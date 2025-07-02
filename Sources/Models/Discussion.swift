import Foundation

struct Discussion: Codable, Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    let body: String?
    let author: User
    let category: DiscussionCategory
    let createdAt: Date
    let updatedAt: Date
    let url: String
    let comments: CommentCount
    let locked: Bool
    let state: DiscussionState
    
    var commentsCount: Int {
        return comments.totalCount
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case number
        case title
        case body
        case author
        case category
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case url
        case comments
        case locked
        case state
    }
}

struct CommentCount: Codable, Hashable {
    let totalCount: Int
}

struct DiscussionCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let description: String?
}

enum DiscussionState: String, Codable, CaseIterable {
    case open = "OPEN"
    case closed = "CLOSED"
    case locked = "LOCKED"
}

// MARK: - GraphQL Response Types
struct DiscussionsResponse: Codable {
    let data: DiscussionsData
}

struct DiscussionsData: Codable {
    let repository: Repository
}

struct Repository: Codable {
    let discussions: DiscussionConnection
}

struct DiscussionConnection: Codable {
    let nodes: [Discussion]
    let pageInfo: PageInfo
    let totalCount: Int
}

struct PageInfo: Codable {
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    let startCursor: String?
    let endCursor: String?
}