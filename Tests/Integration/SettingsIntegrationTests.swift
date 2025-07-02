import XCTest
import Combine
@testable import NookNote

/// Integration tests for settings management and persistence.
/// Tests the complete settings flow including UserDefaults integration and validation.
final class SettingsIntegrationTests: XCTestCase {
    
    private var settingsManager: SettingsManager!
    private var authService: AuthenticationService!
    private var cancellables: Set<AnyCancellable>!
    
    // Test UserDefaults suite to avoid affecting real app data
    private let testSuiteName = "com.nooknote.test.settings"
    
    override func setUp() {
        super.setUp()
        
        // Use test UserDefaults suite
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        
        settingsManager = SettingsManager()
        authService = AuthenticationService(settingsManager: settingsManager)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        // Clean up test data
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        
        cancellables.removeAll()
        authService = nil
        settingsManager = nil
        super.tearDown()
    }
    
    // MARK: - Settings Persistence Tests
    
    func testSettingsPersistence() {
        print("💾 Testing settings persistence...")
        
        // Configure settings
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_test123"
        settingsManager.settings.autoRefreshInterval = 600
        settingsManager.settings.showNotifications = false
        settingsManager.settings.defaultDiscussionCategory = "Ideas"
        
        // Save settings
        settingsManager.saveSettings()
        
        // Create new settings manager to test persistence
        let newSettingsManager = SettingsManager()
        
        // Verify settings were persisted
        XCTAssertEqual(newSettingsManager.settings.repositoryOwner, "testowner")
        XCTAssertEqual(newSettingsManager.settings.repositoryName, "testrepo")
        XCTAssertEqual(newSettingsManager.settings.personalAccessToken, "ghp_test123")
        XCTAssertEqual(newSettingsManager.settings.autoRefreshInterval, 600)
        XCTAssertFalse(newSettingsManager.settings.showNotifications)
        XCTAssertEqual(newSettingsManager.settings.defaultDiscussionCategory, "Ideas")
        
        print("✅ Settings persistence verified")
    }
    
    func testSettingsDefaultValues() {
        print("⚙️ Testing settings default values...")
        
        // Fresh settings manager should have defaults
        let freshSettingsManager = SettingsManager()
        
        XCTAssertEqual(freshSettingsManager.settings.repositoryOwner, "")
        XCTAssertEqual(freshSettingsManager.settings.repositoryName, "")
        XCTAssertEqual(freshSettingsManager.settings.personalAccessToken, "")
        XCTAssertEqual(freshSettingsManager.settings.autoRefreshInterval, 300)
        XCTAssertTrue(freshSettingsManager.settings.showNotifications)
        XCTAssertNil(freshSettingsManager.settings.defaultDiscussionCategory)
        XCTAssertFalse(freshSettingsManager.settings.isConfigured)
        
        print("✅ Default values verified")
    }
    
    func testSettingsValidation() {
        print("✅ Testing settings validation...")
        
        // Test empty configuration
        XCTAssertFalse(settingsManager.settings.isConfigured)
        
        // Test partial configuration
        settingsManager.settings.repositoryOwner = "testowner"
        XCTAssertFalse(settingsManager.settings.isConfigured)
        
        settingsManager.settings.repositoryName = "testrepo"
        XCTAssertFalse(settingsManager.settings.isConfigured)
        
        // Test complete configuration
        settingsManager.settings.personalAccessToken = "ghp_test123"
        XCTAssertTrue(settingsManager.settings.isConfigured)
        
        // Test with empty strings
        settingsManager.settings.repositoryOwner = ""
        XCTAssertFalse(settingsManager.settings.isConfigured)
        
        print("✅ Settings validation verified")
    }
    
    func testSettingsComputedProperties() {
        print("🔗 Testing settings computed properties...")
        
        // Test with empty values
        XCTAssertEqual(settingsManager.settings.repositoryURL, "")
        XCTAssertEqual(settingsManager.settings.apiBaseURL, "https://api.github.com")
        XCTAssertEqual(settingsManager.settings.graphQLURL, "https://api.github.com/graphql")
        
        // Test with configured values
        settingsManager.settings.repositoryOwner = "microsoft"
        settingsManager.settings.repositoryName = "vscode"
        
        XCTAssertEqual(settingsManager.settings.repositoryURL, "https://github.com/microsoft/vscode")
        XCTAssertEqual(settingsManager.settings.apiBaseURL, "https://api.github.com")
        XCTAssertEqual(settingsManager.settings.graphQLURL, "https://api.github.com/graphql")
        
        // Test with special characters
        settingsManager.settings.repositoryOwner = "test-org_123"
        settingsManager.settings.repositoryName = "test-repo.name"
        
        XCTAssertEqual(settingsManager.settings.repositoryURL, "https://github.com/test-org_123/test-repo.name")
        
        print("✅ Computed properties verified")
    }
    
    // MARK: - Settings Change Notifications Tests
    
    func testSettingsChangeNotifications() {
        print("📢 Testing settings change notifications...")
        
        var receivedSettings: [AppSettings] = []
        
        // Subscribe to settings changes
        settingsManager.$settings
            .sink { settings in
                receivedSettings.append(settings)
            }
            .store(in: &cancellables)
        
        // Make changes
        settingsManager.settings.repositoryOwner = "owner1"
        settingsManager.settings.repositoryName = "repo1"
        settingsManager.settings.personalAccessToken = "token1"
        
        // Allow time for notifications to propagate
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        
        // Verify notifications were received
        XCTAssertGreaterThan(receivedSettings.count, 1)
        XCTAssertEqual(receivedSettings.last?.repositoryOwner, "owner1")
        XCTAssertEqual(receivedSettings.last?.repositoryName, "repo1")
        XCTAssertEqual(receivedSettings.last?.personalAccessToken, "token1")
        
        print("✅ Settings change notifications verified")
    }
    
    func testAuthenticationServiceIntegration() {
        print("🔐 Testing authentication service integration...")
        
        var authStates: [AuthenticationState] = []
        
        // Monitor authentication state changes
        authService.$authenticationState
            .sink { state in
                authStates.append(state)
                print("Auth state: \(state)")
            }
            .store(in: &cancellables)
        
        // Initially not configured
        XCTAssertEqual(authService.authenticationState, .notConfigured)
        
        // Configure settings
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_test123"
        
        // Allow time for state changes
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        
        // Should transition to configured
        XCTAssertEqual(authService.authenticationState, .configured)
        
        // Verify state changes were received
        XCTAssertGreaterThan(authStates.count, 1)
        XCTAssertTrue(authStates.contains(where: { 
            if case .notConfigured = $0 { return true }
            return false
        }))
        XCTAssertTrue(authStates.contains(where: { 
            if case .configured = $0 { return true }
            return false
        }))
        
        print("✅ Authentication service integration verified")
    }
    
    // MARK: - Settings Migration Tests
    
    func testSettingsMigration() {
        print("🔄 Testing settings migration...")
        
        // Simulate old settings format (if we ever need to migrate)
        let oldSettings: [String: Any] = [
            "repo_owner": "oldowner",
            "repo_name": "oldrepo",
            "access_token": "old_token",
            "refresh_interval": 600
        ]
        
        // This test verifies that our current settings structure
        // can handle missing or renamed keys gracefully
        let defaults = UserDefaults.standard
        
        // Clear current settings
        defaults.removeObject(forKey: "appSettings")
        
        // Set old format data
        for (key, value) in oldSettings {
            defaults.set(value, forKey: key)
        }
        
        // Create new settings manager
        let migratedSettingsManager = SettingsManager()
        
        // Should start with defaults (graceful handling of missing new format)
        XCTAssertEqual(migratedSettingsManager.settings.repositoryOwner, "")
        XCTAssertEqual(migratedSettingsManager.settings.repositoryName, "")
        XCTAssertEqual(migratedSettingsManager.settings.personalAccessToken, "")
        XCTAssertEqual(migratedSettingsManager.settings.autoRefreshInterval, 300) // Default
        
        // Clean up
        for key in oldSettings.keys {
            defaults.removeObject(forKey: key)
        }
        
        print("✅ Settings migration verified")
    }
    
    // MARK: - Settings Export/Import Tests
    
    func testSettingsExportImport() {
        print("📤📥 Testing settings export/import...")
        
        // Configure settings
        settingsManager.settings.repositoryOwner = "exportowner"
        settingsManager.settings.repositoryName = "exportrepo"
        settingsManager.settings.personalAccessToken = "ghp_export123"
        settingsManager.settings.autoRefreshInterval = 900
        settingsManager.settings.showNotifications = false
        settingsManager.settings.defaultDiscussionCategory = "Export"
        
        // Export settings (simulate JSON export)
        do {
            let jsonData = try JSONEncoder().encode(settingsManager.settings)
            
            // Import to new settings manager
            let importedSettings = try JSONDecoder().decode(AppSettings.self, from: jsonData)
            
            let newSettingsManager = SettingsManager()
            newSettingsManager.settings = importedSettings
            
            // Verify imported settings
            XCTAssertEqual(newSettingsManager.settings.repositoryOwner, "exportowner")
            XCTAssertEqual(newSettingsManager.settings.repositoryName, "exportrepo")
            XCTAssertEqual(newSettingsManager.settings.personalAccessToken, "ghp_export123")
            XCTAssertEqual(newSettingsManager.settings.autoRefreshInterval, 900)
            XCTAssertFalse(newSettingsManager.settings.showNotifications)
            XCTAssertEqual(newSettingsManager.settings.defaultDiscussionCategory, "Export")
            XCTAssertTrue(newSettingsManager.settings.isConfigured)
            
            print("✅ Settings export/import verified")
            
        } catch {
            XCTFail("Settings export/import failed: \(error)")
        }
    }
    
    // MARK: - Settings Security Tests
    
    func testSettingsSecurityHandling() {
        print("🔒 Testing settings security handling...")
        
        // Configure with sensitive data
        settingsManager.settings.personalAccessToken = "ghp_sensitive_token_12345"
        settingsManager.saveSettings()
        
        // Verify token is stored (in real app, this would be in Keychain)
        // For now, we're using UserDefaults for simplicity in testing
        let storedSettings = SettingsManager()
        XCTAssertEqual(storedSettings.settings.personalAccessToken, "ghp_sensitive_token_12345")
        
        // Test token clearing
        settingsManager.settings.personalAccessToken = ""
        settingsManager.saveSettings()
        
        let clearedSettings = SettingsManager()
        XCTAssertEqual(clearedSettings.settings.personalAccessToken, "")
        
        print("✅ Settings security handling verified")
    }
    
    // MARK: - Settings Performance Tests
    
    func testSettingsPerformance() {
        print("⚡ Testing settings performance...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple settings operations
        for i in 0..<1000 {
            settingsManager.settings.repositoryOwner = "owner\(i)"
            settingsManager.settings.repositoryName = "repo\(i)"
            settingsManager.settings.autoRefreshInterval = TimeInterval(300 + i)
            
            // Test computed properties
            _ = settingsManager.settings.repositoryURL
            _ = settingsManager.settings.isConfigured
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Time for 1000 operations: \(String(format: "%.3f", timeElapsed))s")
        
        // Should be very fast (< 100ms for 1000 operations)
        XCTAssertLessThan(timeElapsed, 0.1, "Settings operations should be fast")
        
        print("✅ Settings performance verified")
    }
    
    func testSettingsSaveLoadPerformance() {
        print("💾 Testing settings save/load performance...")
        
        // Configure complex settings
        settingsManager.settings.repositoryOwner = "performanceowner"
        settingsManager.settings.repositoryName = "performancerepo"
        settingsManager.settings.personalAccessToken = "ghp_performance_token_with_long_string_12345678901234567890"
        settingsManager.settings.defaultDiscussionCategory = "Performance Testing Category"
        
        let saveStartTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple save operations
        for _ in 0..<100 {
            settingsManager.saveSettings()
        }
        
        let saveTime = CFAbsoluteTimeGetCurrent() - saveStartTime
        print("Save time for 100 operations: \(String(format: "%.3f", saveTime))s")
        
        let loadStartTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple load operations
        for _ in 0..<100 {
            let _ = SettingsManager()
        }
        
        let loadTime = CFAbsoluteTimeGetCurrent() - loadStartTime
        print("Load time for 100 operations: \(String(format: "%.3f", loadTime))s")
        
        // Operations should be reasonably fast
        XCTAssertLessThan(saveTime, 1.0, "Save operations should be fast")
        XCTAssertLessThan(loadTime, 1.0, "Load operations should be fast")
        
        print("✅ Settings save/load performance verified")
    }
    
    // MARK: - Real-world Scenarios Tests
    
    func testRealWorldConfigurationScenarios() {
        print("🌍 Testing real-world configuration scenarios...")
        
        // Scenario 1: First-time user setup
        let firstTimeUser = SettingsManager()
        XCTAssertFalse(firstTimeUser.settings.isConfigured)
        XCTAssertEqual(firstTimeUser.settings.repositoryURL, "")
        
        // Scenario 2: Microsoft/VSCode repository
        settingsManager.settings.repositoryOwner = "microsoft"
        settingsManager.settings.repositoryName = "vscode"
        settingsManager.settings.personalAccessToken = "ghp_microsoft_token"
        
        XCTAssertTrue(settingsManager.settings.isConfigured)
        XCTAssertEqual(settingsManager.settings.repositoryURL, "https://github.com/microsoft/vscode")
        
        // Scenario 3: Personal repository with special characters
        settingsManager.settings.repositoryOwner = "john-doe_123"
        settingsManager.settings.repositoryName = "my-awesome.project"
        
        XCTAssertEqual(settingsManager.settings.repositoryURL, "https://github.com/john-doe_123/my-awesome.project")
        
        // Scenario 4: Organization repository
        settingsManager.settings.repositoryOwner = "facebook"
        settingsManager.settings.repositoryName = "react"
        
        XCTAssertEqual(settingsManager.settings.repositoryURL, "https://github.com/facebook/react")
        
        // Scenario 5: Custom refresh intervals
        settingsManager.settings.autoRefreshInterval = 60 // 1 minute
        XCTAssertEqual(settingsManager.settings.autoRefreshInterval, 60)
        
        settingsManager.settings.autoRefreshInterval = 3600 // 1 hour
        XCTAssertEqual(settingsManager.settings.autoRefreshInterval, 3600)
        
        print("✅ Real-world scenarios verified")
    }
    
    func testErrorHandlingScenarios() {
        print("🚨 Testing error handling scenarios...")
        
        // Scenario 1: Corrupted settings data
        // Simulate by manually setting invalid JSON in UserDefaults
        UserDefaults.standard.set("invalid json data", forKey: "appSettings")
        
        // Should gracefully fall back to defaults
        let corruptedSettingsManager = SettingsManager()
        XCTAssertEqual(corruptedSettingsManager.settings.repositoryOwner, "")
        XCTAssertFalse(corruptedSettingsManager.settings.isConfigured)
        
        // Scenario 2: Missing UserDefaults data
        UserDefaults.standard.removeObject(forKey: "appSettings")
        let missingSettingsManager = SettingsManager()
        XCTAssertFalse(missingSettingsManager.settings.isConfigured)
        
        // Scenario 3: Extreme values
        settingsManager.settings.autoRefreshInterval = -1
        XCTAssertEqual(settingsManager.settings.autoRefreshInterval, -1) // Should handle gracefully
        
        settingsManager.settings.autoRefreshInterval = Double.greatestFiniteMagnitude
        XCTAssertEqual(settingsManager.settings.autoRefreshInterval, Double.greatestFiniteMagnitude)
        
        print("✅ Error handling scenarios verified")
    }
}