import Foundation

struct Comment: Codable, Identifiable, Hashable {
    let id: String
    let body: String
    let author: User
    let createdAt: Date
    let updatedAt: Date
    let url: String
    let replyTo: String? // Parent comment ID for replies
    let isMinimized: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case body
        case author
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case url
        case replyTo = "reply_to"
        case isMinimized = "is_minimized"
    }
}

// MARK: - Comment Creation
struct CreateCommentInput: Codable {
    let discussionId: String
    let body: String
    let replyToId: String?
    
    enum CodingKeys: String, CodingKey {
        case discussionId = "discussion_id"
        case body
        case replyToId = "reply_to_id"
    }
}

// MARK: - GraphQL Response Types
struct CommentsResponse: Codable {
    let data: CommentsData
}

struct CommentsData: Codable {
    let repository: CommentRepository
}

struct CommentRepository: Codable {
    let discussion: DiscussionComments
}

struct DiscussionComments: Codable {
    let comments: CommentConnection
}

struct CommentConnection: Codable {
    let nodes: [Comment]
    let pageInfo: PageInfo
    let totalCount: Int
}

// MARK: - Comment Creation Response
struct CreateCommentResponse: Codable {
    let data: CreateCommentData?
    let errors: [GraphQLError]?
}

struct CreateCommentData: Codable {
    let addDiscussionComment: AddDiscussionCommentPayload
}

struct AddDiscussionCommentPayload: Codable {
    let comment: Comment
}

struct GraphQLError: Codable {
    let message: String
    let type: String?
    let path: [String]?
}