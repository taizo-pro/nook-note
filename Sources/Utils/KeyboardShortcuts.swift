import SwiftUI

extension KeyboardShortcut {
    // Application shortcuts
    static let newPost = KeyboardShortcut("n", modifiers: .command)
    static let refresh = KeyboardShortcut("r", modifiers: .command)
    static let settings = KeyboardShortcut(",", modifiers: .command)
    static let quit = KeyboardShortcut("q", modifiers: .command)
    
    // Navigation shortcuts
    static let closeWindow = KeyboardShortcut("w", modifiers: .command)
    static let escape = KeyboardShortcut(.escape)
    
    // Editing shortcuts
    static let save = KeyboardShortcut("s", modifiers: .command)
    static let post = KeyboardShortcut(.return, modifiers: .command)
    static let clear = KeyboardShortcut("k", modifiers: .command)
    
    // Search shortcuts
    static let search = KeyboardShortcut("f", modifiers: .command)
    static let clearSearch = KeyboardShortcut(.escape)
}

// MARK: - Keyboard Shortcut Handlers

struct KeyboardShortcutHandler: ViewModifier {
    let settingsManager: SettingsManager
    @Binding var selectedTab: Int
    @Binding var showingSettings: Bool
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .keyboardShortcutPressed)) { notification in
                handleKeyboardShortcut(notification)
            }
    }
    
    private func handleKeyboardShortcut(_ notification: Notification) {
        guard let shortcut = notification.userInfo?["shortcut"] as? String else { return }
        
        switch shortcut {
        case "newPost":
            selectedTab = 1
        case "refresh":
            // Trigger refresh for current tab
            NotificationCenter.default.post(name: .refreshRequested, object: nil)
        case "settings":
            showingSettings = true
        case "discussions":
            selectedTab = 0
        default:
            break
        }
    }
}

extension View {
    func keyboardShortcutHandler(
        settingsManager: SettingsManager,
        selectedTab: Binding<Int>,
        showingSettings: Binding<Bool>
    ) -> some View {
        modifier(KeyboardShortcutHandler(
            settingsManager: settingsManager,
            selectedTab: selectedTab,
            showingSettings: showingSettings
        ))
    }
}

// MARK: - Notification Names for Shortcuts

extension Notification.Name {
    static let keyboardShortcutPressed = Notification.Name("keyboardShortcutPressed")
    static let refreshRequested = Notification.Name("refreshRequested")
}