import XCTest
import Combine
@testable import NookNote

@MainActor
final class DiscussionsServiceTests: XCTestCase {
    
    private var discussionsService: DiscussionsService!
    private var mockAPIClient: MockGitHubAPIClient!
    private var settingsManager: SettingsManager!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockGitHubAPIClient()
        settingsManager = SettingsManager()
        discussionsService = DiscussionsService(apiClient: mockAPIClient, settingsManager: settingsManager)
        cancellables = Set<AnyCancellable>()
        
        // Configure settings for testing
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_test123"
    }
    
    override func tearDown() {
        cancellables.removeAll()
        discussionsService = nil
        mockAPIClient = nil
        settingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertTrue(discussionsService.discussions.isEmpty)
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertNil(discussionsService.errorMessage)
        XCTAssertFalse(discussionsService.hasMorePages)
        XCTAssertTrue(discussionsService.isEmpty)
        XCTAssertFalse(discussionsService.hasError)
    }
    
    // MARK: - Load Discussions Tests
    
    func testLoadDiscussionsSuccess() async {
        // Given
        let mockDiscussions = createMockDiscussions()
        let mockResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: mockDiscussions,
                        pageInfo: PageInfo(
                            hasNextPage: false,
                            hasPreviousPage: false,
                            startCursor: nil,
                            endCursor: nil
                        ),
                        totalCount: mockDiscussions.count
                    )
                )
            )
        )
        
        mockAPIClient.mockFetchDiscussionsResponse = mockResponse
        
        // When
        await discussionsService.loadDiscussions()
        
        // Then
        XCTAssertEqual(discussionsService.discussions.count, mockDiscussions.count)
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertNil(discussionsService.errorMessage)
        XCTAssertFalse(discussionsService.hasMorePages)
        XCTAssertFalse(discussionsService.isEmpty)
    }
    
    func testLoadDiscussionsWithPagination() async {
        // Given
        let mockDiscussions = createMockDiscussions()
        let mockResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: mockDiscussions,
                        pageInfo: PageInfo(
                            hasNextPage: true,
                            hasPreviousPage: false,
                            startCursor: nil,
                            endCursor: "cursor123"
                        ),
                        totalCount: 50
                    )
                )
            )
        )
        
        mockAPIClient.mockFetchDiscussionsResponse = mockResponse
        
        // When
        await discussionsService.loadDiscussions()
        
        // Then
        XCTAssertEqual(discussionsService.discussions.count, mockDiscussions.count)
        XCTAssertTrue(discussionsService.hasMorePages)
    }
    
    func testLoadDiscussionsNotConfigured() async {
        // Given
        settingsManager.settings.repositoryOwner = ""
        settingsManager.settings.repositoryName = ""
        settingsManager.settings.personalAccessToken = ""
        
        // When
        await discussionsService.loadDiscussions()
        
        // Then
        XCTAssertTrue(discussionsService.discussions.isEmpty)
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertEqual(discussionsService.errorMessage, "GitHub repository not configured")
    }
    
    func testLoadDiscussionsAPIError() async {
        // Given
        mockAPIClient.shouldThrowError = true
        mockAPIClient.errorToThrow = APIError.unauthorized
        
        // When
        await discussionsService.loadDiscussions()
        
        // Then
        XCTAssertTrue(discussionsService.discussions.isEmpty)
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertNotNil(discussionsService.errorMessage)
        XCTAssertTrue(discussionsService.hasError)
    }
    
    func testLoadDiscussionsGenericError() async {
        // Given
        mockAPIClient.shouldThrowError = true
        mockAPIClient.errorToThrow = URLError(.timedOut)
        
        // When
        await discussionsService.loadDiscussions()
        
        // Then
        XCTAssertTrue(discussionsService.discussions.isEmpty)
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertTrue(discussionsService.errorMessage?.contains("Failed to load discussions:") == true)
    }
    
    func testLoadDiscussionsRefresh() async {
        // Given - Load initial discussions
        let initialDiscussions = createMockDiscussions(count: 2)
        let initialResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: initialDiscussions,
                        pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil),
                        totalCount: 2
                    )
                )
            )
        )
        mockAPIClient.mockFetchDiscussionsResponse = initialResponse
        await discussionsService.loadDiscussions()
        
        // Then - Load with refresh
        let refreshedDiscussions = createMockDiscussions(count: 3, startId: 10)
        let refreshResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: refreshedDiscussions,
                        pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil),
                        totalCount: 3
                    )
                )
            )
        )
        mockAPIClient.mockFetchDiscussionsResponse = refreshResponse
        
        // When
        await discussionsService.loadDiscussions(refresh: true)
        
        // Then
        XCTAssertEqual(discussionsService.discussions.count, 3)
        XCTAssertEqual(discussionsService.discussions[0].id, "10") // New discussions should replace old ones
    }
    
    // MARK: - Load More Discussions Tests
    
    func testLoadMoreDiscussions() async {
        // Given - Initial load with pagination
        let initialDiscussions = createMockDiscussions(count: 2)
        let initialResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: initialDiscussions,
                        pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false, startCursor: nil, endCursor: "cursor123"),
                        totalCount: 5
                    )
                )
            )
        )
        mockAPIClient.mockFetchDiscussionsResponse = initialResponse
        await discussionsService.loadDiscussions()
        
        // Set up next page response
        let moreDiscussions = createMockDiscussions(count: 3, startId: 10)
        let moreResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: moreDiscussions,
                        pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: true, startCursor: "cursor123", endCursor: nil),
                        totalCount: 5
                    )
                )
            )
        )
        mockAPIClient.mockFetchDiscussionsResponse = moreResponse
        
        // When
        await discussionsService.loadMoreDiscussions()
        
        // Then
        XCTAssertEqual(discussionsService.discussions.count, 5) // Initial 2 + 3 more
        XCTAssertFalse(discussionsService.hasMorePages)
    }
    
    func testLoadMoreDiscussionsWhenAlreadyLoading() async {
        // Given
        let mockResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: [],
                        pageInfo: PageInfo(hasNextPage: true, hasPreviousPage: false, startCursor: nil, endCursor: nil),
                        totalCount: 0
                    )
                )
            )
        )
        mockAPIClient.mockFetchDiscussionsResponse = mockResponse
        mockAPIClient.simulateDelay = true
        
        // When - Start loading and immediately try to load more
        let loadTask = Task { await discussionsService.loadDiscussions() }
        await discussionsService.loadMoreDiscussions() // Should be ignored
        await loadTask.value
        
        // Then
        XCTAssertEqual(mockAPIClient.fetchDiscussionsCallCount, 1) // Only one call should have been made
    }
    
    func testLoadMoreDiscussionsWhenNoMorePages() async {
        // Given
        let mockResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: createMockDiscussions(),
                        pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil),
                        totalCount: 2
                    )
                )
            )
        )
        mockAPIClient.mockFetchDiscussionsResponse = mockResponse
        await discussionsService.loadDiscussions()
        
        // When
        await discussionsService.loadMoreDiscussions()
        
        // Then
        XCTAssertEqual(mockAPIClient.fetchDiscussionsCallCount, 1) // Only initial call, no additional call
    }
    
    // MARK: - Create Discussion Tests
    
    func testCreateDiscussionSuccess() async {
        // Given
        let newDiscussion = createMockDiscussion(id: "new123", number: 999, title: "New Discussion")
        let mockResponse = CreateDiscussionResponse(
            data: CreateDiscussionData(
                createDiscussion: CreateDiscussionPayload(discussion: newDiscussion)
            ),
            errors: nil
        )
        mockAPIClient.mockCreateDiscussionResponse = mockResponse
        
        // When
        let success = await discussionsService.createDiscussion(
            title: "New Discussion",
            body: "Discussion body",
            category: "general"
        )
        
        // Then
        XCTAssertTrue(success)
        XCTAssertEqual(discussionsService.discussions.count, 1)
        XCTAssertEqual(discussionsService.discussions[0].title, "New Discussion")
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertNil(discussionsService.errorMessage)
    }
    
    func testCreateDiscussionEmptyTitle() async {
        // When
        let success = await discussionsService.createDiscussion(
            title: "   ",
            body: "Discussion body",
            category: "general"
        )
        
        // Then
        XCTAssertFalse(success)
        XCTAssertTrue(discussionsService.discussions.isEmpty)
        XCTAssertEqual(discussionsService.errorMessage, "Discussion title cannot be empty")
    }
    
    func testCreateDiscussionNotConfigured() async {
        // Given
        settingsManager.settings.repositoryOwner = ""
        
        // When
        let success = await discussionsService.createDiscussion(
            title: "Test",
            body: "Body",
            category: "general"
        )
        
        // Then
        XCTAssertFalse(success)
        XCTAssertEqual(discussionsService.errorMessage, "GitHub repository not configured")
    }
    
    func testCreateDiscussionAPIError() async {
        // Given
        mockAPIClient.shouldThrowError = true
        mockAPIClient.errorToThrow = APIError.rateLimited
        
        // When
        let success = await discussionsService.createDiscussion(
            title: "Test",
            body: "Body",
            category: "general"
        )
        
        // Then
        XCTAssertFalse(success)
        XCTAssertTrue(discussionsService.discussions.isEmpty)
        XCTAssertNotNil(discussionsService.errorMessage)
        XCTAssertFalse(discussionsService.isLoading)
    }
    
    // MARK: - Comments Tests
    
    func testLoadCommentsSuccess() async throws {
        // Given
        let discussion = createMockDiscussion()
        let mockComments = createMockComments()
        let mockResponse = CommentsResponse(
            data: CommentsData(
                repository: CommentRepository(
                    discussion: DiscussionComments(
                        comments: CommentConnection(
                            nodes: mockComments,
                            pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil),
                            totalCount: mockComments.count
                        )
                    )
                )
            )
        )
        mockAPIClient.mockFetchCommentsResponse = mockResponse
        
        // When
        let comments = try await discussionsService.loadComments(for: discussion)
        
        // Then
        XCTAssertEqual(comments.count, mockComments.count)
        XCTAssertEqual(comments[0].body, "First comment")
    }
    
    func testLoadCommentsNotConfigured() async {
        // Given
        settingsManager.settings.repositoryOwner = ""
        let discussion = createMockDiscussion()
        
        // Then
        do {
            _ = try await discussionsService.loadComments(for: discussion)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
            XCTAssertEqual(error as? APIError, .authenticationRequired)
        }
    }
    
    func testAddCommentSuccess() async throws {
        // Given
        let mockComment = createMockComment(body: "New comment")
        let mockResponse = CreateCommentResponse(
            data: CreateCommentData(
                addDiscussionComment: AddDiscussionCommentPayload(comment: mockComment)
            ),
            errors: nil
        )
        mockAPIClient.mockAddCommentResponse = mockResponse
        
        // When
        let comment = try await discussionsService.addComment(to: "discussion123", body: "New comment")
        
        // Then
        XCTAssertEqual(comment.body, "New comment")
    }
    
    func testAddCommentEmptyBody() async {
        // Then
        do {
            _ = try await discussionsService.addComment(to: "discussion123", body: "   ")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    // MARK: - Helper Methods Tests
    
    func testClearError() async {
        // Given
        mockAPIClient.shouldThrowError = true
        mockAPIClient.errorToThrow = APIError.unauthorized
        await discussionsService.loadDiscussions()
        XCTAssertNotNil(discussionsService.errorMessage)
        
        // When
        discussionsService.clearError()
        
        // Then
        XCTAssertNil(discussionsService.errorMessage)
        XCTAssertFalse(discussionsService.hasError)
    }
    
    func testGetDiscussionByNumber() async {
        // Given
        let mockDiscussions = createMockDiscussions()
        let mockResponse = DiscussionsResponse(
            data: DiscussionsData(
                repository: Repository(
                    discussions: DiscussionConnection(
                        nodes: mockDiscussions,
                        pageInfo: PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil),
                        totalCount: mockDiscussions.count
                    )
                )
            )
        )
        mockAPIClient.mockFetchDiscussionsResponse = mockResponse
        await discussionsService.loadDiscussions()
        
        // When
        let foundDiscussion = discussionsService.getDiscussion(by: 1)
        let notFoundDiscussion = discussionsService.getDiscussion(by: 999)
        
        // Then
        XCTAssertNotNil(foundDiscussion)
        XCTAssertEqual(foundDiscussion?.number, 1)
        XCTAssertNil(notFoundDiscussion)
    }
    
    func testLoadMockData() async {
        // When
        await discussionsService.loadMockData()
        
        // Then
        XCTAssertEqual(discussionsService.discussions.count, 3)
        XCTAssertEqual(discussionsService.discussions[0].title, "Welcome to NookNote!")
        XCTAssertFalse(discussionsService.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createMockDiscussions(count: Int = 2, startId: Int = 1) -> [Discussion] {
        return (0..<count).map { index in
            createMockDiscussion(
                id: "\(startId + index)",
                number: startId + index,
                title: "Test Discussion \(startId + index)"
            )
        }
    }
    
    private func createMockDiscussion(id: String = "1", number: Int = 1, title: String = "Test Discussion") -> Discussion {
        let mockUser = User(
            id: "user1",
            login: "testuser",
            avatarUrl: "https://github.com/testuser.png",
            url: "https://github.com/testuser"
        )
        
        let mockCategory = DiscussionCategory(
            id: "cat1",
            name: "General",
            emoji: "💬",
            description: "General discussions"
        )
        
        return Discussion(
            id: id,
            number: number,
            title: title,
            body: "Test discussion body",
            author: mockUser,
            category: mockCategory,
            createdAt: Date(),
            updatedAt: Date(),
            url: "https://github.com/test/repo/discussions/\(number)",
            comments: CommentCount(totalCount: 0),
            locked: false,
            state: .open
        )
    }
    
    private func createMockComments() -> [Comment] {
        let mockUser = User(
            id: "user1",
            login: "testuser",
            avatarUrl: "https://github.com/testuser.png",
            url: "https://github.com/testuser"
        )
        
        return [
            Comment(
                id: "comment1",
                body: "First comment",
                author: mockUser,
                createdAt: Date(),
                updatedAt: Date(),
                url: "https://github.com/test/repo/discussions/1#comment-1",
                replyTo: nil,
                isMinimized: false
            ),
            Comment(
                id: "comment2",
                body: "Second comment",
                author: mockUser,
                createdAt: Date(),
                updatedAt: Date(),
                url: "https://github.com/test/repo/discussions/1#comment-2",
                replyTo: nil,
                isMinimized: false
            )
        ]
    }
    
    private func createMockComment(body: String = "Test comment") -> Comment {
        let mockUser = User(
            id: "user1",
            login: "testuser",
            avatarUrl: "https://github.com/testuser.png",
            url: "https://github.com/testuser"
        )
        
        return Comment(
            id: "comment123",
            body: body,
            author: mockUser,
            createdAt: Date(),
            updatedAt: Date(),
            url: "https://github.com/test/repo/discussions/1#comment-123",
            replyTo: nil,
            isMinimized: false
        )
    }
}

// MARK: - Mock GitHubAPIClient

class MockGitHubAPIClient: GitHubAPIClient {
    var mockFetchDiscussionsResponse: DiscussionsResponse?
    var mockCreateDiscussionResponse: CreateDiscussionResponse?
    var mockFetchCommentsResponse: CommentsResponse?
    var mockAddCommentResponse: CreateCommentResponse?
    
    var shouldThrowError = false
    var errorToThrow: Error = APIError.invalidURL
    var simulateDelay = false
    
    var fetchDiscussionsCallCount = 0
    
    override func fetchDiscussions(owner: String, repository: String, first: Int, after: String?) async throws -> DiscussionsResponse {
        fetchDiscussionsCallCount += 1
        
        if simulateDelay {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let response = mockFetchDiscussionsResponse else {
            throw APIError.invalidURL
        }
        
        return response
    }
    
    override func createDiscussion(owner: String, repository: String, title: String, body: String, categoryId: String) async throws -> CreateDiscussionResponse {
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let response = mockCreateDiscussionResponse else {
            throw APIError.invalidURL
        }
        
        return response
    }
    
    override func fetchDiscussionComments(owner: String, repository: String, discussionNumber: Int) async throws -> CommentsResponse {
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let response = mockFetchCommentsResponse else {
            throw APIError.invalidURL
        }
        
        return response
    }
    
    override func addDiscussionComment(discussionId: String, body: String) async throws -> CreateCommentResponse {
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let response = mockAddCommentResponse else {
            throw APIError.invalidURL
        }
        
        return response
    }
}