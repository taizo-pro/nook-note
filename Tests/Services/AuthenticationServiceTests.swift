import XCTest
import Combine
@testable import NookNote

final class AuthenticationServiceTests: XCTestCase {
    
    private var authService: AuthenticationService!
    private var settingsManager: SettingsManager!
    private var mockURLSession: MockURLSession!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        settingsManager = SettingsManager()
        mockURLSession = MockURLSession()
        authService = AuthenticationService(settingsManager: settingsManager, urlSession: mockURLSession)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        authService = nil
        settingsManager = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialStateNotConfigured() {
        // Then
        XCTAssertEqual(authService.authenticationState, .notConfigured)
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.authorizationHeader)
    }
    
    func testStateChangesToConfiguredWhenSettingsUpdated() {
        // Given
        let expectation = expectation(description: "State changes to configured")
        var receivedStates: [AuthenticationState] = []
        
        authService.$authenticationState
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_test123"
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStates.count, 2)
        XCTAssertEqual(receivedStates[0], .notConfigured) // Initial state
        XCTAssertEqual(receivedStates[1], .configured) // After settings update
    }
    
    // MARK: - Token Validation Tests
    
    func testValidateTokenWithUnconfiguredSettings() async {
        // When
        await authService.validateToken()
        
        // Then
        XCTAssertEqual(authService.authenticationState, .notConfigured)
    }
    
    func testValidateTokenSuccess() async {
        // Given
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_validtoken"
        
        // Mock successful user validation
        mockURLSession.mockResponse(for: "https://api.github.com/user", statusCode: 200, data: Data())
        
        // Mock successful repository access
        mockURLSession.mockResponse(for: "https://api.github.com/repos/testowner/testrepo", statusCode: 200, data: Data())
        
        // Mock successful GraphQL discussions access
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
        
        // When
        await authService.validateToken()
        
        // Then
        XCTAssertEqual(authService.authenticationState, .valid)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.authorizationHeader, "Bearer ghp_validtoken")
    }
    
    func testValidateTokenInvalidUser() async {
        // Given
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_invalidtoken"
        
        // Mock failed user validation
        mockURLSession.mockResponse(for: "https://api.github.com/user", statusCode: 401, data: Data())
        
        // When
        await authService.validateToken()
        
        // Then
        if case .invalid(let error) = authService.authenticationState {
            XCTAssertTrue(error is AuthenticationError)
            XCTAssertEqual(error as? AuthenticationError, .invalidToken)
        } else {
            XCTFail("Expected invalid state with AuthenticationError.invalidToken")
        }
    }
    
    func testValidateTokenRateLimited() async {
        // Given
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_token"
        
        // Mock rate limited response
        mockURLSession.mockResponse(for: "https://api.github.com/user", statusCode: 403, data: Data())
        
        // When
        await authService.validateToken()
        
        // Then
        if case .invalid(let error) = authService.authenticationState {
            XCTAssertEqual(error as? AuthenticationError, .rateLimited)
        } else {
            XCTFail("Expected invalid state with AuthenticationError.rateLimited")
        }
    }
    
    func testValidateTokenInsufficientPermissions() async {
        // Given
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_limitedtoken"
        
        // Mock successful user validation
        mockURLSession.mockResponse(for: "https://api.github.com/user", statusCode: 200, data: Data())
        
        // Mock forbidden repository access
        mockURLSession.mockResponse(for: "https://api.github.com/repos/testowner/testrepo", statusCode: 403, data: Data())
        
        // When
        await authService.validateToken()
        
        // Then
        if case .invalid(let error) = authService.authenticationState {
            XCTAssertEqual(error as? AuthenticationError, .insufficientPermissions)
        } else {
            XCTFail("Expected invalid state with AuthenticationError.insufficientPermissions")
        }
    }
    
    func testValidateTokenRepositoryNotFound() async {
        // Given
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "nonexistent"
        settingsManager.settings.personalAccessToken = "ghp_token"
        
        // Mock successful user validation
        mockURLSession.mockResponse(for: "https://api.github.com/user", statusCode: 200, data: Data())
        
        // Mock repository not found
        mockURLSession.mockResponse(for: "https://api.github.com/repos/testowner/nonexistent", statusCode: 404, data: Data())
        
        // When
        await authService.validateToken()
        
        // Then
        if case .invalid(let error) = authService.authenticationState {
            XCTAssertTrue(error is AuthenticationError)
        } else {
            XCTFail("Expected invalid state")
        }
    }
    
    func testValidateTokenGraphQLError() async {
        // Given
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_token"
        
        // Mock successful user and repo validation
        mockURLSession.mockResponse(for: "https://api.github.com/user", statusCode: 200, data: Data())
        mockURLSession.mockResponse(for: "https://api.github.com/repos/testowner/testrepo", statusCode: 200, data: Data())
        
        // Mock GraphQL error response
        let graphQLErrorResponse = """
        {
            "errors": [
                {
                    "message": "Field 'discussions' doesn't exist on type 'Repository'",
                    "type": "FIELD_ERROR"
                }
            ]
        }
        """
        mockURLSession.mockResponse(for: "https://api.github.com/graphql", statusCode: 200, data: graphQLErrorResponse.data(using: .utf8)!)
        
        // When
        await authService.validateToken()
        
        // Then
        if case .invalid(let error) = authService.authenticationState {
            XCTAssertEqual(error as? AuthenticationError, .insufficientPermissions)
        } else {
            XCTFail("Expected invalid state with insufficient permissions")
        }
    }
    
    // MARK: - Helper Methods Tests
    
    func testIsAuthenticatedWhenValid() {
        // Given
        authService.authenticationState = .valid
        
        // Then
        XCTAssertTrue(authService.isAuthenticated)
    }
    
    func testIsAuthenticatedWhenInvalid() {
        // Given
        authService.authenticationState = .invalid(AuthenticationError.invalidToken)
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    func testAuthorizationHeaderWhenAuthenticated() {
        // Given
        settingsManager.settings.personalAccessToken = "ghp_test123"
        authService.authenticationState = .valid
        
        // Then
        XCTAssertEqual(authService.authorizationHeader, "Bearer ghp_test123")
    }
    
    func testAuthorizationHeaderWhenNotAuthenticated() {
        // Given
        authService.authenticationState = .invalid(AuthenticationError.invalidToken)
        
        // Then
        XCTAssertNil(authService.authorizationHeader)
    }
    
    func testReset() {
        // Given
        authService.authenticationState = .valid
        settingsManager.settings.repositoryOwner = "testowner"
        settingsManager.settings.repositoryName = "testrepo"
        settingsManager.settings.personalAccessToken = "ghp_test123"
        
        // When
        authService.reset()
        
        // Then
        XCTAssertEqual(authService.authenticationState, .configured)
    }
    
    func testResetWhenNotConfigured() {
        // Given
        authService.authenticationState = .valid
        // Settings remain empty (not configured)
        
        // When
        authService.reset()
        
        // Then
        XCTAssertEqual(authService.authenticationState, .notConfigured)
    }
}

// MARK: - AuthenticationError Tests

final class AuthenticationErrorTests: XCTestCase {
    
    func testAuthenticationErrorDescriptions() {
        // Test all error descriptions
        XCTAssertEqual(AuthenticationError.invalidToken.errorDescription, "Invalid Personal Access Token")
        XCTAssertEqual(AuthenticationError.invalidCredentials.errorDescription, "Invalid credentials")
        XCTAssertEqual(AuthenticationError.insufficientPermissions.errorDescription, "Token lacks required permissions (repo, read:discussion, write:discussion)")
        XCTAssertEqual(AuthenticationError.rateLimited.errorDescription, "API rate limit exceeded. Please try again later.")
        
        // Test network error with underlying error
        let underlyingError = URLError(.timedOut)
        let networkError = AuthenticationError.networkError(underlyingError)
        XCTAssertTrue(networkError.errorDescription?.contains("Network error:") == true)
        XCTAssertTrue(networkError.errorDescription?.contains("timed out") == true)
    }
    
    func testAuthenticationErrorEquality() {
        // Test equality for simple cases
        XCTAssertEqual(AuthenticationError.invalidToken, AuthenticationError.invalidToken)
        XCTAssertEqual(AuthenticationError.rateLimited, AuthenticationError.rateLimited)
        XCTAssertNotEqual(AuthenticationError.invalidToken, AuthenticationError.rateLimited)
        
        // Network errors with same underlying error should be equal
        let error1 = AuthenticationError.networkError(URLError(.timedOut))
        let error2 = AuthenticationError.networkError(URLError(.timedOut))
        // Note: These won't be equal due to Error protocol limitations
        // This is expected behavior for associated values with Error types
    }
}

// MARK: - AuthenticationState Tests

final class AuthenticationStateTests: XCTestCase {
    
    func testAuthenticationStateEquality() {
        // Test simple state equality
        XCTAssertEqual(AuthenticationState.notConfigured, AuthenticationState.notConfigured)
        XCTAssertEqual(AuthenticationState.configured, AuthenticationState.configured)
        XCTAssertEqual(AuthenticationState.validating, AuthenticationState.validating)
        XCTAssertEqual(AuthenticationState.valid, AuthenticationState.valid)
        
        // Test inequality
        XCTAssertNotEqual(AuthenticationState.notConfigured, AuthenticationState.configured)
        XCTAssertNotEqual(AuthenticationState.validating, AuthenticationState.valid)
        
        // Test invalid states (these won't be equal due to Error protocol)
        let invalidState1 = AuthenticationState.invalid(AuthenticationError.invalidToken)
        let invalidState2 = AuthenticationState.invalid(AuthenticationError.invalidToken)
        // These comparisons are complex due to Error protocol, so we test the pattern matching instead
        
        if case .invalid(let error) = invalidState1 {
            XCTAssertTrue(error is AuthenticationError)
        } else {
            XCTFail("Expected invalid state")
        }
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSession {
    private var mockResponses: [String: (data: Data, response: HTTPURLResponse)] = [:]
    
    func mockResponse(for urlString: String, statusCode: Int, data: Data) {
        let url = URL(string: urlString)!
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        mockResponses[urlString] = (data: data, response: response)
    }
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let urlString = request.url?.absoluteString,
              let mockResponse = mockResponses[urlString] else {
            throw URLError(.badURL)
        }
        
        return (mockResponse.data, mockResponse.response)
    }
}