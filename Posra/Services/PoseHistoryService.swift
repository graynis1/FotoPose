import Foundation
import SwiftUI
import Combine

/// Persists the user's favorite poses and recently-viewed poses across launches.
/// Backed by UserDefaults (JSON) so it works on iOS 16+; the API is SwiftData-shaped
/// so we can swap the backing store later without touching callers.
@MainActor
final class PoseHistoryService: ObservableObject {
    static let shared = PoseHistoryService()

    @Published private(set) var favorites: [GeneratedPose] = []
    @Published private(set) var recents: [GeneratedPose] = []

    private let favoritesKey = "posra.history.favorites"
    private let recentsKey = "posra.history.recents"
    private let maxRecents = 30

    init() {
        load()
    }

    // MARK: - Favorites

    func isFavorite(_ pose: GeneratedPose) -> Bool {
        favorites.contains(where: { $0.id == pose.id })
    }

    func saveFavorite(_ pose: GeneratedPose) {
        guard !isFavorite(pose) else { return }
        favorites.insert(pose, at: 0)
        persistFavorites()
    }

    func removeFavorite(_ pose: GeneratedPose) {
        favorites.removeAll(where: { $0.id == pose.id })
        persistFavorites()
    }

    func toggleFavorite(_ pose: GeneratedPose) {
        if isFavorite(pose) { removeFavorite(pose) }
        else { saveFavorite(pose) }
    }

    func getFavorites() -> [GeneratedPose] { favorites }

    // MARK: - Recents

    /// Call when the user views/selects a pose — moves it to the front of the recents list.
    func noteView(_ pose: GeneratedPose) {
        recents.removeAll(where: { $0.id == pose.id })
        recents.insert(pose, at: 0)
        if recents.count > maxRecents {
            recents = Array(recents.prefix(maxRecents))
        }
        persistRecents()
    }

    func getRecent(limit: Int = 10) -> [GeneratedPose] {
        Array(recents.prefix(limit))
    }

    func clearRecents() {
        recents.removeAll()
        persistRecents()
    }

    // MARK: - Persistence

    private func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([GeneratedPose].self, from: data) {
            favorites = decoded
        }
        if let data = defaults.data(forKey: recentsKey),
           let decoded = try? JSONDecoder().decode([GeneratedPose].self, from: data) {
            recents = decoded
        }
    }

    private func persistFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }

    private func persistRecents() {
        guard let data = try? JSONEncoder().encode(recents) else { return }
        UserDefaults.standard.set(data, forKey: recentsKey)
    }
}
