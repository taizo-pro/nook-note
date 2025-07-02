import XCTest
import Combine
@testable import NookNote

/// Performance tests for NookNote application.
/// These tests measure memory usage, startup time, API response times, and UI rendering performance.
@MainActor
final class PerformanceTests: XCTestCase {
    
    private var settingsManager: SettingsManager!
    private var apiClient: GitHubAPIClient!
    private var authService: AuthenticationService!
    private var discussionsService: DiscussionsService!
    private var notificationService: NotificationService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
        apiClient = GitHubAPIClient(settingsManager: settingsManager)
        authService = AuthenticationService(settingsManager: settingsManager)
        discussionsService = DiscussionsService(apiClient: apiClient, settingsManager: settingsManager)
        notificationService = NotificationService()
        cancellables = Set<AnyCancellable>()
        
        // Configure for testing
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_test123"
    }
    
    override func tearDown() {
        cancellables.removeAll()
        notificationService = nil
        discussionsService = nil
        authService = nil
        apiClient = nil
        settingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageBaseline() {
        print("🧠 Testing baseline memory usage...")
        
        let initialMemory = getMemoryUsage()
        print("Initial memory usage: \(String(format: "%.2f", initialMemory)) MB")
        
        // Baseline memory should be reasonable for a MenuBar app
        XCTAssertLessThan(initialMemory, 50.0, "Initial memory usage should be under 50MB")
        
        // Verify memory measurement is working
        XCTAssertGreaterThan(initialMemory, 0.0, "Memory measurement should return positive value")
        
        print("✅ Baseline memory usage: \(String(format: "%.2f", initialMemory)) MB")
    }
    
    func testMemoryUsageWithMockData() async {
        print("📊 Testing memory usage with mock data...")
        
        let beforeMemory = getMemoryUsage()
        
        // Load mock data multiple times
        for i in 1...10 {
            await discussionsService.loadMockData()
            
            if i % 5 == 0 {
                let currentMemory = getMemoryUsage()
                let growth = currentMemory - beforeMemory
                print("Memory after \(i) loads: \(String(format: "%.2f", currentMemory)) MB (growth: \(String(format: "%.2f", growth)) MB)")
            }
        }
        
        let finalMemory = getMemoryUsage()
        let totalGrowth = finalMemory - beforeMemory
        
        print("Final memory usage: \(String(format: "%.2f", finalMemory)) MB")
        print("Total memory growth: \(String(format: "%.2f", totalGrowth)) MB")
        
        // Memory growth should be reasonable
        XCTAssertLessThan(totalGrowth, 20.0, "Memory growth should be under 20MB for mock data")
        
        print("✅ Memory usage with mock data tested")
    }
    
    func testMemoryLeaks() async {
        print("🔍 Testing for memory leaks...")
        
        let initialMemory = getMemoryUsage()
        
        // Create and destroy objects repeatedly
        for i in 1...100 {
            // Create temporary objects
            let tempSettingsManager = SettingsManager()
            let tempAPIClient = GitHubAPIClient(settingsManager: tempSettingsManager)
            let tempAuthService = AuthenticationService(settingsManager: tempSettingsManager)
            let tempDiscussionsService = DiscussionsService(apiClient: tempAPIClient, settingsManager: tempSettingsManager)
            
            // Use the objects briefly
            tempSettingsManager.settings.repositoryOwner = "temp\(i)"
            _ = tempAuthService.isAuthenticated
            _ = tempDiscussionsService.isEmpty
            
            // Objects should be deallocated when they go out of scope
            // In Swift with ARC, this should happen automatically
            
            if i % 25 == 0 {
                let currentMemory = getMemoryUsage()
                let growth = currentMemory - initialMemory
                print("Memory after \(i) iterations: \(String(format: "%.2f", currentMemory)) MB (growth: \(String(format: "%.2f", growth)) MB)")
            }
        }
        
        // Force garbage collection (if available)
        // In Swift, we don't have direct control over GC, but ARC should handle deallocation
        
        let finalMemory = getMemoryUsage()
        let memoryGrowth = finalMemory - initialMemory
        
        print("Final memory after leak test: \(String(format: "%.2f", finalMemory)) MB")
        print("Memory growth: \(String(format: "%.2f", memoryGrowth)) MB")
        
        // Memory growth should be minimal if no leaks
        XCTAssertLessThan(memoryGrowth, 10.0, "Memory growth should be minimal - check for leaks")
        
        print("✅ Memory leak test completed")
    }
    
    func testLargeDataSetMemoryUsage() {
        print("📈 Testing memory usage with large data sets...")
        
        let beforeMemory = getMemoryUsage()
        
        // Create large data set
        let largeDataSet = createLargeDiscussionDataSet(count: 10000)
        
        let afterCreationMemory = getMemoryUsage()
        let creationGrowth = afterCreationMemory - beforeMemory
        
        print("Memory after creating 10,000 discussions: \(String(format: "%.2f", afterCreationMemory)) MB")
        print("Memory growth from data creation: \(String(format: "%.2f", creationGrowth)) MB")
        
        // Assign to discussions service
        discussionsService.discussions = largeDataSet
        
        let afterAssignmentMemory = getMemoryUsage()
        let totalGrowth = afterAssignmentMemory - beforeMemory
        
        print("Memory after assignment: \(String(format: "%.2f", afterAssignmentMemory)) MB")
        print("Total memory growth: \(String(format: "%.2f", totalGrowth)) MB")
        
        // Verify data was assigned
        XCTAssertEqual(discussionsService.discussions.count, 10000)
        
        // Memory usage should be proportional to data size but not excessive
        XCTAssertLessThan(totalGrowth, 100.0, "Large data set should not exceed 100MB growth")
        
        print("✅ Large data set memory usage tested")
    }
    
    // MARK: - Startup Performance Tests
    
    func testAppStartupTime() {
        print("🚀 Testing app startup time...")
        
        measure {
            // Measure time to create core app components
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Simulate app startup
            let settings = SettingsManager()
            let api = GitHubAPIClient(settingsManager: settings)
            let auth = AuthenticationService(settingsManager: settings)
            let discussions = DiscussionsService(apiClient: api, settingsManager: settings)
            let notifications = NotificationService()
            
            // Verify components are created
            XCTAssertNotNil(settings)
            XCTAssertNotNil(api)
            XCTAssertNotNil(auth)
            XCTAssertNotNil(discussions)
            XCTAssertNotNil(notifications)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let startupTime = endTime - startTime
            
            print("Startup time: \(String(format: "%.3f", startupTime * 1000)) ms")
        }
        
        print("✅ App startup time measured")
    }
    
    func testSettingsLoadTime() {
        print("⚙️ Testing settings load time...")
        
        // First, save some settings
        settingsManager.settings.repositoryOwner = "performance-test-owner"
        settingsManager.settings.repositoryName = "performance-test-repo"
        settingsManager.settings.personalAccessToken = "ghp_performance_test_token_12345"
        settingsManager.settings.autoRefreshInterval = 600
        settingsManager.settings.showNotifications = false
        settingsManager.settings.defaultDiscussionCategory = "Performance"
        
        settingsManager.saveSettings()
        
        measure {
            // Measure settings load time
            let loadStartTime = CFAbsoluteTimeGetCurrent()
            
            let _ = SettingsManager()
            
            let loadEndTime = CFAbsoluteTimeGetCurrent()
            let loadTime = loadEndTime - loadStartTime
            
            print("Settings load time: \(String(format: "%.3f", loadTime * 1000)) ms")
        }
        
        print("✅ Settings load time measured")
    }
    
    func testFirstTimeAppLaunch() {
        print("🆕 Testing first-time app launch performance...")
        
        // Clear any existing settings to simulate first launch
        UserDefaults.standard.removeObject(forKey: "appSettings")
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Simulate first-time app launch
            let settings = SettingsManager()
            let auth = AuthenticationService(settingsManager: settings)
            
            // Verify initial state
            XCTAssertFalse(settings.settings.isConfigured)
            XCTAssertEqual(auth.authenticationState, .notConfigured)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let launchTime = endTime - startTime
            
            print("First launch time: \(String(format: "%.3f", launchTime * 1000)) ms")
        }
        
        print("✅ First-time app launch performance measured")
    }
    
    // MARK: - API Performance Tests
    
    func testMockAPIResponseTime() async {
        print("🌐 Testing mock API response time...")
        
        // Use mock API client for consistent performance testing
        let mockAPIClient = MockGitHubAPIClient()
        let mockDiscussionsService = DiscussionsService(apiClient: mockAPIClient, settingsManager: settingsManager)
        
        // Set up mock response
        let mockResponse = createMockDiscussionsResponse()
        mockAPIClient.mockFetchDiscussionsResponse = mockResponse
        
        await measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            await mockDiscussionsService.loadDiscussions()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let responseTime = endTime - startTime
            
            print("Mock API response time: \(String(format: "%.3f", responseTime * 1000)) ms")
        }
        
        print("✅ Mock API response time measured")
    }
    
    func testAuthenticationPerformance() async {
        print("🔐 Testing authentication performance...")
        
        // Use mock URL session for consistent testing
        let mockURLSession = MockURLSession()
        let mockAuthService = AuthenticationService(settingsManager: settingsManager, urlSession: mockURLSession)
        
        // Mock successful responses
        mockURLSession.mockResponse(for: "https://api.github.com/user", statusCode: 200, data: Data())
        mockURLSession.mockResponse(for: "https://api.github.com/repos/testowner/testrepo", statusCode: 200, data: Data())
        
        let graphQLResponse = """
        {
            "data": {
                "repository": {
                    "discussions": {
                        "totalCount": 5
                    }
                }
            }
        }
        """
        mockURLSession.mockResponse(for: "https://api.github.com/graphql", statusCode: 200, data: graphQLResponse.data(using: .utf8)!)
        
        await measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            await mockAuthService.validateToken()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let authTime = endTime - startTime
            
            print("Authentication time: \(String(format: "%.3f", authTime * 1000)) ms")
        }
        
        print("✅ Authentication performance measured")
    }
    
    // MARK: - UI Performance Tests
    
    func testViewCreationPerformance() {
        print("🖼️ Testing view creation performance...")
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Create main views
            let contentView = ContentView()
            let settingsView = SettingsView(settingsManager: settingsManager)
            let discussionsListView = DiscussionsListView(settingsManager: settingsManager) { _ in }
            let newPostView = NewPostView(settingsManager: settingsManager)
            
            // Verify views are created
            _ = contentView
            _ = settingsView
            _ = discussionsListView
            _ = newPostView
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let creationTime = endTime - startTime
            
            print("View creation time: \(String(format: "%.3f", creationTime * 1000)) ms")
        }
        
        print("✅ View creation performance measured")
    }
    
    func testLargeListRenderingPerformance() {
        print("📋 Testing large list rendering performance...")
        
        // Create large data set
        let largeDataSet = createLargeDiscussionDataSet(count: 1000)
        discussionsService.discussions = largeDataSet
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Create discussions list view with large data set
            let discussionsListView = DiscussionsListView(settingsManager: settingsManager) { _ in }
            
            // In a real rendering test, we would measure actual rendering time
            // For now, we measure view creation time with large data
            _ = discussionsListView
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let renderTime = endTime - startTime
            
            print("Large list creation time: \(String(format: "%.3f", renderTime * 1000)) ms")
        }
        
        // Verify large data set is available
        XCTAssertEqual(discussionsService.discussions.count, 1000)
        
        print("✅ Large list rendering performance measured")
    }
    
    // MARK: - Data Processing Performance Tests
    
    func testJSONParsingPerformance() {
        print("🔄 Testing JSON parsing performance...")
        
        // Create large JSON data
        let largeJSONData = createLargeJSONData()
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let _ = try decoder.decode(DiscussionsResponse.self, from: largeJSONData)
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let parseTime = endTime - startTime
                
                print("JSON parsing time: \(String(format: "%.3f", parseTime * 1000)) ms")
            } catch {
                XCTFail("JSON parsing failed: \(error)")
            }
        }
        
        print("✅ JSON parsing performance measured")
    }
    
    func testDataFilteringPerformance() {
        print("🔍 Testing data filtering performance...")
        
        // Create large data set
        let largeDataSet = createLargeDiscussionDataSet(count: 10000)
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Perform various filtering operations
            let openDiscussions = largeDataSet.filter { $0.state == .open }
            let recentDiscussions = largeDataSet.filter { $0.createdAt > Date().addingTimeInterval(-86400) }
            let discussionsWithComments = largeDataSet.filter { $0.commentsCount > 0 }
            let titleSearch = largeDataSet.filter { $0.title.lowercased().contains("test") }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let filterTime = endTime - startTime
            
            print("Data filtering time: \(String(format: "%.3f", filterTime * 1000)) ms")
            print("Results: \(openDiscussions.count) open, \(recentDiscussions.count) recent, \(discussionsWithComments.count) with comments, \(titleSearch.count) matching search")
        }
        
        print("✅ Data filtering performance measured")
    }
    
    func testDataSortingPerformance() {
        print("📊 Testing data sorting performance...")
        
        // Create large unsorted data set
        var largeDataSet = createLargeDiscussionDataSet(count: 5000)
        
        measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Perform various sorting operations
            let sortedByDate = largeDataSet.sorted { $0.createdAt > $1.createdAt }
            let sortedByTitle = largeDataSet.sorted { $0.title < $1.title }
            let sortedByComments = largeDataSet.sorted { $0.commentsCount > $1.commentsCount }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let sortTime = endTime - startTime
            
            print("Data sorting time: \(String(format: "%.3f", sortTime * 1000)) ms")
            
            // Verify sorting worked
            XCTAssertEqual(sortedByDate.count, largeDataSet.count)
            XCTAssertEqual(sortedByTitle.count, largeDataSet.count)
            XCTAssertEqual(sortedByComments.count, largeDataSet.count)
        }
        
        print("✅ Data sorting performance measured")
    }
    
    // MARK: - Concurrency Performance Tests
    
    func testConcurrentOperations() async {
        print("🔄 Testing concurrent operations performance...")
        
        await measure {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Perform multiple concurrent operations
            async let task1 = discussionsService.loadMockData()
            async let task2 = authService.validateToken()
            async let task3 = settingsManager.saveSettings()
            
            // Wait for all tasks to complete
            await task1
            await task2
            await task3
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let concurrentTime = endTime - startTime
            
            print("Concurrent operations time: \(String(format: "%.3f", concurrentTime * 1000)) ms")
        }
        
        print("✅ Concurrent operations performance measured")
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
    
    private func createLargeDiscussionDataSet(count: Int) -> [Discussion] {
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
        
        return (1...count).map { i in
            Discussion(
                id: "discussion_\(i)",
                number: i,
                title: "Performance Test Discussion \(i)",
                body: "This is a performance test discussion with body content for item \(i). It contains some text to simulate real discussion content.",
                author: mockUser,
                category: mockCategory,
                createdAt: Date().addingTimeInterval(-Double(i * 60)),
                updatedAt: Date().addingTimeInterval(-Double(i * 30)),
                url: "https://github.com/test/repo/discussions/\(i)",
                comments: CommentCount(totalCount: i % 10),
                locked: i % 100 == 0,
                state: i % 10 == 0 ? .closed : .open
            )
        }
    }
    
    private func createMockDiscussionsResponse() -> DiscussionsResponse {
        let mockDiscussions = createLargeDiscussionDataSet(count: 20)
        
        return DiscussionsResponse(
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
    }
    
    private func createLargeJSONData() -> Data {
        // Create a large JSON structure for parsing performance tests
        let mockDiscussions = createLargeDiscussionDataSet(count: 100)
        let response = createMockDiscussionsResponse()
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(response)
        } catch {
            XCTFail("Failed to create large JSON data: \(error)")
            return Data()
        }
    }
    
    @MainActor
    private func measure(_ block: () async -> Void) async {
        // Custom async measure method
        let startTime = CFAbsoluteTimeGetCurrent()
        await block()
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        print("Measured time: \(String(format: "%.3f", timeElapsed * 1000)) ms")
    }
}