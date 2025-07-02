import SwiftUI

struct NewPostView: View {
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var authService: AuthenticationService
    @StateObject private var discussionsService: DiscussionsService
    @EnvironmentObject var notificationService: NotificationService
    @State private var title: String = ""
    @State private var discussionBody: String = ""
    @State private var selectedCategory: String = "General"
    @State private var postingMessage: String = ""
    @State private var postingSuccess = false
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        let authService = AuthenticationService(settingsManager: settingsManager)
        let apiClient = GitHubAPIClient(authenticationService: authService)
        let discussionsService = DiscussionsService(apiClient: apiClient, settingsManager: settingsManager)
        
        self._authService = StateObject(wrappedValue: authService)
        self._discussionsService = StateObject(wrappedValue: discussionsService)
    }
    
    private let categories = ["General", "Ideas", "Q&A", "Show and tell"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Discussion")
                    .font(.headline)
                
                Spacer()
                
                Button(action: clearForm) {
                    Image(systemName: "trash")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.borderless)
                .disabled(discussionsService.isLoading)
                .help("Clear (⌘K)")
                .keyboardShortcut("k", modifiers: .command)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider()
                .padding(.top, 8)
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(categoryDisplayText(category))
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Title Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        
                        TextField("Enter discussion title...", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .disabled(discussionsService.isLoading)
                    }
                    
                    // Body Input
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Description")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(discussionBody.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                            
                            if discussionBody.isEmpty {
                                Text("Write your discussion content here...\n\nYou can use **Markdown** formatting:\n• **Bold text**\n• *Italic text*\n• `code snippets`\n• [Links](https://example.com)")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 13))
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $discussionBody)
                                .font(.system(size: 13))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                                .background(Color.clear)
                                .disabled(discussionsService.isLoading)
                        }
                        .frame(minHeight: 120)
                        
                        Text("Markdown formatting supported")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Repository Info
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        
                        Text("Will be posted to: \(settingsManager.settings.repositoryURL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Status Message
                    if !postingMessage.isEmpty {
                        HStack {
                            Image(systemName: postingSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(postingSuccess ? .green : .orange)
                            
                            Text(postingMessage)
                                .font(.caption)
                                .foregroundColor(postingSuccess ? .green : .orange)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Clear") {
                    clearForm()
                }
                .secondaryButtonStyle()
                .disabled(discussionsService.isLoading)
                .keyboardShortcut("k", modifiers: .command)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await postDiscussion()
                    }
                }) {
                    HStack {
                        if discussionsService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(discussionsService.isLoading ? "Posting..." : "Post Discussion")
                    }
                }
                .primaryButtonStyle()
                .disabled(discussionsService.isLoading || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    private func categoryDisplayText(_ category: String) -> String {
        switch category {
        case "General":
            return "💬 General"
        case "Ideas":
            return "💡 Ideas"
        case "Q&A":
            return "❓ Q&A"
        case "Show and tell":
            return "🙌 Show and tell"
        default:
            return category
        }
    }
    
    private func clearForm() {
        withAnimation(DesignSystem.Animation.fast) {
            title = ""
            discussionBody = ""
            selectedCategory = "General"
            postingMessage = ""
            postingSuccess = false
        }
    }
    
    private func postDiscussion() async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        postingMessage = ""
        
        // Ensure authentication
        if !authService.isAuthenticated {
            await authService.validateToken()
            if !authService.isAuthenticated {
                postingMessage = "Authentication required. Please check your settings."
                postingSuccess = false
                return
            }
        }
        
        let success = await discussionsService.createDiscussion(
            title: title,
            body: discussionBody,
            category: selectedCategory
        )
        
        if success {
            withAnimation(DesignSystem.Animation.spring) {
                postingMessage = "Discussion posted successfully!"
                postingSuccess = true
            }
            
            // Notify success
            notificationService.showInAppSuccess(message: "Discussion posted successfully!")
            NotificationCenter.default.post(name: .discussionPosted, object: nil)
            
            // Clear form after success with animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(DesignSystem.Animation.medium) {
                    clearForm()
                }
            }
        } else {
            withAnimation(DesignSystem.Animation.fast) {
                postingMessage = discussionsService.errorMessage ?? "Failed to post discussion"
                postingSuccess = false
            }
            
            // Notify error
            notificationService.showInAppError(message: postingMessage)
        }
    }
}

#Preview {
    NewPostView(settingsManager: SettingsManager())
        .frame(width: 400, height: 500)
}