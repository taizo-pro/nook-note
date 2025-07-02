import SwiftUI
import AppKit

extension KeyboardShortcut {
    // Application shortcuts
    static let newPost = KeyboardShortcut("n", modifiers: .command)
    static let refresh = KeyboardShortcut("r", modifiers: .command)
    static let settings = KeyboardShortcut(",", modifiers: .command)
    static let quit = KeyboardShortcut("q", modifiers: .command)
    
    // Navigation shortcuts
    static let closeWindow = KeyboardShortcut("w", modifiers: .command)
    static let escape = KeyboardShortcut(.escape)
    static let nextTab = KeyboardShortcut(.tab, modifiers: .control)
    static let previousTab = KeyboardShortcut(.tab, modifiers: [.control, .shift])
    
    // Editing shortcuts
    static let save = KeyboardShortcut("s", modifiers: .command)
    static let post = KeyboardShortcut(.return, modifiers: .command)
    static let clear = KeyboardShortcut("k", modifiers: .command)
    static let selectAll = KeyboardShortcut("a", modifiers: .command)
    
    // Search shortcuts
    static let search = KeyboardShortcut("f", modifiers: .command)
    static let clearSearch = KeyboardShortcut(.escape)
    
    // View shortcuts
    static let toggleFilters = KeyboardShortcut("l", modifiers: .command)
    static let focusSearch = KeyboardShortcut("f", modifiers: [.command, .shift])
}

// MARK: - Keyboard Shortcut Handlers

// MARK: - Global Keyboard Shortcut Manager

class GlobalKeyboardShortcutManager: ObservableObject {
    static let shared = GlobalKeyboardShortcutManager()
    
    @Published var isEnabled = true
    private var shortcuts: [String: () -> Void] = [:]
    
    private init() {
        setupGlobalShortcuts()
    }
    
    private func setupGlobalShortcuts() {
        // Set up global keyboard event monitoring
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return self.handleKeyEvent(event) ? nil : event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard isEnabled else { return false }
        
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        let characters = event.charactersIgnoringModifiers ?? ""
        
        // Command key shortcuts
        if modifiers.contains(.command) {
            switch characters.lowercased() {
            case "n":
                NotificationCenter.default.post(name: .keyboardShortcut, object: "newPost")
                return true
            case "r":
                NotificationCenter.default.post(name: .keyboardShortcut, object: "refresh")
                return true
            case ",":
                NotificationCenter.default.post(name: .keyboardShortcut, object: "settings")
                return true
            case "w":
                NotificationCenter.default.post(name: .keyboardShortcut, object: "closeWindow")
                return true
            case "f":
                if modifiers.contains(.shift) {
                    NotificationCenter.default.post(name: .keyboardShortcut, object: "focusSearch")
                } else {
                    NotificationCenter.default.post(name: .keyboardShortcut, object: "search")
                }
                return true
            case "l":
                NotificationCenter.default.post(name: .keyboardShortcut, object: "toggleFilters")
                return true
            case "k":
                NotificationCenter.default.post(name: .keyboardShortcut, object: "clear")
                return true
            default:
                break
            }
        }
        
        // Escape key
        if keyCode == 53 { // Escape key code
            NotificationCenter.default.post(name: .keyboardShortcut, object: "escape")
            return true
        }
        
        // Control + Tab (next tab)
        if modifiers.contains(.control) && keyCode == 48 { // Tab key code
            if modifiers.contains(.shift) {
                NotificationCenter.default.post(name: .keyboardShortcut, object: "previousTab")
            } else {
                NotificationCenter.default.post(name: .keyboardShortcut, object: "nextTab")
            }
            return true
        }
        
        return false
    }
    
    func enableShortcuts() {
        isEnabled = true
    }
    
    func disableShortcuts() {
        isEnabled = false
    }
}

struct KeyboardShortcutHandler: ViewModifier {
    let settingsManager: SettingsManager
    @Binding var selectedTab: Int
    @Binding var showingSettings: Bool
    @StateObject private var shortcutManager = GlobalKeyboardShortcutManager.shared
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .keyboardShortcut)) { notification in
                handleKeyboardShortcut(notification)
            }
    }
    
    private func handleKeyboardShortcut(_ notification: Notification) {
        guard let shortcut = notification.object as? String else { return }
        
        DispatchQueue.main.async {
            switch shortcut {
            case "newPost":
                selectedTab = 1
            case "refresh":
                NotificationCenter.default.post(name: .refreshRequested, object: nil)
            case "settings":
                showingSettings = true
            case "discussions":
                selectedTab = 0
            case "nextTab":
                selectedTab = (selectedTab + 1) % 2
            case "previousTab":
                selectedTab = selectedTab == 0 ? 1 : 0
            case "closeWindow":
                // Close current sheet/modal if any
                NotificationCenter.default.post(name: .closeCurrentView, object: nil)
            case "escape":
                // Handle escape - close modals, clear search, etc.
                NotificationCenter.default.post(name: .escapePressed, object: nil)
            case "search":
                NotificationCenter.default.post(name: .focusSearch, object: nil)
            case "focusSearch":
                NotificationCenter.default.post(name: .focusSearch, object: nil)
            case "toggleFilters":
                NotificationCenter.default.post(name: .toggleFilters, object: nil)
            case "clear":
                NotificationCenter.default.post(name: .clearAction, object: nil)
            default:
                break
            }
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
    
    func keyboardShortcuts(_ shortcuts: [KeyboardShortcut: () -> Void]) -> some View {
        self.background(
            Color.clear
                .onReceive(NotificationCenter.default.publisher(for: .keyboardShortcut)) { notification in
                    // Handle individual shortcuts
                }
        )
    }
}

// MARK: - Notification Names for Shortcuts

extension Notification.Name {
    static let keyboardShortcut = Notification.Name("keyboardShortcut")
    static let refreshRequested = Notification.Name("refreshRequested")
    static let closeCurrentView = Notification.Name("closeCurrentView")
    static let escapePressed = Notification.Name("escapePressed")
    static let focusSearch = Notification.Name("focusSearch")
    static let toggleFilters = Notification.Name("toggleFilters")
    static let clearAction = Notification.Name("clearAction")
}

// MARK: - Keyboard Shortcut Help

struct KeyboardShortcutHelp {
    static let shortcuts: [ShortcutInfo] = [
        ShortcutInfo(key: "⌘N", description: "New discussion"),
        ShortcutInfo(key: "⌘R", description: "Refresh discussions"),
        ShortcutInfo(key: "⌘,", description: "Open settings"),
        ShortcutInfo(key: "⌘W", description: "Close window/modal"),
        ShortcutInfo(key: "⌘F", description: "Search discussions"),
        ShortcutInfo(key: "⌘⇧F", description: "Focus search field"),
        ShortcutInfo(key: "⌘L", description: "Toggle filters"),
        ShortcutInfo(key: "⌘K", description: "Clear form/search"),
        ShortcutInfo(key: "⌃Tab", description: "Next tab"),
        ShortcutInfo(key: "⌃⇧Tab", description: "Previous tab"),
        ShortcutInfo(key: "Esc", description: "Cancel/close"),
        ShortcutInfo(key: "⌘↵", description: "Post (in editor)")
    ]
}

struct ShortcutInfo {
    let key: String
    let description: String
}