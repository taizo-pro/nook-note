import XCTest
@testable import NookNote

final class AppSettingsTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testAppSettingsDefaultInitialization() {
        // When
        let settings = AppSettings()
        
        // Then
        XCTAssertEqual(settings.repositoryOwner, "")
        XCTAssertEqual(settings.repositoryName, "")
        XCTAssertEqual(settings.personalAccessToken, "")
        XCTAssertEqual(settings.autoRefreshInterval, 300)
        XCTAssertTrue(settings.showNotifications)
        XCTAssertNil(settings.defaultDiscussionCategory)
    }
    
    func testAppSettingsCustomInitialization() {
        // Given
        var settings = AppSettings()
        
        // When
        settings.repositoryOwner = "testowner"
        settings.repositoryName = "testrepo"
        settings.personalAccessToken = "ghp_test123"
        settings.autoRefreshInterval = 600
        settings.showNotifications = false
        settings.defaultDiscussionCategory = "General"
        
        // Then
        XCTAssertEqual(settings.repositoryOwner, "testowner")
        XCTAssertEqual(settings.repositoryName, "testrepo")
        XCTAssertEqual(settings.personalAccessToken, "ghp_test123")
        XCTAssertEqual(settings.autoRefreshInterval, 600)
        XCTAssertFalse(settings.showNotifications)
        XCTAssertEqual(settings.defaultDiscussionCategory, "General")
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsConfiguredWhenEmpty() {
        // Given
        let settings = AppSettings()
        
        // Then
        XCTAssertFalse(settings.isConfigured)
    }
    
    func testIsConfiguredWhenPartiallyFilled() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "testowner"
        settings.repositoryName = "testrepo"
        // personalAccessToken is still empty
        
        // Then
        XCTAssertFalse(settings.isConfigured)
    }
    
    func testIsConfiguredWhenFullyFilled() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "testowner"
        settings.repositoryName = "testrepo"
        settings.personalAccessToken = "ghp_test123"
        
        // Then
        XCTAssertTrue(settings.isConfigured)
    }
    
    func testIsConfiguredWithEmptyStrings() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "testowner"
        settings.repositoryName = ""
        settings.personalAccessToken = "ghp_test123"
        
        // Then
        XCTAssertFalse(settings.isConfigured)
    }
    
    func testRepositoryURLWhenEmpty() {
        // Given
        let settings = AppSettings()
        
        // Then
        XCTAssertEqual(settings.repositoryURL, "")
    }
    
    func testRepositoryURLWhenPartiallyFilled() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "testowner"
        // repositoryName is still empty
        
        // Then
        XCTAssertEqual(settings.repositoryURL, "")
    }
    
    func testRepositoryURLWhenFullyFilled() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "testowner"
        settings.repositoryName = "testrepo"
        
        // Then
        XCTAssertEqual(settings.repositoryURL, "https://github.com/testowner/testrepo")
    }
    
    func testRepositoryURLWithSpecialCharacters() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "test-owner_123"
        settings.repositoryName = "test-repo.name"
        
        // Then
        XCTAssertEqual(settings.repositoryURL, "https://github.com/test-owner_123/test-repo.name")
    }
    
    func testAPIBaseURL() {
        // Given
        let settings = AppSettings()
        
        // Then
        XCTAssertEqual(settings.apiBaseURL, "https://api.github.com")
    }
    
    func testGraphQLURL() {
        // Given
        let settings = AppSettings()
        
        // Then
        XCTAssertEqual(settings.graphQLURL, "https://api.github.com/graphql")
    }
    
    // MARK: - Codable Tests
    
    func testAppSettingsJSONEncoding() throws {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "testowner"
        settings.repositoryName = "testrepo"
        settings.personalAccessToken = "ghp_test123"
        settings.autoRefreshInterval = 600
        settings.showNotifications = false
        settings.defaultDiscussionCategory = "General"
        
        // When
        let jsonData = try JSONEncoder().encode(settings)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("testowner") == true)
        XCTAssertTrue(jsonString?.contains("testrepo") == true)
        XCTAssertTrue(jsonString?.contains("ghp_test123") == true)
        XCTAssertTrue(jsonString?.contains("600") == true)
        XCTAssertTrue(jsonString?.contains("General") == true)
    }
    
    func testAppSettingsJSONDecoding() throws {
        // Given
        let jsonString = """
        {
            "repositoryOwner": "testowner",
            "repositoryName": "testrepo",
            "personalAccessToken": "ghp_test123",
            "autoRefreshInterval": 600,
            "showNotifications": false,
            "defaultDiscussionCategory": "General"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let settings = try JSONDecoder().decode(AppSettings.self, from: jsonData)
        
        // Then
        XCTAssertEqual(settings.repositoryOwner, "testowner")
        XCTAssertEqual(settings.repositoryName, "testrepo")
        XCTAssertEqual(settings.personalAccessToken, "ghp_test123")
        XCTAssertEqual(settings.autoRefreshInterval, 600)
        XCTAssertFalse(settings.showNotifications)
        XCTAssertEqual(settings.defaultDiscussionCategory, "General")
    }
    
    func testAppSettingsJSONDecodingWithDefaults() throws {
        // Given - minimal JSON with only required fields
        let jsonString = """
        {
            "repositoryOwner": "testowner",
            "repositoryName": "testrepo",
            "personalAccessToken": "ghp_test123"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let settings = try JSONDecoder().decode(AppSettings.self, from: jsonData)
        
        // Then
        XCTAssertEqual(settings.repositoryOwner, "testowner")
        XCTAssertEqual(settings.repositoryName, "testrepo")
        XCTAssertEqual(settings.personalAccessToken, "ghp_test123")
        XCTAssertEqual(settings.autoRefreshInterval, 300) // Default value
        XCTAssertTrue(settings.showNotifications) // Default value
        XCTAssertNil(settings.defaultDiscussionCategory) // Default value
    }
    
    func testAppSettingsJSONDecodingWithNullCategory() throws {
        // Given
        let jsonString = """
        {
            "repositoryOwner": "testowner",
            "repositoryName": "testrepo",
            "personalAccessToken": "ghp_test123",
            "autoRefreshInterval": 300,
            "showNotifications": true,
            "defaultDiscussionCategory": null
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let settings = try JSONDecoder().decode(AppSettings.self, from: jsonData)
        
        // Then
        XCTAssertNil(settings.defaultDiscussionCategory)
    }
    
    // MARK: - Edge Cases Tests
    
    func testAppSettingsWithEmptyToken() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "testowner"
        settings.repositoryName = "testrepo"
        settings.personalAccessToken = ""
        
        // Then
        XCTAssertFalse(settings.isConfigured)
        XCTAssertEqual(settings.repositoryURL, "https://github.com/testowner/testrepo")
    }
    
    func testAppSettingsWithWhitespaceToken() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "testowner"
        settings.repositoryName = "testrepo"
        settings.personalAccessToken = "   "
        
        // Then
        // Note: Current implementation only checks for empty string, not whitespace
        XCTAssertTrue(settings.isConfigured)
    }
    
    func testAppSettingsWithZeroRefreshInterval() {
        // Given
        var settings = AppSettings()
        settings.autoRefreshInterval = 0
        
        // Then
        XCTAssertEqual(settings.autoRefreshInterval, 0)
    }
    
    func testAppSettingsWithNegativeRefreshInterval() {
        // Given
        var settings = AppSettings()
        settings.autoRefreshInterval = -100
        
        // Then
        XCTAssertEqual(settings.autoRefreshInterval, -100)
    }
    
    func testAppSettingsWithLargeRefreshInterval() {
        // Given
        var settings = AppSettings()
        settings.autoRefreshInterval = 86400 // 24 hours
        
        // Then
        XCTAssertEqual(settings.autoRefreshInterval, 86400)
    }
    
    // MARK: - Real-world Scenarios Tests
    
    func testTypicalGitHubConfiguration() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "microsoft"
        settings.repositoryName = "vscode"
        settings.personalAccessToken = "ghp_1234567890abcdef1234567890abcdef12345678"
        settings.autoRefreshInterval = 300
        settings.showNotifications = true
        settings.defaultDiscussionCategory = "Ideas"
        
        // Then
        XCTAssertTrue(settings.isConfigured)
        XCTAssertEqual(settings.repositoryURL, "https://github.com/microsoft/vscode")
        XCTAssertEqual(settings.apiBaseURL, "https://api.github.com")
        XCTAssertEqual(settings.graphQLURL, "https://api.github.com/graphql")
    }
    
    func testOrganizationRepository() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "facebook"
        settings.repositoryName = "react"
        settings.personalAccessToken = "ghp_test"
        
        // Then
        XCTAssertTrue(settings.isConfigured)
        XCTAssertEqual(settings.repositoryURL, "https://github.com/facebook/react")
    }
    
    func testPersonalRepository() {
        // Given
        var settings = AppSettings()
        settings.repositoryOwner = "johndoe"
        settings.repositoryName = "my-awesome-project"
        settings.personalAccessToken = "ghp_test"
        
        // Then
        XCTAssertTrue(settings.isConfigured)
        XCTAssertEqual(settings.repositoryURL, "https://github.com/johndoe/my-awesome-project")
    }
}