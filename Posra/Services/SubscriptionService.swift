import Foundation
import StoreKit

@MainActor
final class SubscriptionService: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var status: SubscriptionStatus = .unknown
    @Published private(set) var isLoading: Bool = false
    @Published var lastErrorMessage: String? = nil

    private let productIDs: Set<String> = Set(SubscriptionPlan.allCases.map(\.rawValue))
    private var updateListener: Task<Void, Never>? = nil

    nonisolated init() {}

    deinit {
        updateListener?.cancel()
    }

    func bootstrap() async {
        updateListener = listenForTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    // MARK: - Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: productIDs)
            products = fetched.sorted { a, b in
                // weekly, monthly, yearly
                planOrder(a.id) < planOrder(b.id)
            }
        } catch {
            lastErrorMessage = "sub.error.loadPlans".localized
        }
    }

    private func planOrder(_ id: String) -> Int {
        switch id {
        case SubscriptionPlan.weekly.rawValue: return 0
        case SubscriptionPlan.monthly.rawValue: return 1
        case SubscriptionPlan.yearly.rawValue: return 2
        default: return 99
        }
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        products.first { $0.id == plan.rawValue }
    }

    // MARK: - Purchase

    func purchase(_ plan: SubscriptionPlan) async -> Bool {
        guard let product = product(for: plan) else {
            lastErrorMessage = "sub.error.unavailable".localized
            return false
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verify(verification)
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled:
                return false
            case .pending:
                lastErrorMessage = "sub.error.pending".localized
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = "sub.error.restoreFailed".localized
        }
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var resolved: SubscriptionStatus = .notSubscribed
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard productIDs.contains(transaction.productID) else { continue }
            if let expires = transaction.expirationDate, expires > Date() {
                if transaction.offerType == .introductory {
                    resolved = .inTrial(expiresAt: expires)
                } else {
                    resolved = .active(expiresAt: expires, productID: transaction.productID)
                }
            } else {
                resolved = .expired
            }
        }
        status = resolved
    }

    // MARK: - Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self.refreshEntitlements()
            }
        }
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}

extension Product {
    var displayPriceCompact: String {
        displayPrice
    }

    var unitLabel: String {
        guard let sub = subscription else { return "" }
        switch sub.subscriptionPeriod.unit {
        case .day: return "unit.day".localized
        case .week: return "unit.week".localized
        case .month: return "unit.month".localized
        case .year: return "unit.year".localized
        @unknown default: return ""
        }
    }
}
