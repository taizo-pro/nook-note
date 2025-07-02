import SwiftUI

struct DiscussionDetailView: View {
    let discussion: Discussion
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var authService: AuthenticationService
    @StateObject private var discussionsService: DiscussionsService
    @State private var comments: [Comment] = []
    @State private var isLoadingComments = false
    @State private var commentsError: String?
    @State private var showingCommentComposer = false
    @State private var newCommentBody = ""
    @State private var isPostingComment = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var notificationService: NotificationService
    
    init(discussion: Discussion, settingsManager: SettingsManager) {
        self.discussion = discussion
        self.settingsManager = settingsManager
        let authService = AuthenticationService(settingsManager: settingsManager)
        let apiClient = GitHubAPIClient(authenticationService: authService)
        let discussionsService = DiscussionsService(apiClient: apiClient, settingsManager: settingsManager)
        
        self._authService = StateObject(wrappedValue: authService)
        self._discussionsService = StateObject(wrappedValue: discussionsService)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("← Back") {
                    dismiss()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.accentColor)
                
                Spacer()
                
                Button(action: {
                    if let url = URL(string: discussion.url) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Image(systemName: "safari")
                }
                .buttonStyle(.borderless)
                .help("Open in GitHub")
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Divider()
                .padding(.top, 8)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Discussion header
                    VStack(alignment: .leading, spacing: 12) {
                        // Title and number
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
                            
                            Text(formatDate(discussion.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(discussion.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Author and meta info
                        HStack {
                            Text("@\(discussion.author.login)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if discussion.createdAt != discussion.updatedAt {
                                Text("• Updated \(timeAgoString(from: discussion.updatedAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.caption)
                                Text("\(discussion.commentsCount)")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Body content
                        if let body = discussion.body, !body.isEmpty {
                            Text(body)
                                .font(.body)
                                .lineSpacing(4)
                        } else {
                            Text("No description provided.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Comments section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Comments (\(comments.count))")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showingCommentComposer.toggle()
                            }) {
                                Image(systemName: "plus.bubble")
                            }
                            .buttonStyle(.borderless)
                            .help("Add Comment")
                        }
                        
                        if isLoadingComments {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading comments...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical)
                        } else if let error = commentsError {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("Failed to load comments")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                HStack {
                                    Button("Try Again") {
                                        loadComments()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    
                                    Spacer()
                                }
                            }
                            .padding(.vertical)
                        } else if comments.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                
                                Text("No comments yet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Be the first to comment!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            // Comments list
                            LazyVStack(spacing: 8) {
                                ForEach(comments) { comment in
                                    CommentRowView(comment: comment)
                                }
                            }
                        }
                    }
                    
                    // Comment composer
                    if showingCommentComposer {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Add Comment")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Cancel") {
                                    showingCommentComposer = false
                                    newCommentBody = ""
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                            }
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(8)
                                
                                if newCommentBody.isEmpty {
                                    Text("Write your comment here...")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, 8)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $newCommentBody)
                                    .font(.system(size: 13))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                                    .background(Color.clear)
                                    .disabled(isPostingComment)
                            }
                            .frame(minHeight: 80)
                            
                            HStack {
                                Text("\(newCommentBody.count) characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button(action: postComment) {
                                    HStack {
                                        if isPostingComment {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                        Text(isPostingComment ? "Posting..." : "Post Comment")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isPostingComment || newCommentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        .padding(16)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        guard authService.isAuthenticated else {
            commentsError = "Authentication required"
            return
        }
        
        isLoadingComments = true
        commentsError = nil
        
        Task {
            do {
                let loadedComments = try await discussionsService.loadComments(for: discussion)
                await MainActor.run {
                    comments = loadedComments
                    isLoadingComments = false
                }
            } catch {
                await MainActor.run {
                    commentsError = error.localizedDescription
                    isLoadingComments = false
                }
            }
        }
    }
    
    private func postComment() {
        guard !newCommentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isPostingComment = true
        
        Task {
            do {
                let newComment = try await discussionsService.addComment(
                    to: discussion.id,
                    body: newCommentBody
                )
                
                await MainActor.run {
                    comments.append(newComment)
                    newCommentBody = ""
                    showingCommentComposer = false
                    isPostingComment = false
                    
                    // Notify success
                    notificationService.showInAppSuccess(message: "Comment posted successfully")
                    NotificationCenter.default.post(name: .commentPosted, object: nil)
                }
            } catch {
                await MainActor.run {
                    commentsError = "Failed to post comment: \(error.localizedDescription)"
                    isPostingComment = false
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("@\(comment.author.login)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(timeAgoString(from: comment.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if comment.createdAt != comment.updatedAt {
                    Text("(edited)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Body
            Text(comment.body)
                .font(.system(size: 13))
                .lineSpacing(2)
            
            if comment.isMinimized {
                Text("This comment has been minimized.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
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
    let mockUser = User(
        id: "1",
        login: "demo-user",
        avatarUrl: "https://github.com/demo-user.png",
        url: "https://github.com/demo-user"
    )
    
    let mockCategory = DiscussionCategory(
        id: "1",
        name: "General",
        emoji: "💬",
        description: "General discussions"
    )
    
    let mockDiscussion = Discussion(
        id: "1",
        number: 1,
        title: "Welcome to NookNote!",
        body: "This is a sample discussion to demonstrate the detailed view interface.",
        author: mockUser,
        category: mockCategory,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-3600),
        url: "https://github.com/demo/repo/discussions/1",
        comments: CommentCount(totalCount: 3),
        locked: false,
        state: .open
    )
    
    return DiscussionDetailView(discussion: mockDiscussion, settingsManager: SettingsManager())
}