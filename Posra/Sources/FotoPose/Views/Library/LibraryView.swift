import SwiftUI
import CoreLocation

/// The pose library — re-imagined around dynamic AI generation.
/// Sections:
///  - Favorites (from PoseHistoryService)
///  - Recent (from PoseHistoryService)
///  - Perfect for Now (PoseAIEngine with current context)
///  - Categories grid — tapping a tile regenerates with a category hint
///  - Search field — plumbs the query string to the AI engine
struct LibraryView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var appState: AppState
    @StateObject private var history = PoseHistoryService.shared
    @StateObject private var model = LibraryViewModel()

    @State private var query: String = ""
    @State private var isSearchFocused: Bool = false
    @State private var detailPose: GeneratedPose? = nil
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [DS.Colors.violet.opacity(0.28), .clear],
                        center: .center, startRadius: 0, endRadius: 200
                    )
                )
                .frame(width: 320, height: 320)
                .blur(radius: 10)
                .offset(x: 130, y: -200)
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    titleRow
                        .padding(.top, 60)
                        .padding(.horizontal, 20)

                    searchField
                        .padding(.top, 14)
                        .padding(.horizontal, 20)

                    if !history.favorites.isEmpty {
                        silhouetteSection(
                            title: "FAVORITES",
                            poses: history.favorites,
                            accent: .pink
                        )
                        .padding(.top, 24)
                    }

                    if !history.recents.isEmpty {
                        silhouetteSection(
                            title: "RECENT",
                            poses: history.getRecent(limit: 10),
                            accent: .violet
                        )
                        .padding(.top, 24)
                    }

                    perfectForNowSection
                        .padding(.top, 24)

                    categoriesGrid
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    Color.clear.frame(height: 120) // tab-bar spacer
                }
            }
        }
        .onAppear { model.loadPerfectForNow() }
        .onChange(of: query) { (newQuery: String) in
            model.searchDebounced(newQuery)
        }
        .sheet(item: $detailPose) { pose in
            PoseDetailSheet(
                pose: pose,
                detection: DetectionResult(),
                similar: model.similarPoses(to: pose),
                onUsePose: {
                    appState.selectedTab = .camera
                },
                onDismiss: { detailPose = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: "#0E0E14"))
        }
    }

    // MARK: - Sections

    private var titleRow: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Library")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-1)
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(subtitleText))
                    .font(.system(size: 13))
                    .tracking(-0.15)
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            Spacer()
            if !model.isAIAvailable {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.Colors.gold)
                    Text("Fallback")
                        .font(DS.Font.mono(10, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06), in: Capsule())
                .overlay(Capsule().stroke(DS.Colors.gold.opacity(0.25), lineWidth: 0.5))
            }
        }
    }

    private var subtitleText: String {
        if model.isAIAvailable {
            return "Generated for you · on-device AI"
        } else {
            return String.localized("library.curatedTemplates", PoseFallbackEngine.all.count)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
            TextField("Ask for a pose…", text: $query)
                .font(.system(size: 14))
                .tint(DS.Colors.pink)
                .foregroundStyle(.white)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { model.search(query) }
            if !query.isEmpty {
                Button {
                    query = ""
                    model.searchDebounced("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(searchFocused ? DS.Colors.pink.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: searchFocused ? 1 : 0.5)
        )
    }

    private var perfectForNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Gradients.accent)
                    Text(model.isSearching ? LocalizedStringKey("Matching your query") : LocalizedStringKey("Perfect for Now"))
                        .font(.system(size: 16, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(.white)
                }
                Text(LocalizedStringKey(model.perfectForNowSubtitle))
                    .font(.system(size: 12.5))
                    .tracking(-0.15)
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.leading, 20)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if model.isLoading {
                        ForEach(0..<5, id: \.self) { _ in
                            LibraryShimmerCard()
                        }
                    } else {
                        ForEach(model.perfectForNow) { pose in
                            LibraryPoseCard(pose: pose, width: 150, height: 210)
                                .onTapGesture { openDetail(pose) }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func silhouetteSection(title: String, poses: [GeneratedPose], accent: LibraryAccent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey(title))
                    .font(DS.Font.mono(11, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(Color.white.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(poses) { pose in
                        LibraryPoseCard(pose: pose, width: 130, height: 176, accent: accent)
                            .onTapGesture { openDetail(pose) }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var categoriesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CATEGORIES")
                .font(DS.Font.mono(11, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(Color.white.opacity(0.5))

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(PoseCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        count: PoseFallbackEngine.poses(in: category).count,
                        isPro: category == .editorial || category == .wedding
                    )
                    .onTapGesture {
                        let isPro = category == .editorial || category == .wedding
                        if isPro && !subscriptionService.status.isPro {
                            appState.presentPaywall()
                            return
                        }
                        model.generateForCategory(category) { pose in
                            if let pose { openDetail(pose) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func openDetail(_ pose: GeneratedPose) {
        if pose.isPro && !subscriptionService.status.isPro {
            appState.presentPaywall()
            return
        }
        detailPose = pose
    }
}

// MARK: - Library cards

private enum LibraryAccent {
    case pink, violet

    var gradientColors: [Color] {
        switch self {
        case .pink:   return [DS.Colors.pink.opacity(0.22), .clear]
        case .violet: return [DS.Colors.violet.opacity(0.22), .clear]
        }
    }
}

private struct LibraryPoseCard: View {
    let pose: GeneratedPose
    let width: CGFloat
    let height: CGFloat
    var accent: LibraryAccent = .pink

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "#14121D"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: accent.gradientColors,
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )

            PoseSilhouette(
                keypoints: pose.bodyKeypoints,
                stroke: DS.Gradients.accent,
                lineWidth: 2,
                glow: DS.Colors.pink.opacity(0.5)
            )
            .padding(16)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.75)],
                startPoint: .center, endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(pose.name))
                    .font(.system(size: 13, weight: .bold))
                    .tracking(-0.15)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
                    .lineLimit(2)
                Text(LocalizedStringKey(pose.categoryDisplayName))
                    .font(DS.Font.mono(10, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            if pose.isPro {
                HStack(spacing: 3) {
                    Image(systemName: "sparkles").font(.system(size: 8, weight: .bold))
                    Text("PRO")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(0.6)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(DS.Gradients.accent, in: Capsule())
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

private struct LibraryShimmerCard: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .frame(width: 150, height: 210)
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.12), location: 0.5),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .offset(x: phase * 160)
                .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private struct CategoryCard: View {
    let category: PoseCategory
    let count: Int
    let isPro: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "#14121D"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DS.Colors.violet.opacity(0.22), DS.Colors.pink.opacity(0.08)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )

            // Decorative silhouette of a representative pose
            if let sample = PoseFallbackEngine.poses(in: category).first {
                PoseSilhouette(
                    keypoints: sample.bodyKeypoints,
                    stroke: DS.Gradients.accent,
                    lineWidth: 1.4,
                    glow: DS.Colors.pink.opacity(0.25),
                    jointDots: false
                )
                .padding(20)
                .opacity(0.5)
            }

            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.05), location: 0),
                    .init(color: DS.Colors.background.opacity(0.85), location: 1)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(category.displayName))
                    .font(.system(size: 14.5, weight: .bold))
                    .tracking(-0.2)
                    .foregroundStyle(.white)
                Text("Tap to generate")
                    .font(DS.Font.mono(11, weight: .medium))
                    .tracking(0.2)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            if isPro {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 8, weight: .bold))
                    Text("PRO")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(DS.Gradients.accent, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                .shadow(color: DS.Colors.pink.opacity(0.4), radius: 10, x: 0, y: 4)
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(height: 160)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - ViewModel

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var perfectForNow: [GeneratedPose] = []
    @Published var isLoading: Bool = false
    @Published var isSearching: Bool = false

    private var searchTask: Task<Void, Never>?
    private let engine = PoseAIEngine.shared

    var isAIAvailable: Bool { engine.isAvailable }

    var perfectForNowSubtitle: String {
        if isSearching { return "Tailored to your query".localized }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        let time = formatter.string(from: Date())
        if isAIAvailable {
            return String.localized("library.generatedAt", time)
        }
        return String.localized("library.curatedAt", time)
    }

    func loadPerfectForNow() {
        let context = PoseContext(
            personCount: 1,
            estimatedGender: "any",
            estimatedBodyType: "any",
            currentPosture: "standing",
            sceneType: "any",
            lightingCondition: "any",
            colorTemperature: 5500,
            timeOfDay: timeOfDayLabel(),
            isGoldenHour: isNearGoldenHour()
        )
        generate(context: context)
    }

    func generateForCategory(_ category: PoseCategory, completion: @escaping (GeneratedPose?) -> Void) {
        var context = PoseContext(
            personCount: category == .couple ? 2 : (category == .group ? 3 : 1),
            estimatedGender: "any",
            estimatedBodyType: "any",
            currentPosture: "standing",
            sceneType: "any",
            lightingCondition: "any",
            colorTemperature: 5500,
            timeOfDay: timeOfDayLabel(),
            isGoldenHour: false
        )
        context.categoryHint = category.rawValue

        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            var ai: [GeneratedPose]? = nil
            if self.engine.isAvailable {
                ai = try? await self.engine.generatePoses(from: context, limit: 5, force: true)
            }
            let result: [GeneratedPose] = (ai?.isEmpty == false ? ai! : PoseFallbackEngine.poses(in: category))
            await MainActor.run {
                self.isLoading = false
                self.perfectForNow = result
                self.isSearching = false
                completion(result.first)
            }
        }
    }

    func searchDebounced(_ query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            isSearching = false
            loadPerfectForNow()
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard let self, !Task.isCancelled else { return }
            self.search(trimmed)
        }
    }

    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var context = PoseContext(
            personCount: 1,
            estimatedGender: "any",
            estimatedBodyType: "any",
            currentPosture: "standing",
            sceneType: "any",
            lightingCondition: "any",
            colorTemperature: 5500,
            timeOfDay: timeOfDayLabel(),
            isGoldenHour: false
        )
        context.userQuery = trimmed

        isSearching = true
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            var ai: [GeneratedPose]? = nil
            if self.engine.isAvailable {
                ai = try? await self.engine.generatePoses(from: context, limit: 6, force: true)
            }
            let result: [GeneratedPose] = (ai?.isEmpty == false ? ai! : PoseFallbackEngine.search(trimmed))
            await MainActor.run {
                self.isLoading = false
                self.perfectForNow = result
            }
        }
    }

    func similarPoses(to pose: GeneratedPose) -> [GeneratedPose] {
        let pool = perfectForNow + PoseHistoryService.shared.favorites + PoseFallbackEngine.all
        return pool
            .filter { $0.id != pose.id && $0.category == pose.category }
            .prefix(4)
            .map { $0 }
    }

    // MARK: - Private

    private func generate(context: PoseContext) {
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            var ai: [GeneratedPose]? = nil
            if self.engine.isAvailable {
                ai = try? await self.engine.generatePoses(from: context, limit: 6, force: false)
            }
            let result: [GeneratedPose] = (ai?.isEmpty == false ? ai! : PoseFallbackEngine.poses(for: context, limit: 6))
            await MainActor.run {
                self.isLoading = false
                self.perfectForNow = result
            }
        }
    }

    private func timeOfDayLabel() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8:   return "Sunrise"
        case 8..<11:  return "Morning"
        case 11..<14: return "Midday"
        case 14..<17: return "Afternoon"
        case 17..<20: return "Golden Hour"
        case 20..<22: return "Dusk"
        default:      return "Night"
        }
    }

    private func isNearGoldenHour() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return (17..<20).contains(hour) || (5..<8).contains(hour)
    }
}
