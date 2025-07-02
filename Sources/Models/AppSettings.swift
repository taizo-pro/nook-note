import Foundation

struct AppSettings: Codable {
    var repositoryOwner: String = ""
    var repositoryName: String = ""
    var personalAccessToken: String = ""
    var autoRefreshInterval: TimeInterval = 300 // 5 minutes
    var showNotifications: Bool = true
    var defaultDiscussionCategory: String?
    
    var isConfigured: Bool {
        !repositoryOwner.isEmpty && 
        !repositoryName.isEmpty && 
        !personalAccessToken.isEmpty
    }
    
    var repositoryURL: String {
        guard !repositoryOwner.isEmpty && !repositoryName.isEmpty else {
            return ""
        }
        return "https://github.com/\(repositoryOwner)/\(repositoryName)"
    }
    
    var apiBaseURL: String {
        return "https://api.github.com"
    }
    
    var graphQLURL: String {
        return "https://api.github.com/graphql"
    }
}