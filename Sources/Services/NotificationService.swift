import Foundation
import UserNotifications
import Combine
import AppKit

class NotificationService: ObservableObject {
    @Published var isNotificationEnabled = true
    @Published var showBadge = true
    @Published var playSound = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotificationObservers()
        // Delay notification permission request to avoid bundle issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestNotificationPermissionSafely()
        }
    }
    
    // MARK: - Permission Management
    
    private func requestNotificationPermissionSafely() {
        // Check if we're running in a proper app bundle context
        guard Bundle.main.bundleIdentifier != nil else {
            print("NotificationService: Skipping notification setup - not in app bundle context")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                }
                // Update UI based on granted status if needed
            }
        }
    }
    
    func checkNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Listen for new discussions
        NotificationCenter.default.publisher(for: .newDiscussionsAvailable)
            .sink { [weak self] notification in
                if let count = notification.userInfo?["count"] as? Int {
                    self?.showNewDiscussionsNotification(count: count)
                }
            }
            .store(in: &cancellables)
        
        // Listen for post success
        NotificationCenter.default.publisher(for: .discussionPosted)
            .sink { [weak self] notification in
                self?.showDiscussionPostedNotification()
            }
            .store(in: &cancellables)
        
        // Listen for update errors
        NotificationCenter.default.publisher(for: .updateError)
            .sink { [weak self] notification in
                if let error = notification.userInfo?["error"] as? String {
                    self?.showErrorNotification(message: error)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Types
    
    func showNewDiscussionsNotification(count: Int) {
        guard isNotificationEnabled && Bundle.main.bundleIdentifier != nil else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Discussions"
        content.body = count == 1 ? "1 new discussion available" : "\(count) new discussions available"
        content.sound = playSound ? .default : nil
        content.badge = showBadge ? NSNumber(value: count) : nil
        
        let request = UNNotificationRequest(
            identifier: "new-discussions-\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func showDiscussionPostedNotification() {
        guard isNotificationEnabled && Bundle.main.bundleIdentifier != nil else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Discussion Posted"
        content.body = "Your discussion has been posted successfully"
        content.sound = playSound ? .default : nil
        
        let request = UNNotificationRequest(
            identifier: "discussion-posted-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func showCommentPostedNotification() {
        guard isNotificationEnabled && Bundle.main.bundleIdentifier != nil else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Comment Posted"
        content.body = "Your comment has been posted successfully"
        content.sound = playSound ? .default : nil
        
        let request = UNNotificationRequest(
            identifier: "comment-posted-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func showErrorNotification(message: String) {
        guard isNotificationEnabled && Bundle.main.bundleIdentifier != nil else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Error"
        content.body = message
        content.sound = playSound ? .default : nil
        
        let request = UNNotificationRequest(
            identifier: "error-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func showAuthenticationRequiredNotification() {
        guard isNotificationEnabled && Bundle.main.bundleIdentifier != nil else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Authentication Required"
        content.body = "Please check your GitHub settings"
        content.sound = playSound ? .default : nil
        
        let request = UNNotificationRequest(
            identifier: "auth-required-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    // MARK: - In-App Notifications
    
    func showInAppSuccess(message: String) {
        // For in-app success messages
        NotificationCenter.default.post(
            name: .inAppSuccess,
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    func showInAppError(message: String) {
        // For in-app error messages
        NotificationCenter.default.post(
            name: .inAppError,
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    func showInAppInfo(message: String) {
        // For in-app info messages
        NotificationCenter.default.post(
            name: .inAppInfo,
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        guard showBadge else { return }
        
        DispatchQueue.main.async {
            NSApp.dockTile.badgeLabel = count > 0 ? "\(count)" : ""
            NSApp.dockTile.display()
        }
    }
    
    func clearBadge() {
        DispatchQueue.main.async {
            NSApp.dockTile.badgeLabel = ""
            NSApp.dockTile.display()
        }
    }
    
    // MARK: - Settings
    
    func enableNotifications(_ enabled: Bool) {
        isNotificationEnabled = enabled
        if !enabled {
            clearBadge()
        }
    }
    
    func enableBadge(_ enabled: Bool) {
        showBadge = enabled
        if !enabled {
            clearBadge()
        }
    }
    
    func enableSound(_ enabled: Bool) {
        playSound = enabled
    }
    
    // MARK: - Cleanup
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let discussionPosted = Notification.Name("discussionPosted")
    static let commentPosted = Notification.Name("commentPosted")
    static let inAppSuccess = Notification.Name("inAppSuccess")
    static let inAppError = Notification.Name("inAppError")
    static let inAppInfo = Notification.Name("inAppInfo")
}