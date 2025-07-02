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
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showingFilters.toggle()
                    }) {
                        Image(systemName: showingFilters ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Filters")
                    
                    Button(action: {
                        Task {
                            await updateService.manualUpdate()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(discussionsService.isLoading ? 360 : 0))
                            .animation(discussionsService.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: discussionsService.isLoading)
                    }
                    .buttonStyle(.borderless)
                    .disabled(discussionsService.isLoading)
                    .help(updateService.isAutoUpdateEnabled ? "Refresh (Auto-update: \(updateService.formattedNextUpdateTime))" : "Refresh (Auto-update disabled)")
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search discussions...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
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
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider()
                .padding(.top, 8)
            
            if discussionsService.isLoading && filteredDiscussions.isEmpty {
                // Initial loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading discussions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = discussionsService.errorMessage {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Failed to load discussions")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        Task {
                            await discussionsService.refreshDiscussions()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredDiscussions.isEmpty && !discussionsService.discussions.isEmpty {
                // No search results
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No matching discussions")
                        .font(.headline)
                    
                    Text("Try adjusting your search or filters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if discussionsService.discussions.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No discussions found")
                        .font(.headline)
                    
                    Text("Be the first to start a discussion!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Discussions list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredDiscussions) { discussion in
                            DiscussionRowView(discussion: discussion)
                                .onTapGesture {
                                    onDiscussionSelected(discussion)
                                }
                                .contextMenu {
                                    Button("Open in GitHub") {
                                        openDiscussionInBrowser(discussion)
                                    }
                                    Button("View Details") {
                                        onDiscussionSelected(discussion)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
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
    }
    
    
    private func openDiscussionInBrowser(_ discussion: Discussion) {
        if let url = URL(string: discussion.url) {
            NSWorkspace.shared.open(url)
        }
    }
    
}

struct DiscussionRowView: View {
    let discussion: Discussion
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("#\(discussion.number)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(discussion.category.emoji + " " + discussion.category.name)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(timeAgoString(from: discussion.updatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(discussion.title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            
            // Body preview
            if let body = discussion.body, !body.isEmpty {
                Text(body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isHovered ? 3 : 2)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
            }
            
            // Footer
            HStack {
                Text("@\(discussion.author.login)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.caption)
                    Text("\(discussion.commentsCount)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
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
        .frame(width: 400, height: 400)
}