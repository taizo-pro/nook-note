import XCTest
import Combine
@testable import NookNote

/// Integration tests for GitHub API connectivity and authentication flow.
/// These tests can be run against a real GitHub repository for validation.
/// Set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO environment variables to enable real API testing.
final class GitHubAPIIntegrationTests: XCTestCase {
    
    private var apiClient: GitHubAPIClient!
    private var authService: AuthenticationService!
    private var settingsManager: SettingsManager!
    private var cancellables: Set<AnyCancellable>!
    
    // Test configuration - set these via environment variables for real API testing
    private var testToken: String? {
        ProcessInfo.processInfo.environment["GITHUB_TEST_TOKEN"]
    }
    
    private var testRepo: String? {
        ProcessInfo.processInfo.environment["GITHUB_TEST_REPO"] // Format: "owner/repo"
    }
    
    private var useRealAPI: Bool {
        testToken != nil && testRepo != nil
    }
    
    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
        apiClient = GitHubAPIClient(settingsManager: settingsManager)
        authService = AuthenticationService(settingsManager: settingsManager)
        cancellables = Set<AnyCancellable>()
        
        // Configure test settings
        if let repo = testRepo {
            let components = repo.split(separator: "/")
            if components.count == 2 {
                settingsManager.settings.repositoryOwner = String(components[0])
                settingsManager.settings.repositoryName = String(components[1])
            }
        } else {
            // Use test values for mock testing
            settingsManager.settings.repositoryOwner = "testowner"
            settingsManager.settings.repositoryName = "testrepo"
        }
        
        if let token = testToken {
            settingsManager.settings.personalAccessToken = token
        } else {
            settingsManager.settings.personalAccessToken = "ghp_mock_token_for_testing"
        }
    }
    
    override func tearDown() {
        cancellables.removeAll()
        authService = nil
        apiClient = nil
        settingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Authentication Integration Tests
    
    func testAuthenticationFlow() async {
        guard useRealAPI else {
            print("⚠️ Skipping real API test - set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO to enable")
            return
        }
        
        // Test initial state
        XCTAssertEqual(authService.authenticationState, .configured)
        XCTAssertFalse(authService.isAuthenticated)
        
        // Test token validation
        await authService.validateToken()
        
        // Verify authentication succeeded
        XCTAssertEqual(authService.authenticationState, .valid)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNotNil(authService.authorizationHeader)
        XCTAssertTrue(authService.authorizationHeader?.hasPrefix("Bearer ") == true)
    }
    
    func testAuthenticationWithInvalidToken() async {
        // Configure with invalid token
        settingsManager.settings.personalAccessToken = "ghp_invalid_token_12345"
        
        guard useRealAPI else {
            print("⚠️ Skipping real API test - set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO to enable")
            return
        }
        
        // Test validation with invalid token
        await authService.validateToken()
        
        // Verify authentication failed
        if case .invalid(let error) = authService.authenticationState {
            XCTAssertTrue(error is AuthenticationError)
        } else {
            XCTFail("Expected authentication to fail with invalid token")
        }
        
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    func testAuthenticationWithMissingRepository() async {
        guard useRealAPI else {
            print("⚠️ Skipping real API test - set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO to enable")
            return
        }
        
        // Configure with non-existent repository
        settingsManager.settings.repositoryOwner = "nonexistent-user-12345"
        settingsManager.settings.repositoryName = "nonexistent-repo-12345"
        
        // Test validation
        await authService.validateToken()
        
        // Verify authentication failed
        if case .invalid(let error) = authService.authenticationState {
            XCTAssertTrue(error is AuthenticationError)
        } else {
            XCTFail("Expected authentication to fail with non-existent repository")
        }
    }
    
    // MARK: - API Client Integration Tests
    
    func testFetchDiscussionsIntegration() async throws {
        guard useRealAPI else {
            print("⚠️ Skipping real API test - set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO to enable")
            return
        }
        
        // Ensure we're authenticated first
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated, "Authentication must succeed for API tests")
        
        // Test fetching discussions
        let response = try await apiClient.fetchDiscussions(
            owner: settingsManager.settings.repositoryOwner,
            repository: settingsManager.settings.repositoryName,
            first: 10,
            after: nil
        )
        
        // Verify response structure
        XCTAssertNotNil(response.data.repository.discussions)
        XCTAssertNotNil(response.data.repository.discussions.pageInfo)
        XCTAssertGreaterThanOrEqual(response.data.repository.discussions.totalCount, 0)
        
        // Verify discussion data structure if discussions exist
        if !response.data.repository.discussions.nodes.isEmpty {
            let firstDiscussion = response.data.repository.discussions.nodes[0]
            XCTAssertFalse(firstDiscussion.id.isEmpty)
            XCTAssertGreaterThan(firstDiscussion.number, 0)
            XCTAssertFalse(firstDiscussion.title.isEmpty)
            XCTAssertNotNil(firstDiscussion.author)
            XCTAssertNotNil(firstDiscussion.category)
        }
        
        print("✅ Successfully fetched \(response.data.repository.discussions.nodes.count) discussions")
    }
    
    func testFetchDiscussionsPagination() async throws {
        guard useRealAPI else {
            print("⚠️ Skipping real API test - set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO to enable")
            return
        }
        
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated)
        
        // Test pagination by fetching small pages
        let firstPage = try await apiClient.fetchDiscussions(
            owner: settingsManager.settings.repositoryOwner,
            repository: settingsManager.settings.repositoryName,
            first: 2,
            after: nil
        )
        
        XCTAssertLessThanOrEqual(firstPage.data.repository.discussions.nodes.count, 2)
        
        // If there are more pages, test fetching the next page
        if firstPage.data.repository.discussions.pageInfo.hasNextPage,
           let endCursor = firstPage.data.repository.discussions.pageInfo.endCursor {
            
            let secondPage = try await apiClient.fetchDiscussions(
                owner: settingsManager.settings.repositoryOwner,
                repository: settingsManager.settings.repositoryName,
                first: 2,
                after: endCursor
            )
            
            XCTAssertLessThanOrEqual(secondPage.data.repository.discussions.nodes.count, 2)
            
            // Ensure we got different discussions
            if !firstPage.data.repository.discussions.nodes.isEmpty &&
               !secondPage.data.repository.discussions.nodes.isEmpty {
                let firstPageIds = Set(firstPage.data.repository.discussions.nodes.map { $0.id })
                let secondPageIds = Set(secondPage.data.repository.discussions.nodes.map { $0.id })
                XCTAssertTrue(firstPageIds.isDisjoint(with: secondPageIds), "Pages should contain different discussions")
            }
            
            print("✅ Successfully tested pagination")
        } else {
            print("ℹ️ Repository has insufficient discussions to test pagination")
        }
    }
    
    func testFetchDiscussionComments() async throws {
        guard useRealAPI else {
            print("⚠️ Skipping real API test - set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO to enable")
            return
        }
        
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated)
        
        // First, get a discussion to test comments on
        let discussionsResponse = try await apiClient.fetchDiscussions(
            owner: settingsManager.settings.repositoryOwner,
            repository: settingsManager.settings.repositoryName,
            first: 10,
            after: nil
        )
        
        guard let firstDiscussion = discussionsResponse.data.repository.discussions.nodes.first else {
            print("ℹ️ No discussions found to test comments on")
            return
        }
        
        // Test fetching comments for this discussion
        let commentsResponse = try await apiClient.fetchDiscussionComments(
            owner: settingsManager.settings.repositoryOwner,
            repository: settingsManager.settings.repositoryName,
            discussionNumber: firstDiscussion.number
        )
        
        // Verify response structure
        XCTAssertNotNil(commentsResponse.data.repository.discussion.comments)
        XCTAssertGreaterThanOrEqual(commentsResponse.data.repository.discussion.comments.totalCount, 0)
        
        // Verify comment data structure if comments exist
        if !commentsResponse.data.repository.discussion.comments.nodes.isEmpty {
            let firstComment = commentsResponse.data.repository.discussion.comments.nodes[0]
            XCTAssertFalse(firstComment.id.isEmpty)
            XCTAssertFalse(firstComment.body.isEmpty)
            XCTAssertNotNil(firstComment.author)
        }
        
        print("✅ Successfully fetched \(commentsResponse.data.repository.discussion.comments.nodes.count) comments")
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testAPIErrorHandling() async {
        // Test with intentionally invalid configuration
        settingsManager.settings.repositoryOwner = "invalid-user-name-12345"
        settingsManager.settings.repositoryName = "invalid-repo-name-12345"
        settingsManager.settings.personalAccessToken = "ghp_invalid_token"
        
        do {
            _ = try await apiClient.fetchDiscussions(
                owner: settingsManager.settings.repositoryOwner,
                repository: settingsManager.settings.repositoryName,
                first: 10,
                after: nil
            )
            XCTFail("Expected API call to fail with invalid configuration")
        } catch let error as APIError {
            // Verify we get appropriate API errors
            XCTAssertTrue([.unauthorized, .notFound, .invalidResponse].contains(error))
            print("✅ Correctly handled API error: \(error)")
        } catch {
            XCTFail("Expected APIError but got: \(error)")
        }
    }
    
    func testNetworkErrorHandling() async {
        // Test with invalid URL to simulate network errors
        settingsManager.settings.repositoryOwner = ""
        settingsManager.settings.repositoryName = ""
        
        do {
            _ = try await apiClient.fetchDiscussions(
                owner: settingsManager.settings.repositoryOwner,
                repository: settingsManager.settings.repositoryName,
                first: 10,
                after: nil
            )
            XCTFail("Expected API call to fail with invalid URL")
        } catch {
            // Should get some form of error
            XCTAssertTrue(error is APIError || error is URLError)
            print("✅ Correctly handled network error: \(error)")
        }
    }
    
    // MARK: - Rate Limiting Tests
    
    func testRateLimitHandling() async {
        guard useRealAPI else {
            print("⚠️ Skipping rate limit test - requires real API")
            return
        }
        
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated)
        
        // Make multiple rapid requests to test rate limiting behavior
        // Note: This test should be run sparingly to avoid actually hitting rate limits
        let requestCount = 5
        var responses: [DiscussionsResponse] = []
        var errors: [Error] = []
        
        for i in 0..<requestCount {
            do {
                let response = try await apiClient.fetchDiscussions(
                    owner: settingsManager.settings.repositoryOwner,
                    repository: settingsManager.settings.repositoryName,
                    first: 1,
                    after: nil
                )
                responses.append(response)
                print("Request \(i + 1): Success")
            } catch {
                errors.append(error)
                print("Request \(i + 1): Error - \(error)")
                
                // If we hit a rate limit, verify it's handled correctly
                if let apiError = error as? APIError, apiError == .rateLimited {
                    print("✅ Rate limit correctly detected and handled")
                    break
                }
            }
            
            // Small delay between requests
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // We should get at least some successful responses
        XCTAssertGreaterThan(responses.count, 0, "Should get at least some successful responses")
        
        print("✅ Completed rate limit test: \(responses.count) successes, \(errors.count) errors")
    }
    
    // MARK: - End-to-End Integration Test
    
    func testCompleteIntegrationFlow() async {
        guard useRealAPI else {
            print("⚠️ Skipping end-to-end test - set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO to enable")
            return
        }
        
        print("🚀 Starting end-to-end integration test...")
        
        // Step 1: Authentication
        print("Step 1: Testing authentication...")
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated, "Authentication must succeed")
        print("✅ Authentication successful")
        
        // Step 2: Fetch discussions
        print("Step 2: Fetching discussions...")
        let discussionsResponse = try? await apiClient.fetchDiscussions(
            owner: settingsManager.settings.repositoryOwner,
            repository: settingsManager.settings.repositoryName,
            first: 5,
            after: nil
        )
        XCTAssertNotNil(discussionsResponse, "Should successfully fetch discussions")
        print("✅ Fetched \(discussionsResponse?.data.repository.discussions.nodes.count ?? 0) discussions")
        
        // Step 3: Fetch comments for first discussion (if exists)
        if let firstDiscussion = discussionsResponse?.data.repository.discussions.nodes.first {
            print("Step 3: Fetching comments for discussion #\(firstDiscussion.number)...")
            let commentsResponse = try? await apiClient.fetchDiscussionComments(
                owner: settingsManager.settings.repositoryOwner,
                repository: settingsManager.settings.repositoryName,
                discussionNumber: firstDiscussion.number
            )
            XCTAssertNotNil(commentsResponse, "Should successfully fetch comments")
            print("✅ Fetched \(commentsResponse?.data.repository.discussion.comments.nodes.count ?? 0) comments")
        } else {
            print("ℹ️ No discussions found to test comment fetching")
        }
        
        // Step 4: Test error recovery
        print("Step 4: Testing error recovery...")
        let originalToken = settingsManager.settings.personalAccessToken
        settingsManager.settings.personalAccessToken = "invalid"
        
        await authService.validateToken()
        XCTAssertFalse(authService.isAuthenticated, "Should fail with invalid token")
        
        settingsManager.settings.personalAccessToken = originalToken
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated, "Should recover with valid token")
        print("✅ Error recovery successful")
        
        print("🎉 End-to-end integration test completed successfully!")
    }
    
    // MARK: - Performance Integration Tests
    
    func testAPIPerformance() async {
        guard useRealAPI else {
            print("⚠️ Skipping performance test - requires real API")
            return
        }
        
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated)
        
        // Measure API response time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await apiClient.fetchDiscussions(
                owner: settingsManager.settings.repositoryOwner,
                repository: settingsManager.settings.repositoryName,
                first: 10,
                after: nil
            )
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("⏱️ API response time: \(String(format: "%.2f", timeElapsed))s")
            
            // API should respond within reasonable time (adjust based on network conditions)
            XCTAssertLessThan(timeElapsed, 10.0, "API should respond within 10 seconds")
            
            if timeElapsed < 2.0 {
                print("✅ Excellent API performance (< 2s)")
            } else if timeElapsed < 5.0 {
                print("✅ Good API performance (< 5s)")
            } else {
                print("⚠️ Slow API performance (> 5s)")
            }
            
        } catch {
            XCTFail("Performance test failed: \(error)")
        }
    }
}

// MARK: - Test Configuration Helper

extension GitHubAPIIntegrationTests {
    
    /// Prints instructions for setting up real API testing
    func printTestSetupInstructions() {
        print("""
        
        📋 GitHub API Integration Test Setup:
        
        To run tests against real GitHub API:
        1. Create a GitHub Personal Access Token with permissions:
           - repo
           - read:discussion
           - write:discussion
        
        2. Set environment variables:
           export GITHUB_TEST_TOKEN="your_token_here"
           export GITHUB_TEST_REPO="owner/repository"
        
        3. Run tests:
           swift test --filter GitHubAPIIntegrationTests
        
        ⚠️ Note: These tests will make real API calls and count against your rate limit.
        Use a test repository to avoid affecting production data.
        
        """)
    }
}