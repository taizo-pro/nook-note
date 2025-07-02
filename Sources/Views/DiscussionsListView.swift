import SwiftUI

struct DiscussionsListView: View {
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var authService: AuthenticationService
    @StateObject private var discussionsService: DiscussionsService
    @StateObject private var updateService: UpdateService
    @EnvironmentObject var notificationService: NotificationService
    let onDiscussionSelected: (Discussion) -> Void
    
    init(settingsManager: SettingsManager, onDiscussionSelected: @escaping (Discussion) -> Void = { _ in }) {
        self.settingsManager = settingsManager
        self.onDiscussionSelected = onDiscussionSelected
        let authService = AuthenticationService(settingsManager: settingsManager)
        let apiClient = GitHubAPIClient(authenticationService: authService)
        let discussionsService = DiscussionsService(apiClient: apiClient, settingsManager: settingsManager)
        let updateService = UpdateService(discussionsService: discussionsService, settingsManager: settingsManager)
        
        self._authService = StateObject(wrappedValue: authService)
        self._discussionsService = StateObject(wrappedValue: discussionsService)
        self._updateService = StateObject(wrappedValue: updateService)
    }
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedState = "All"
    @State private var showingFilters = false
    @FocusState private var isSearchFocused: Bool
    
    private let categories = ["All", "General", "Ideas", "Q&A", "Show and tell"]
    private let states = ["All", "Open", "Closed"]
    
    private var filteredDiscussions: [Discussion] {
        var filtered = discussionsService.discussions
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { discussion in
                discussion.title.localizedCaseInsensitiveContains(searchText) ||
                (discussion.body?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Category filter
        if selectedCategory != "All" {
            filtered = filtered.filter { discussion in
                discussion.category.name.localizedCaseInsensitiveContains(selectedCategory)
            }
        }
        
        // State filter
        if selectedState != "All" {
            filtered = filtered.filter { discussion in
                switch selectedState {
                case "Open":
                    return discussion.state == .open
                case "Closed":
                    return discussion.state == .closed
                default:
                    return true
                }
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and filters
            VStack(spacing: 8) {
                HStack {
                    Text("Discussions")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(DesignSystem.Animation.medium) {
                            showingFilters.toggle()
                        }
                    }) {
                        Image(systemName: showingFilters ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle")
                            .foregroundColor(showingFilters ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Toggle Filters (⌘L)")
                    .keyboardShortcut("l", modifiers: .command)
                    
                    Button(action: {
                        Task {
                            await updateService.manualUpdate()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .rotationEffect(.degrees(discussionsService.isLoading ? 360 : 0))
                            .animation(
                                discussionsService.isLoading ? 
                                    Animation.linear(duration: 1).repeatForever(autoreverses: false) : 
                                    DesignSystem.Animation.medium, 
                                value: discussionsService.isLoading
                            )
                    }
                    .buttonStyle(.borderless)
                    .disabled(discussionsService.isLoading)
                    .help(updateService.isAutoUpdateEnabled ? "Refresh (⌘R) - Auto-update: \(updateService.formattedNextUpdateTime)" : "Refresh (⌘R) - Auto-update disabled")
                    .keyboardShortcut("r", modifiers: .command)
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .font(DesignSystem.Typography.body)
                    
                    TextField("Search discussions...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.body)
                        .focused($isSearchFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(DesignSystem.Animation.fast) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .buttonStyle(.borderless)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .stroke(isSearchFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
                                .animation(DesignSystem.Animation.fast, value: isSearchFocused)
                        )
                )
                
                // Filters panel
                if showingFilters {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Category:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .controlSize(.small)
                            
                            Spacer()
                            
                            Text("State:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("State", selection: $selectedState) {
                                ForEach(states, id: \.self) { state in
                                    Text(state).tag(state)
                                }
                            }
                            .pickerStyle(.menu)
                            .controlSize(.small)
                        }
                        
                        HStack {
                            Text("\(filteredDiscussions.count) of \(discussionsService.discussions.count) discussions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if searchText != "" || selectedCategory != "All" || selectedState != "All" {
                                Button("Clear Filters") {
                                    searchText = ""
                                    selectedCategory = "All"
                                    selectedState = "All"
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.top, DesignSystem.Spacing.md)
            
            Divider()
                .padding(.top, 8)
            
            // Content with loading states
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    if discussionsService.isLoading && filteredDiscussions.isEmpty {
                        LoadingDiscussionsList()
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        ForEach(filteredDiscussions) { discussion in
                            DiscussionRowView(discussion: discussion)
                                .interactiveCardStyle {
                                    withAnimation(DesignSystem.Animation.medium) {
                                        onDiscussionSelected(discussion)
                                    }
                                }
                                .contextMenu {
                                    Button("Open in GitHub") {
                                        openDiscussionInBrowser(discussion)
                                    }
                                    Button("View Details") {
                                        onDiscussionSelected(discussion)
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.sm)
            }
            .withLoadingState(
                isLoading: discussionsService.isLoading && filteredDiscussions.isEmpty,
                errorMessage: discussionsService.errorMessage,
                isEmpty: filteredDiscussions.isEmpty && !discussionsService.isLoading,
                loading: {
                    LoadingStateView(message: "Loading discussions...")
                },
                errorView: { errorMessage in
                    ErrorStateView(
                        title: "Failed to load discussions",
                        message: errorMessage
                    ) {
                        Task {
                            await discussionsService.refreshDiscussions()
                        }
                    }
                },
                empty: {
                    if !discussionsService.discussions.isEmpty {
                        // No search results
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No matching discussions",
                            message: "Try adjusting your search or filters",
                            actionTitle: "Clear Filters",
                            action: {
                                withAnimation(DesignSystem.Animation.fast) {
                                    searchText = ""
                                    selectedCategory = "All"
                                    selectedState = "All"
                                }
                            }
                        )
                    } else {
                        // Truly empty state
                        EmptyStateView(
                            icon: "bubble.left.and.bubble.right",
                            title: "No discussions found",
                            message: "Be the first to start a discussion!",
                            actionTitle: "New Discussion",
                            action: {
                                // Post notification to switch to new post tab
                                NotificationCenter.default.post(name: .keyboardShortcut, object: "newPost")
                            }
                        )
                    }
                }
            )
        }
        .onAppear {
            if discussionsService.discussions.isEmpty {
                Task {
                    if authService.isAuthenticated {
                        await discussionsService.refreshDiscussions()
                    } else {
                        await authService.validateToken()
                        if authService.isAuthenticated {
                            await discussionsService.refreshDiscussions()
                        }
                    }
                }
            }
        }
        .onChange(of: searchText) { _ in
            // Debounce search to avoid excessive filtering
            // For now, we'll do immediate filtering
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshRequested)) { _ in
            Task {
                await updateService.manualUpdate()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newDiscussionsAvailable)) { notification in
            if let count = notification.userInfo?["count"] as? Int {
                notificationService.updateBadgeCount(count)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            isSearchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleFilters)) { _ in
            withAnimation(DesignSystem.Animation.medium) {
                showingFilters.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .escapePressed)) { _ in
            if isSearchFocused {
                isSearchFocused = false
            } else if showingFilters {
                withAnimation(DesignSystem.Animation.medium) {
                    showingFilters = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearAction)) { _ in
            withAnimation(DesignSystem.Animation.fast) {
                searchText = ""
                selectedCategory = "All"
                selectedState = "All"
            }
        }
    }
    
    
    private func openDiscussionInBrowser(_ discussion: Discussion) {
        if let url = URL(string: discussion.url) {
            NSWorkspace.shared.open(url)
        }
    }
    
}

struct DiscussionRowView: View {
    let discussion: Discussion
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                StatusBadge(text: "#\(discussion.number)", style: .neutral)
                
                StatusBadge(
                    text: discussion.category.emoji + " " + discussion.category.name,
                    style: .info
                )
                
                Spacer()
                
                Text(timeAgoString(from: discussion.updatedAt))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            // Title
            Text(discussion.title)
                .font(DesignSystem.Typography.bodyLarge)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Body preview
            if let body = discussion.body, !body.isEmpty {
                Text(body)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Footer
            HStack {
                Text("@\(discussion.author.login)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.githubAuthor)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "bubble.left")
                        .font(DesignSystem.Typography.caption)
                    Text("\(discussion.commentsCount)")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        // Note: Styling is now handled by .interactiveCardStyle() modifier
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}

#Preview {
    DiscussionsListView(settingsManager: SettingsManager())
        .frame(width: 400, height: 500)
        .environmentObject(NotificationService())
}