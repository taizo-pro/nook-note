import Foundation
import Combine

class UpdateService: ObservableObject {
    @Published var isAutoUpdateEnabled = true
    @Published var updateInterval: TimeInterval = 300 // 5 minutes
    @Published var lastUpdateTime: Date?
    @Published var nextUpdateTime: Date?
    
    private let discussionsService: DiscussionsService
    private let settingsManager: SettingsManager
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(discussionsService: DiscussionsService, settingsManager: SettingsManager) {
        self.discussionsService = discussionsService
        self.settingsManager = settingsManager
        
        setupAutoUpdate()
        
        // Monitor settings changes
        settingsManager.$settings
            .sink { [weak self] settings in
                self?.handleSettingsChange(settings)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        stopAutoUpdate()
    }
    
    // MARK: - Auto Update Management
    
    func setupAutoUpdate() {
        guard isAutoUpdateEnabled && settingsManager.settings.isConfigured else {
            stopAutoUpdate()
            return
        }
        
        startAutoUpdate()
    }
    
    private func startAutoUpdate() {
        stopAutoUpdate() // Clear any existing timer
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.performBackgroundUpdate()
            }
        }
        
        updateNextUpdateTime()
    }
    
    private func stopAutoUpdate() {
        updateTimer?.invalidate()
        updateTimer = nil
        nextUpdateTime = nil
    }
    
    private func updateNextUpdateTime() {
        nextUpdateTime = Date().addingTimeInterval(updateInterval)
    }
    
    // MARK: - Update Operations
    
    @MainActor
    func performBackgroundUpdate() async {
        guard isAutoUpdateEnabled && settingsManager.settings.isConfigured else { return }
        
        // Only update if not currently loading to avoid conflicts
        guard !discussionsService.isLoading else { return }
        
        let oldCount = discussionsService.discussions.count
        
        // Perform silent update
        await discussionsService.loadDiscussions(refresh: true)
        
        let newCount = discussionsService.discussions.count
        lastUpdateTime = Date()
        updateNextUpdateTime()
        
        // Check for new discussions
        if newCount > oldCount {
            let newDiscussionsCount = newCount - oldCount
            sendUpdateNotification(newDiscussionsCount: newDiscussionsCount)
        }
    }
    
    @MainActor
    func manualUpdate() async {
        lastUpdateTime = Date()
        await discussionsService.refreshDiscussions()
        updateNextUpdateTime()
    }
    
    // MARK: - Settings
    
    func enableAutoUpdate(_ enabled: Bool) {
        isAutoUpdateEnabled = enabled
        if enabled {
            setupAutoUpdate()
        } else {
            stopAutoUpdate()
        }
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        updateInterval = interval
        if isAutoUpdateEnabled {
            setupAutoUpdate()
        }
    }
    
    private func handleSettingsChange(_ settings: AppSettings) {
        if settings.isConfigured && isAutoUpdateEnabled {
            setupAutoUpdate()
        } else {
            stopAutoUpdate()
        }
    }
    
    // MARK: - Notifications
    
    private func sendUpdateNotification(newDiscussionsCount: Int) {
        // Post notification for new discussions
        NotificationCenter.default.post(
            name: .newDiscussionsAvailable,
            object: nil,
            userInfo: ["count": newDiscussionsCount]
        )
    }
    
    // MARK: - Utility
    
    var timeUntilNextUpdate: TimeInterval? {
        guard let nextUpdateTime = nextUpdateTime else { return nil }
        return max(0, nextUpdateTime.timeIntervalSinceNow)
    }
    
    var isUpdateDue: Bool {
        guard let lastUpdateTime = lastUpdateTime else { return true }
        return Date().timeIntervalSince(lastUpdateTime) >= updateInterval
    }
    
    var formattedLastUpdateTime: String {
        guard let lastUpdateTime = lastUpdateTime else { return "Never" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        let now = Date()
        let interval = now.timeIntervalSince(lastUpdateTime)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if Calendar.current.isDate(lastUpdateTime, inSameDayAs: now) {
            return "Today at \(formatter.string(from: lastUpdateTime))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: lastUpdateTime)
        }
    }
    
    var formattedNextUpdateTime: String {
        guard let timeUntil = timeUntilNextUpdate else { return "Never" }
        
        if timeUntil < 60 {
            return "In \(Int(timeUntil))s"
        } else if timeUntil < 3600 {
            let minutes = Int(timeUntil / 60)
            return "In \(minutes)m"
        } else {
            let hours = Int(timeUntil / 3600)
            let minutes = Int((timeUntil.truncatingRemainder(dividingBy: 3600)) / 60)
            return "In \(hours)h \(minutes)m"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newDiscussionsAvailable = Notification.Name("newDiscussionsAvailable")
    static let discussionUpdated = Notification.Name("discussionUpdated")
    static let updateError = Notification.Name("updateError")
}