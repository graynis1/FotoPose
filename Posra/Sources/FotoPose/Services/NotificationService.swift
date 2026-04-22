import CoreLocation
import Foundation
import UserNotifications

/// Schedules local notifications: golden-hour reminders at the user's location,
/// a trial-ending nudge, and a weekly "new poses" prompt.
@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // Identifier prefixes let us cancel whole categories without touching others.
    private enum ID {
        static let goldenHourPrefix = "posra.goldenhour."
        static let trial = "posra.trial.endingSoon"
        static let weekly = "posra.weekly.newPoses"
    }

    /// Checks whether notifications are already authorized. Does NOT prompt.
    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        switch status {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    /// Explicitly prompts the user. Call from a user-initiated action (toggle, onboarding).
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    // MARK: - Golden hour

    /// Schedules up to 4 daily golden-hour alerts based on a provided location.
    /// Re-registers from scratch; existing golden-hour notifications are removed first.
    /// Does not prompt for permission — call `requestAuthorizationIfNeeded()` first.
    func scheduleGoldenHourAlerts(location: CLLocation? = nil) async {
        guard await isAuthorized() else { return }
        cancelGoldenHourAlerts()

        let loc = location ?? CLLocation(latitude: 41.0082, longitude: 28.9784) // Istanbul fallback
        var scheduled: Int = 0
        var cursor = Date()
        while scheduled < 4 {
            guard let next = loc.nextGoldenHourStart(from: cursor) else { break }
            // Notify 15 minutes before the window starts
            let fireDate = next.addingTimeInterval(-15 * 60)
            if fireDate > Date() {
                await schedule(
                    id: ID.goldenHourPrefix + "\(scheduled)",
                    title: "notif.goldenHour.title".localized,
                    body: "notif.goldenHour.body".localized,
                    fireDate: fireDate
                )
                scheduled += 1
            }
            cursor = next.addingTimeInterval(60 * 60)
        }
    }

    func cancelGoldenHourAlerts() {
        center.getPendingNotificationRequests { [center] requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(ID.goldenHourPrefix) }
            if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
        }
    }

    // MARK: - Trial

    /// Fires 2 hours before the trial expires so the user can decide to keep/cancel.
    /// Does not prompt — call `requestAuthorizationIfNeeded()` first.
    func scheduleTrialEndingNotification(trialExpires: Date) async {
        guard await isAuthorized() else { return }
        center.removePendingNotificationRequests(withIdentifiers: [ID.trial])
        let fireDate = trialExpires.addingTimeInterval(-2 * 3600)
        guard fireDate > Date() else { return }
        await schedule(
            id: ID.trial,
            title: "notif.trial.title".localized,
            body: "notif.trial.body".localized,
            fireDate: fireDate
        )
    }

    // MARK: - Weekly

    /// Schedules a recurring weekly reminder on Fridays at 18:00 local time.
    /// Does not prompt — call `requestAuthorizationIfNeeded()` first.
    func scheduleWeeklyReminder() async {
        guard await isAuthorized() else { return }
        center.removePendingNotificationRequests(withIdentifiers: [ID.weekly])

        var components = DateComponents()
        components.weekday = 6 // Friday (1 = Sunday)
        components.hour = 18
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "notif.weekly.title".localized
        content.body = "notif.weekly.body".localized
        content.sound = .default

        let request = UNNotificationRequest(identifier: ID.weekly, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Private

    private func schedule(id: String, title: String, body: String, fireDate: Date) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
