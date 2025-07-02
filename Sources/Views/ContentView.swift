import SwiftUI

struct ContentView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var notificationService = NotificationService()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var selectedDiscussion: Discussion?
    @State private var showingDiscussionDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("NookNote")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.borderless)
                .help("Settings (⌘,)")
                .keyboardShortcut(",", modifiers: .command)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.md)
            
            if settingsManager.settings.isConfigured {
                // Main Content - Tabbed Interface
                VStack(spacing: 0) {
                    // Tab Bar
                    HStack {
                        TabButton(title: "Discussions", isSelected: selectedTab == 0) {
                            withAnimation(DesignSystem.Animation.medium) {
                                selectedTab = 0
                            }
                        }
                        TabButton(title: "New Post", isSelected: selectedTab == 1) {
                            withAnimation(DesignSystem.Animation.medium) {
                                selectedTab = 1
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.sm)
                    
                    Divider()
                    
                    // Tab Content with animation
                    ZStack {
                        if selectedTab == 0 {
                            DiscussionsListView(
                                settingsManager: settingsManager,
                                onDiscussionSelected: { discussion in
                                    withAnimation(DesignSystem.Animation.medium) {
                                        selectedDiscussion = discussion
                                        showingDiscussionDetail = true
                                    }
                                }
                            )
                            .transition(.slideAndFade)
                        } else {
                            NewPostView(settingsManager: settingsManager)
                                .transition(.slideAndFade)
                        }
                    }
                    .animation(DesignSystem.Animation.medium, value: selectedTab)
                }
            } else {
                // Setup Required View
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(DesignSystem.Typography.largeTitle)
                        .foregroundColor(DesignSystem.Colors.warning)
                    
                    Text("Setup Required")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Configure your GitHub repository and access token to get started.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Open Settings") {
                        showingSettings = true
                    }
                    .primaryButtonStyle()
                    .keyboardShortcut(",", modifiers: .command)
                }
                .padding(DesignSystem.Spacing.xl)
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("GitHub Discussions")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .font(DesignSystem.Typography.caption)
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.sm)
        }
        .frame(
            minWidth: ResponsiveDesign.WindowSize.regular.width,
            idealWidth: ResponsiveDesign.WindowSize.regular.width,
            maxWidth: ResponsiveDesign.WindowSize.large.width,
            minHeight: ResponsiveDesign.WindowSize.regular.height,
            idealHeight: ResponsiveDesign.WindowSize.regular.height,
            maxHeight: ResponsiveDesign.WindowSize.large.height
        )
        .detectScreenSize()
        .sheet(isPresented: $showingSettings) {
            SettingsView(settingsManager: settingsManager)
                .transition(.slideUp)
        }
        .sheet(isPresented: $showingDiscussionDetail) {
            if let discussion = selectedDiscussion {
                DiscussionDetailView(discussion: discussion, settingsManager: settingsManager)
                    .transition(.scaleAndFade)
            }
        }
        .environmentObject(notificationService)
        .keyboardShortcutHandler(
            settingsManager: settingsManager,
            selectedTab: $selectedTab,
            showingSettings: $showingSettings
        )
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            notificationService.clearBadge()
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeCurrentView)) { _ in
            showingSettings = false
            showingDiscussionDetail = false
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? DesignSystem.Typography.buttonLabel : DesignSystem.Typography.body)
                .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(backgroundColor)
                        .animation(DesignSystem.Animation.fast, value: isSelected)
                        .animation(DesignSystem.Animation.fast, value: isHovered)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return DesignSystem.Colors.primary.opacity(0.1)
        } else if isHovered {
            return DesignSystem.Colors.surfaceHover
        } else {
            return Color.clear
        }
    }
}

#Preview {
    ContentView()
        .frame(
            width: ResponsiveDesign.WindowSize.regular.width,
            height: ResponsiveDesign.WindowSize.regular.height
        )
}