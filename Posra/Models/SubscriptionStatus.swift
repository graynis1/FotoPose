import Foundation

enum SubscriptionStatus: Equatable {
    case unknown
    case notSubscribed
    case inTrial(expiresAt: Date)
    case active(expiresAt: Date, productID: String)
    case expired

    var hasAccess: Bool {
        switch self {
        case .inTrial, .active: return true
        default: return false
        }
    }

    var isPro: Bool {
        if case .active = self { return true }
        if case .inTrial = self { return true }
        return false
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case weekly = "com.posra.weekly"
    case monthly = "com.posra.monthly"
    case yearly = "com.posra.yearly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly".localized
        case .monthly: return "Monthly".localized
        case .yearly: return "Yearly".localized
        }
    }

    var unitLabel: String {
        switch self {
        case .weekly: return "unit.week".localized
        case .monthly: return "unit.month".localized
        case .yearly: return "unit.year".localized
        }
    }

    var fallbackPrice: String {
        switch self {
        case .weekly: return "₺79.99"
        case .monthly: return "₺279.99"
        case .yearly: return "₺999.99"
        }
    }

    var fallbackSubtitle: String {
        switch self {
        case .weekly: return "After trial".localized
        case .monthly: return "Cancel anytime".localized
        case .yearly: return "Save 68%".localized
        }
    }
}
