import Foundation
import Combine

enum AuthenticationState {
    case notConfigured
    case configured
    case validating
    case valid
    case invalid(Error)
}

enum AuthenticationError: LocalizedError {
    case invalidToken
    case networkError(Error)
    case invalidCredentials
    case insufficientPermissions
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid Personal Access Token"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidCredentials:
            return "Invalid credentials"
        case .insufficientPermissions:
            return "Token lacks required permissions (repo, read:discussion, write:discussion)"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later."
        }
    }
}

class AuthenticationService: ObservableObject {
    @Published var authenticationState: AuthenticationState = .notConfigured
    
    private let settingsManager: SettingsManager
    private let urlSession: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    init(settingsManager: SettingsManager, urlSession: URLSession = .shared) {
        self.settingsManager = settingsManager
        self.urlSession = urlSession
        
        // Monitor settings changes
        settingsManager.$settings
            .map { settings in
                settings.isConfigured ? .configured : .notConfigured
            }
            .assign(to: &$authenticationState)
    }
    
    // MARK: - Token Validation
    
    func validateToken() async {
        guard settingsManager.settings.isConfigured else {
            await MainActor.run {
                authenticationState = .notConfigured
            }
            return
        }
        
        await MainActor.run {
            authenticationState = .validating
        }
        
        do {
            let isValid = try await performTokenValidation()
            await MainActor.run {
                authenticationState = isValid ? .valid : .invalid(AuthenticationError.invalidCredentials)
            }
        } catch {
            await MainActor.run {
                authenticationState = .invalid(error)
            }
        }
    }
    
    private func performTokenValidation() async throws -> Bool {
        let settings = settingsManager.settings
        
        // Create validation request to GitHub API
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(settings.personalAccessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("NookNote/1.0", forHTTPHeaderField: "User-Agent")
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.networkError(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200:
            // Validate that the token has required scopes
            return try await validateTokenScopes()
        case 401:
            throw AuthenticationError.invalidToken
        case 403:
            throw AuthenticationError.rateLimited
        default:
            throw AuthenticationError.networkError(URLError(.badServerResponse))
        }
    }
    
    private func validateTokenScopes() async throws -> Bool {
        let settings = settingsManager.settings
        
        // Check if repository exists and is accessible
        let repoURL = URL(string: "https://api.github.com/repos/\(settings.repositoryOwner)/\(settings.repositoryName)")!
        var request = URLRequest(url: repoURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(settings.personalAccessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("NookNote/1.0", forHTTPHeaderField: "User-Agent")
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.networkError(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200:
            // Check discussions access
            return try await validateDiscussionsAccess()
        case 401:
            throw AuthenticationError.invalidToken
        case 403:
            throw AuthenticationError.insufficientPermissions
        case 404:
            throw AuthenticationError.networkError(URLError(.fileDoesNotExist))
        default:
            throw AuthenticationError.networkError(URLError(.badServerResponse))
        }
    }
    
    private func validateDiscussionsAccess() async throws -> Bool {
        let settings = settingsManager.settings
        
        // Test GraphQL query for discussions
        let query = """
        {
          repository(owner: "\(settings.repositoryOwner)", name: "\(settings.repositoryName)") {
            discussions(first: 1) {
              totalCount
            }
          }
        }
        """
        
        var request = URLRequest(url: URL(string: "https://api.github.com/graphql")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(settings.personalAccessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("NookNote/1.0", forHTTPHeaderField: "User-Agent")
        
        let requestBody = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticationError.networkError(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200:
            // Check if response contains errors
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
                throw AuthenticationError.insufficientPermissions
            }
            return true
        case 401:
            throw AuthenticationError.invalidToken
        case 403:
            throw AuthenticationError.insufficientPermissions
        default:
            throw AuthenticationError.networkError(URLError(.badServerResponse))
        }
    }
    
    // MARK: - Helper Methods
    
    var isAuthenticated: Bool {
        if case .valid = authenticationState {
            return true
        }
        return false
    }
    
    var authorizationHeader: String? {
        guard isAuthenticated else { return nil }
        return "Bearer \(settingsManager.settings.personalAccessToken)"
    }
    
    func reset() {
        authenticationState = settingsManager.settings.isConfigured ? .configured : .notConfigured
    }
}