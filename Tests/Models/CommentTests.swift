import XCTest
@testable import NookNote

final class CommentTests: XCTestCase {
    
    // MARK: - Test Data
    
    private var testUser: User {
        User(
            id: "user123",
            login: "testuser",
            avatarUrl: "https://github.com/testuser.png",
            url: "https://github.com/testuser"
        )
    }
    
    private var testDate: Date {
        Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
    }
    
    // MARK: - Initialization Tests
    
    func testCommentInitialization() {
        // Given
        let id = "comment123"
        let body = "This is a test comment"
        let url = "https://github.com/owner/repo/discussions/1#comment-123"
        let replyTo = "comment456"
        let isMinimized = false
        
        // When
        let comment = Comment(
            id: id,
            body: body,
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: url,
            replyTo: replyTo,
            isMinimized: isMinimized
        )
        
        // Then
        XCTAssertEqual(comment.id, id)
        XCTAssertEqual(comment.body, body)
        XCTAssertEqual(comment.author, testUser)
        XCTAssertEqual(comment.createdAt, testDate)
        XCTAssertEqual(comment.updatedAt, testDate)
        XCTAssertEqual(comment.url, url)
        XCTAssertEqual(comment.replyTo, replyTo)
        XCTAssertEqual(comment.isMinimized, isMinimized)
    }
    
    func testCommentWithNilReplyTo() {
        // Given
        let comment = Comment(
            id: "comment123",
            body: "Top-level comment",
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            replyTo: nil,
            isMinimized: false
        )
        
        // Then
        XCTAssertNil(comment.replyTo)
    }
    
    // MARK: - Codable Tests
    
    func testCommentJSONEncoding() throws {
        // Given
        let comment = Comment(
            id: "comment123",
            body: "Test comment body",
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: "https://github.com/test/repo/discussions/1#comment-123",
            replyTo: "comment456",
            isMinimized: false
        )
        
        // When
        let jsonData = try JSONEncoder().encode(comment)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("Test comment body") == true)
        XCTAssertTrue(jsonString?.contains("comment123") == true)
        XCTAssertTrue(jsonString?.contains("testuser") == true)
    }
    
    func testCommentJSONDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "comment123",
            "body": "Test comment body",
            "author": {
                "id": "user123",
                "login": "testuser",
                "avatarUrl": "https://github.com/testuser.png",
                "url": "https://github.com/testuser"
            },
            "created_at": "2022-01-01T00:00:00Z",
            "updated_at": "2022-01-01T00:00:00Z",
            "url": "https://github.com/test/repo/discussions/1#comment-123",
            "reply_to": "comment456",
            "is_minimized": false
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // When
        let comment = try decoder.decode(Comment.self, from: jsonData)
        
        // Then
        XCTAssertEqual(comment.id, "comment123")
        XCTAssertEqual(comment.body, "Test comment body")
        XCTAssertEqual(comment.author.login, "testuser")
        XCTAssertEqual(comment.url, "https://github.com/test/repo/discussions/1#comment-123")
        XCTAssertEqual(comment.replyTo, "comment456")
        XCTAssertEqual(comment.isMinimized, false)
    }
    
    func testCommentJSONDecodingWithNilReplyTo() throws {
        // Given
        let jsonString = """
        {
            "id": "comment123",
            "body": "Top-level comment",
            "author": {
                "id": "user123",
                "login": "testuser",
                "avatarUrl": "https://github.com/testuser.png",
                "url": "https://github.com/testuser"
            },
            "created_at": "2022-01-01T00:00:00Z",
            "updated_at": "2022-01-01T00:00:00Z",
            "url": "https://github.com/test/repo/discussions/1#comment-123",
            "reply_to": null,
            "is_minimized": false
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // When
        let comment = try decoder.decode(Comment.self, from: jsonData)
        
        // Then
        XCTAssertNil(comment.replyTo)
    }
    
    // MARK: - Equatable Tests
    
    func testCommentEquality() {
        // Given
        let comment1 = Comment(
            id: "comment123",
            body: "Test body",
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            replyTo: nil,
            isMinimized: false
        )
        
        let comment2 = Comment(
            id: "comment123",
            body: "Test body",
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            replyTo: nil,
            isMinimized: false
        )
        
        let comment3 = Comment(
            id: "comment456",
            body: "Different body",
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: "different-url",
            replyTo: "parent123",
            isMinimized: true
        )
        
        // Then
        XCTAssertEqual(comment1, comment2)
        XCTAssertNotEqual(comment1, comment3)
    }
    
    // MARK: - Hashable Tests
    
    func testCommentHashable() {
        // Given
        let comment1 = Comment(
            id: "comment123",
            body: "Test body",
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            replyTo: nil,
            isMinimized: false
        )
        
        let comment2 = Comment(
            id: "comment123",
            body: "Test body",
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            replyTo: nil,
            isMinimized: false
        )
        
        let comment3 = Comment(
            id: "comment456",
            body: "Different",
            author: testUser,
            createdAt: testDate,
            updatedAt: testDate,
            url: "different",
            replyTo: nil,
            isMinimized: false
        )
        
        let commentSet: Set<Comment> = [comment1, comment2, comment3]
        
        // Then
        XCTAssertEqual(commentSet.count, 2) // comment1 and comment2 are the same
    }
}

// MARK: - CreateCommentInput Tests

final class CreateCommentInputTests: XCTestCase {
    
    func testCreateCommentInputInitialization() {
        // Given
        let discussionId = "discussion123"
        let body = "New comment body"
        let replyToId = "comment456"
        
        // When
        let input = CreateCommentInput(
            discussionId: discussionId,
            body: body,
            replyToId: replyToId
        )
        
        // Then
        XCTAssertEqual(input.discussionId, discussionId)
        XCTAssertEqual(input.body, body)
        XCTAssertEqual(input.replyToId, replyToId)
    }
    
    func testCreateCommentInputWithNilReplyTo() {
        // Given
        let input = CreateCommentInput(
            discussionId: "discussion123",
            body: "Top-level comment",
            replyToId: nil
        )
        
        // Then
        XCTAssertNil(input.replyToId)
    }
    
    func testCreateCommentInputJSONEncoding() throws {
        // Given
        let input = CreateCommentInput(
            discussionId: "discussion123",
            body: "New comment",
            replyToId: "comment456"
        )
        
        // When
        let jsonData = try JSONEncoder().encode(input)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("discussion123") == true)
        XCTAssertTrue(jsonString?.contains("New comment") == true)
        XCTAssertTrue(jsonString?.contains("comment456") == true)
    }
}

// MARK: - CommentsResponse Tests

final class CommentsResponseTests: XCTestCase {
    
    func testCommentsResponseDecoding() throws {
        // Given
        let jsonString = """
        {
            "data": {
                "repository": {
                    "discussion": {
                        "comments": {
                            "nodes": [],
                            "pageInfo": {
                                "hasNextPage": false,
                                "hasPreviousPage": false,
                                "startCursor": null,
                                "endCursor": null
                            },
                            "totalCount": 0
                        }
                    }
                }
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(CommentsResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.data.repository.discussion.comments.totalCount, 0)
        XCTAssertFalse(response.data.repository.discussion.comments.pageInfo.hasNextPage)
        XCTAssertTrue(response.data.repository.discussion.comments.nodes.isEmpty)
    }
}

// MARK: - CreateCommentResponse Tests

final class CreateCommentResponseTests: XCTestCase {
    
    func testCreateCommentResponseSuccessDecoding() throws {
        // Given
        let jsonString = """
        {
            "data": {
                "addDiscussionComment": {
                    "comment": {
                        "id": "comment123",
                        "body": "New comment",
                        "author": {
                            "id": "user123",
                            "login": "testuser",
                            "avatarUrl": "https://github.com/testuser.png",
                            "url": "https://github.com/testuser"
                        },
                        "created_at": "2022-01-01T00:00:00Z",
                        "updated_at": "2022-01-01T00:00:00Z",
                        "url": "https://github.com/test/repo/discussions/1#comment-123",
                        "reply_to": null,
                        "is_minimized": false
                    }
                }
            }
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // When
        let response = try decoder.decode(CreateCommentResponse.self, from: jsonData)
        
        // Then
        XCTAssertNotNil(response.data)
        XCTAssertNil(response.errors)
        XCTAssertEqual(response.data?.addDiscussionComment.comment.id, "comment123")
        XCTAssertEqual(response.data?.addDiscussionComment.comment.body, "New comment")
    }
    
    func testCreateCommentResponseErrorDecoding() throws {
        // Given
        let jsonString = """
        {
            "data": null,
            "errors": [
                {
                    "message": "Could not resolve to a node with the global id of 'invalid_id'",
                    "type": "NOT_FOUND",
                    "path": ["addDiscussionComment"]
                }
            ]
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try decoder.decode(CreateCommentResponse.self, from: jsonData)
        
        // Then
        XCTAssertNil(response.data)
        XCTAssertNotNil(response.errors)
        XCTAssertEqual(response.errors?.count, 1)
        XCTAssertEqual(response.errors?.first?.message, "Could not resolve to a node with the global id of 'invalid_id'")
        XCTAssertEqual(response.errors?.first?.type, "NOT_FOUND")
    }
}

// MARK: - GraphQLError Tests

final class GraphQLErrorTests: XCTestCase {
    
    func testGraphQLErrorDecoding() throws {
        // Given
        let jsonString = """
        {
            "message": "Field 'invalidField' doesn't exist on type 'Discussion'",
            "type": "FIELD_ERROR",
            "path": ["repository", "discussions", "nodes", 0, "invalidField"]
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let error = try JSONDecoder().decode(GraphQLError.self, from: jsonData)
        
        // Then
        XCTAssertEqual(error.message, "Field 'invalidField' doesn't exist on type 'Discussion'")
        XCTAssertEqual(error.type, "FIELD_ERROR")
        XCTAssertEqual(error.path?.count, 5)
        XCTAssertEqual(error.path?[0], "repository")
        XCTAssertEqual(error.path?[4], "invalidField")
    }
    
    func testGraphQLErrorWithNilOptionals() throws {
        // Given
        let jsonString = """
        {
            "message": "Something went wrong"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let error = try JSONDecoder().decode(GraphQLError.self, from: jsonData)
        
        // Then
        XCTAssertEqual(error.message, "Something went wrong")
        XCTAssertNil(error.type)
        XCTAssertNil(error.path)
    }
}