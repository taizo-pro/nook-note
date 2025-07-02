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
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")
            }
            .padding(.horizontal)
            .padding(.top)
            
            if settingsManager.settings.isConfigured {
                // Main Content - Tabbed Interface
                VStack(spacing: 0) {
                    // Tab Bar
                    HStack {
                        TabButton(title: "Discussions", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        TabButton(title: "New Post", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        DiscussionsListView(
                            settingsManager: settingsManager,
                            onDiscussionSelected: { discussion in
                                selectedDiscussion = discussion
                                showingDiscussionDetail = true
                            }
                        )
                        .tag(0)
                        
                        NewPostView(settingsManager: settingsManager)
                            .tag(1)
                    }
                    .tabViewStyle(.automatic)
                }
            } else {
                // Setup Required View
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Setup Required")
                        .font(.headline)
                    
                    Text("Configure your GitHub repository and access token to get started.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Open Settings") {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("GitHub Discussions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
                .font(.caption)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingSettings) {
            SettingsView(settingsManager: settingsManager)
        }
        .sheet(isPresented: $showingDiscussionDetail) {
            if let discussion = selectedDiscussion {
                DiscussionDetailView(discussion: discussion, settingsManager: settingsManager)
            }
        }
        .environmentObject(notificationService)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            notificationService.clearBadge()
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Rectangle()
                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}