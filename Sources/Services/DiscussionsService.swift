import Foundation
import Combine

class DiscussionsService: ObservableObject {
    @Published var discussions: [Discussion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMorePages = false
    
    private let apiClient: GitHubAPIClient
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()
    private var currentCursor: String?
    
    init(apiClient: GitHubAPIClient, settingsManager: SettingsManager) {
        self.apiClient = apiClient
        self.settingsManager = settingsManager
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func loadDiscussions(refresh: Bool = false) async {
        guard settingsManager.settings.isConfigured else {
            errorMessage = "GitHub repository not configured"
            return
        }
        
        if refresh {
            discussions = []
            currentCursor = nil
            hasMorePages = false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.fetchDiscussions(
                owner: settingsManager.settings.repositoryOwner,
                repository: settingsManager.settings.repositoryName,
                first: 20,
                after: currentCursor
            )
            
            let newDiscussions = response.data.repository.discussions.nodes
            
            if refresh {
                discussions = newDiscussions
            } else {
                discussions.append(contentsOf: newDiscussions)
            }
            
            currentCursor = response.data.repository.discussions.pageInfo.endCursor
            hasMorePages = response.data.repository.discussions.pageInfo.hasNextPage
            
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load discussions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMoreDiscussions() async {
        guard !isLoading && hasMorePages else { return }
        await loadDiscussions(refresh: false)
    }
    
    @MainActor
    func refreshDiscussions() async {
        await loadDiscussions(refresh: true)
    }
    
    @MainActor
    func createDiscussion(title: String, body: String, category: String) async -> Bool {
        guard settingsManager.settings.isConfigured else {
            errorMessage = "GitHub repository not configured"
            return false
        }
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Discussion title cannot be empty"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.createDiscussion(
                owner: settingsManager.settings.repositoryOwner,
                repository: settingsManager.settings.repositoryName,
                title: title,
                body: body,
                categoryId: category
            )
            
            // Add new discussion to the beginning of the list
            discussions.insert(response.data.createDiscussion.discussion, at: 0)
            
            isLoading = false
            return true
            
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        } catch {
            errorMessage = "Failed to create discussion: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Discussion Details
    
    func loadComments(for discussion: Discussion) async throws -> [Comment] {
        guard settingsManager.settings.isConfigured else {
            throw APIError.authenticationRequired
        }
        
        let response = try await apiClient.fetchDiscussionComments(
            owner: settingsManager.settings.repositoryOwner,
            repository: settingsManager.settings.repositoryName,
            discussionNumber: discussion.number
        )
        
        return response.data.repository.discussion.comments.nodes
    }
    
    func addComment(to discussionId: String, body: String) async throws -> Comment {
        guard settingsManager.settings.isConfigured else {
            throw APIError.authenticationRequired
        }
        
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.invalidURL // Using this as a generic validation error
        }
        
        let response = try await apiClient.addDiscussionComment(
            discussionId: discussionId,
            body: body
        )
        
        return response.data?.addDiscussionComment.comment ?? Comment(
            id: "",
            body: body,
            author: User(id: "", login: "", avatarUrl: "", url: ""),
            createdAt: Date(),
            updatedAt: Date(),
            url: "",
            replyTo: nil,
            isMinimized: false
        )
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func getDiscussion(by number: Int) -> Discussion? {
        return discussions.first { $0.number == number }
    }
    
    var isEmpty: Bool {
        return discussions.isEmpty && !isLoading
    }
    
    var hasError: Bool {
        return errorMessage != nil
    }
}

// MARK: - Mock Data Helper (for development)
extension DiscussionsService {
    @MainActor
    func loadMockData() {
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
        
        discussions = [
            Discussion(
                id: "1",
                number: 1,
                title: "Welcome to NookNote!",
                body: "This is a sample discussion to demonstrate the interface. The app is now connected to GitHub API and can fetch real discussions.",
                author: mockUser,
                category: mockCategory,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-3600),
                url: "\(settingsManager.settings.repositoryURL)/discussions/1",
                comments: CommentCount(totalCount: 3),
                locked: false,
                state: .open
            ),
            Discussion(
                id: "2",
                number: 2,
                title: "Phase 3: GitHub API Integration Complete",
                body: "The GitHub API integration has been completed with full GraphQL support for discussions and comments.",
                author: mockUser,
                category: mockCategory,
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: Date().addingTimeInterval(-7200),
                url: "\(settingsManager.settings.repositoryURL)/discussions/2",
                comments: CommentCount(totalCount: 5),
                locked: false,
                state: .open
            ),
            Discussion(
                id: "3",
                number: 3,
                title: "Feature: Real-time Discussion Loading",
                body: "Discussions are now loaded directly from GitHub with proper pagination and error handling.",
                author: mockUser,
                category: mockCategory,
                createdAt: Date().addingTimeInterval(-259200),
                updatedAt: Date().addingTimeInterval(-14400),
                url: "\(settingsManager.settings.repositoryURL)/discussions/3",
                comments: CommentCount(totalCount: 2),
                locked: false,
                state: .open
            )
        ]
    }
}