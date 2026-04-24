import Foundation
import UserNotifications

/// Wrapper around `UNUserNotificationCenter` for local reminders.
/// Push + household-wide coordination is deferred to a later release.
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func syncReminders(for occurrences: [Occurrence]) async {
        // Clear outdated requests first — cheap enough for MVP volumes.
        let pending = await center.pendingNotificationRequests()
        let pendingIDs = Set(pending.map(\.identifier))
        let desiredIDs = Set(occurrences.filter { $0.isOpen && $0.dueDate > .now }.map { $0.id.uuidString })

        let toCancel = pendingIDs.subtracting(desiredIDs)
        if !toCancel.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(toCancel))
        }

        for occurrence in occurrences where occurrence.isOpen && occurrence.dueDate > .now {
            let id = occurrence.id.uuidString
            guard !pendingIDs.contains(id) else { continue }
            await schedule(occurrence)
        }
    }

    func schedule(_ occurrence: Occurrence) async {
        let content = UNMutableNotificationContent()
        content.title = occurrence.title
        content.body = "Due today · \(occurrence.effort.points) pt\(occurrence.effort.points == 1 ? "" : "s")"
        content.sound = .default
        content.threadIdentifier = "chores.today"
        content.interruptionLevel = .active

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: occurrence.dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: occurrence.id.uuidString, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancel(_ occurrenceID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [occurrenceID.uuidString])
    }
}
