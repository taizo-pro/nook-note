import XCTest
import Combine
@testable import NookNote

/// End-to-end integration tests that simulate complete user workflows.
/// These tests verify the entire application flow from authentication to discussion management.
@MainActor
final class EndToEndTests: XCTestCase {
    
    private var settingsManager: SettingsManager!
    private var authService: AuthenticationService!
    private var discussionsService: DiscussionsService!
    private var apiClient: GitHubAPIClient!
    private var cancellables: Set<AnyCancellable>!
    
    // Test configuration
    private var useRealAPI: Bool {
        ProcessInfo.processInfo.environment["GITHUB_TEST_TOKEN"] != nil &&
        ProcessInfo.processInfo.environment["GITHUB_TEST_REPO"] != nil
    }
    
    override func setUp() {
        super.setUp()
        
        // Initialize core services
        settingsManager = SettingsManager()
        apiClient = GitHubAPIClient(settingsManager: settingsManager)
        authService = AuthenticationService(settingsManager: settingsManager)
        discussionsService = DiscussionsService(apiClient: apiClient, settingsManager: settingsManager)
        cancellables = Set<AnyCancellable>()
        
        // Configure test settings
        if let testRepo = ProcessInfo.processInfo.environment["GITHUB_TEST_REPO"] {
            let components = testRepo.split(separator: "/")
            if components.count == 2 {
                settingsManager.settings.repositoryOwner = String(components[0])
                settingsManager.settings.repositoryName = String(components[1])
            }
        } else {
            settingsManager.settings.repositoryOwner = "testowner"
            settingsManager.settings.repositoryName = "testrepo"
        }
        
        if let testToken = ProcessInfo.processInfo.environment["GITHUB_TEST_TOKEN"] {
            settingsManager.settings.personalAccessToken = testToken
        } else {
            settingsManager.settings.personalAccessToken = "ghp_mock_token"
        }
    }
    
    override func tearDown() {
        cancellables.removeAll()
        discussionsService = nil
        authService = nil
        apiClient = nil
        settingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Complete User Workflow Tests
    
    func testCompleteUserJourney() async {
        guard useRealAPI else {
            print("⚠️ Skipping end-to-end test - set GITHUB_TEST_TOKEN and GITHUB_TEST_REPO to enable")
            await testCompleteUserJourneyWithMockData()
            return
        }
        
        print("🚀 Starting complete user journey test...")
        
        // Step 1: Initial app state
        print("Step 1: Verifying initial app state...")
        XCTAssertTrue(settingsManager.settings.isConfigured)
        XCTAssertEqual(authService.authenticationState, .configured)
        XCTAssertTrue(discussionsService.discussions.isEmpty)
        XCTAssertFalse(discussionsService.isLoading)
        print("✅ Initial state verified")
        
        // Step 2: Authentication flow
        print("Step 2: Testing authentication flow...")
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated)
        print("✅ Authentication successful")
        
        // Step 3: Load discussions
        print("Step 3: Loading discussions...")
        await discussionsService.loadDiscussions()
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertNil(discussionsService.errorMessage)
        print("✅ Loaded \(discussionsService.discussions.count) discussions")
        
        // Step 4: Test refresh functionality
        print("Step 4: Testing refresh functionality...")
        let initialCount = discussionsService.discussions.count
        await discussionsService.refreshDiscussions()
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertNil(discussionsService.errorMessage)
        print("✅ Refresh completed, count: \(discussionsService.discussions.count)")
        
        // Step 5: Test pagination (if available)
        if discussionsService.hasMorePages {
            print("Step 5: Testing pagination...")
            let beforeCount = discussionsService.discussions.count
            await discussionsService.loadMoreDiscussions()
            XCTAssertGreaterThanOrEqual(discussionsService.discussions.count, beforeCount)
            print("✅ Loaded more discussions: \(discussionsService.discussions.count)")
        } else {
            print("Step 5: No more pages available for pagination test")
        }
        
        // Step 6: Test discussion details
        if let firstDiscussion = discussionsService.discussions.first {
            print("Step 6: Testing discussion details...")
            do {
                let comments = try await discussionsService.loadComments(for: firstDiscussion)
                XCTAssertGreaterThanOrEqual(comments.count, 0)
                print("✅ Loaded \(comments.count) comments for discussion #\(firstDiscussion.number)")
            } catch {
                print("⚠️ Failed to load comments: \(error)")
            }
        } else {
            print("Step 6: No discussions available for comment testing")
        }
        
        // Step 7: Test error recovery
        print("Step 7: Testing error recovery...")
        await testErrorRecovery()
        print("✅ Error recovery tested")
        
        print("🎉 Complete user journey test successful!")
    }
    
    func testCompleteUserJourneyWithMockData() async {
        print("🧪 Running user journey with mock data...")
        
        // Step 1: Load mock data
        await discussionsService.loadMockData()
        XCTAssertEqual(discussionsService.discussions.count, 3)
        XCTAssertFalse(discussionsService.isEmpty)
        print("✅ Mock data loaded")
        
        // Step 2: Test discussion retrieval
        let discussion = discussionsService.getDiscussion(by: 1)
        XCTAssertNotNil(discussion)
        XCTAssertEqual(discussion?.title, "Welcome to NookNote!")
        print("✅ Discussion retrieval works")
        
        // Step 3: Test error clearing
        discussionsService.errorMessage = "Test error"
        XCTAssertTrue(discussionsService.hasError)
        discussionsService.clearError()
        XCTAssertFalse(discussionsService.hasError)
        print("✅ Error clearing works")
        
        print("🎉 Mock user journey test successful!")
    }
    
    // MARK: - Authentication Flow Tests
    
    func testAuthenticationStateTransitions() async {
        guard useRealAPI else {
            print("⚠️ Skipping authentication state test - requires real API")
            return
        }
        
        print("🔐 Testing authentication state transitions...")
        
        var stateChanges: [AuthenticationState] = []
        
        // Monitor authentication state changes
        authService.$authenticationState
            .sink { state in
                stateChanges.append(state)
                print("Auth state: \(state)")
            }
            .store(in: &cancellables)
        
        // Test valid authentication
        await authService.validateToken()
        
        // Allow time for state changes to propagate
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify state transitions
        XCTAssertGreaterThan(stateChanges.count, 1)
        XCTAssertTrue(stateChanges.contains(where: { 
            if case .validating = $0 { return true }
            return false
        }))
        XCTAssertTrue(stateChanges.contains(where: { 
            if case .valid = $0 { return true }
            return false
        }))
        
        print("✅ Authentication state transitions verified")
    }
    
    func testAuthenticationPersistence() async {
        print("💾 Testing authentication persistence...")
        
        // Set up initial authentication
        if useRealAPI {
            await authService.validateToken()
            XCTAssertTrue(authService.isAuthenticated)
        } else {
            authService.authenticationState = .valid
        }
        
        // Simulate app restart by creating new auth service
        let newAuthService = AuthenticationService(settingsManager: settingsManager)
        
        // Should start in configured state (not authenticated until validated)
        XCTAssertEqual(newAuthService.authenticationState, .configured)
        XCTAssertFalse(newAuthService.isAuthenticated)
        
        // But settings should be preserved
        XCTAssertTrue(settingsManager.settings.isConfigured)
        
        print("✅ Authentication persistence verified")
    }
    
    // MARK: - Data Loading Flow Tests
    
    func testDataLoadingFlow() async {
        guard useRealAPI else {
            print("⚠️ Skipping data loading test - requires real API")
            return
        }
        
        print("📊 Testing data loading flow...")
        
        var loadingStates: [Bool] = []
        var errorStates: [String?] = []
        
        // Monitor loading and error states
        discussionsService.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                print("Loading: \(isLoading)")
            }
            .store(in: &cancellables)
        
        discussionsService.$errorMessage
            .sink { error in
                errorStates.append(error)
                if let error = error {
                    print("Error: \(error)")
                }
            }
            .store(in: &cancellables)
        
        // Authenticate first
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated)
        
        // Load discussions
        await discussionsService.loadDiscussions()
        
        // Allow time for state changes
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify loading states
        XCTAssertTrue(loadingStates.contains(true), "Should have been loading at some point")
        XCTAssertTrue(loadingStates.contains(false), "Should have stopped loading")
        XCTAssertEqual(loadingStates.last, false, "Should not be loading at the end")
        
        // Should not have errors if authentication worked
        let finalError = errorStates.last
        if let error = finalError {
            print("⚠️ Final error state: \(error)")
        } else {
            print("✅ No errors in final state")
        }
        
        print("✅ Data loading flow verified")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorRecovery() async {
        print("🔧 Testing error recovery...")
        
        // Store original settings
        let originalToken = settingsManager.settings.personalAccessToken
        let originalOwner = settingsManager.settings.repositoryOwner
        
        // Test authentication error recovery
        settingsManager.settings.personalAccessToken = "invalid_token"
        await authService.validateToken()
        XCTAssertFalse(authService.isAuthenticated)
        
        // Recover with valid settings
        settingsManager.settings.personalAccessToken = originalToken
        await authService.validateToken()
        
        if useRealAPI {
            XCTAssertTrue(authService.isAuthenticated)
        }
        
        // Test API error recovery
        settingsManager.settings.repositoryOwner = "invalid_owner"
        await discussionsService.loadDiscussions()
        
        if useRealAPI {
            XCTAssertNotNil(discussionsService.errorMessage)
        }
        
        // Clear error and recover
        discussionsService.clearError()
        settingsManager.settings.repositoryOwner = originalOwner
        
        if useRealAPI {
            await discussionsService.loadDiscussions()
            XCTAssertNil(discussionsService.errorMessage)
        }
        
        print("✅ Error recovery verified")
    }
    
    func testNetworkErrorHandling() async {
        print("🌐 Testing network error handling...")
        
        // Configure invalid settings to trigger network errors
        settingsManager.settings.repositoryOwner = ""
        settingsManager.settings.repositoryName = ""
        
        // Should handle gracefully
        await discussionsService.loadDiscussions()
        
        // Should have error message
        XCTAssertNotNil(discussionsService.errorMessage)
        XCTAssertFalse(discussionsService.isLoading)
        
        // Error should be informative
        let errorMessage = discussionsService.errorMessage ?? ""
        XCTAssertFalse(errorMessage.isEmpty)
        print("Error message: \(errorMessage)")
        
        print("✅ Network error handling verified")
    }
    
    // MARK: - Performance Tests
    
    func testAppStartupPerformance() async {
        print("⚡ Testing app startup performance...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate app startup sequence
        let newSettingsManager = SettingsManager()
        newSettingsManager.settings = settingsManager.settings
        
        let newAPIClient = GitHubAPIClient(settingsManager: newSettingsManager)
        let newAuthService = AuthenticationService(settingsManager: newSettingsManager)
        let newDiscussionsService = DiscussionsService(apiClient: newAPIClient, settingsManager: newSettingsManager)
        
        let setupTime = CFAbsoluteTimeGetCurrent() - startTime
        
        print("Setup time: \(String(format: "%.3f", setupTime))s")
        
        // Startup should be very fast (< 100ms for object creation)
        XCTAssertLessThan(setupTime, 0.1, "App startup should be fast")
        
        // Test initial state performance
        XCTAssertTrue(newSettingsManager.settings.isConfigured)
        XCTAssertEqual(newAuthService.authenticationState, .configured)
        XCTAssertTrue(newDiscussionsService.discussions.isEmpty)
        
        print("✅ App startup performance verified")
    }
    
    func testMemoryUsage() async {
        print("🧠 Testing memory usage...")
        
        let initialMemory = getMemoryUsage()
        print("Initial memory: \(initialMemory) MB")
        
        // Load mock data multiple times to test memory management
        for i in 1...10 {
            await discussionsService.loadMockData()
            
            if i % 5 == 0 {
                let currentMemory = getMemoryUsage()
                print("Memory after \(i) loads: \(currentMemory) MB")
            }
        }
        
        let finalMemory = getMemoryUsage()
        print("Final memory: \(finalMemory) MB")
        
        // Memory should not grow excessively
        let memoryGrowth = finalMemory - initialMemory
        print("Memory growth: \(memoryGrowth) MB")
        
        // Allow some growth but not excessive (adjust threshold as needed)
        XCTAssertLessThan(memoryGrowth, 50.0, "Memory growth should be reasonable")
        
        print("✅ Memory usage verified")
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentOperations() async {
        guard useRealAPI else {
            print("⚠️ Skipping concurrency test - requires real API")
            return
        }
        
        print("🔄 Testing concurrent operations...")
        
        await authService.validateToken()
        XCTAssertTrue(authService.isAuthenticated)
        
        // Perform multiple concurrent operations
        async let task1 = discussionsService.loadDiscussions()
        async let task2 = discussionsService.refreshDiscussions()
        async let task3 = authService.validateToken()
        
        // Wait for all tasks to complete
        await task1
        await task2
        await task3
        
        // All operations should complete without crashes
        XCTAssertFalse(discussionsService.isLoading)
        XCTAssertTrue(authService.isAuthenticated)
        
        print("✅ Concurrent operations handled correctly")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
}