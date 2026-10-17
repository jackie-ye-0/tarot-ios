import Foundation
import UserNotifications

/// The one platform boundary. Debug fixtures never ask the system or schedule real alerts.
@MainActor
final class ReminderNotifications {
    enum Permission { case notDetermined, denied, allowed }
    static let identifier = "morning-reminder"
    private let center = UNUserNotificationCenter.current()
    #if DEBUG
    private var fixture: String?
    private var fixturePermission: Permission = .notDetermined
    private var pending: UNNotificationRequest?
    private var requests = 0

    init(fixture: String? = nil) {
        self.fixture = fixture
        if fixture == "allowed" { fixturePermission = .allowed }
        if fixture == "denied" { fixturePermission = .denied }
    }
    #endif

    func permission() async -> Permission {
        #if DEBUG
        if fixture != nil { return fixturePermission }
        #endif
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorized, .provisional, .ephemeral: return .allowed
        default: return .denied
        }
    }

    func requestPermission() async throws -> Bool {
        #if DEBUG
        if let fixture {
            requests += 1
            if fixture == "request-failure" { throw CocoaError(.featureUnsupported) }
            fixturePermission = fixture == "deny" ? .denied : .allowed
            return fixturePermission == .allowed
        }
        #endif
        return try await center.requestAuthorization(options: [.alert, .sound])
    }

    func schedule() async throws {
        let content = UNMutableNotificationContent()
        content.title = MorningReminderRule.title
        content.body = MorningReminderRule.body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: MorningReminderRule.time, repeats: true)
        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        #if DEBUG
        if fixture != nil {
            if fixture == "schedule-failure" {
                fixture = "allowed" // The retry uses the same authorised state.
                throw CocoaError(.fileWriteOutOfSpace)
            }
            pending = request
            return
        }
        #endif
        try await center.add(request)
    }

    func cancel() {
        #if DEBUG
        if fixture != nil { pending = nil; return }
        #endif
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.identifier])
    }

    #if DEBUG
    var testState: String {
        guard fixture != nil else { return "" }
        guard let pending, let trigger = pending.trigger as? UNCalendarNotificationTrigger else {
            return "requests=\(requests); pending=none"
        }
        return "requests=\(requests); pending=\(pending.identifier); hour=\(trigger.dateComponents.hour ?? -1); minute=\(trigger.dateComponents.minute ?? -1); repeats=\(trigger.repeats); deviceTime=\(trigger.dateComponents.timeZone == nil); title=\(pending.content.title); body=\(pending.content.body)"
    }
    #endif
}
