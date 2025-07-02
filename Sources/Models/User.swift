import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let login: String
    let avatarUrl: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case login
        case avatarUrl = "avatar_url"
        case url
    }
}