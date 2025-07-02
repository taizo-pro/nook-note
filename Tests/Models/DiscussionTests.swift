import XCTest
@testable import NookNote

final class DiscussionTests: XCTestCase {
    
    // MARK: - Test Data
    
    private var testUser: User {
        User(
            id: "user123",
            login: "testuser",
            avatarUrl: "https://github.com/testuser.png",
            url: "https://github.com/testuser"
        )
    }
    
    private var testCategory: DiscussionCategory {
        DiscussionCategory(
            id: "cat123",
            name: "General",
            emoji: "💬",
            description: "General discussions"
        )
    }
    
    private var testCommentCount: CommentCount {
        CommentCount(totalCount: 5)
    }
    
    private var testDate: Date {
        Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
    }
    
    // MARK: - Initialization Tests
    
    func testDiscussionInitialization() {
        // Given
        let id = "discussion123"
        let number = 42
        let title = "Test Discussion"
        let body = "This is a test discussion body"
        let url = "https://github.com/owner/repo/discussions/42"
        let locked = false
        let state = DiscussionState.open
        
        // When
        let discussion = Discussion(
            id: id,
            number: number,
            title: title,
            body: body,
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: url,
            comments: testCommentCount,
            locked: locked,
            state: state
        )
        
        // Then
        XCTAssertEqual(discussion.id, id)
        XCTAssertEqual(discussion.number, number)
        XCTAssertEqual(discussion.title, title)
        XCTAssertEqual(discussion.body, body)
        XCTAssertEqual(discussion.author, testUser)
        XCTAssertEqual(discussion.category, testCategory)
        XCTAssertEqual(discussion.createdAt, testDate)
        XCTAssertEqual(discussion.updatedAt, testDate)
        XCTAssertEqual(discussion.url, url)
        XCTAssertEqual(discussion.comments, testCommentCount)
        XCTAssertEqual(discussion.locked, locked)
        XCTAssertEqual(discussion.state, state)
    }
    
    func testDiscussionWithNilBody() {
        // Given
        let discussion = Discussion(
            id: "123",
            number: 1,
            title: "Title",
            body: nil,
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            comments: testCommentCount,
            locked: false,
            state: .open
        )
        
        // Then
        XCTAssertNil(discussion.body)
    }
    
    // MARK: - Computed Properties Tests
    
    func testCommentsCount() {
        // Given
        let commentCount = CommentCount(totalCount: 10)
        let discussion = Discussion(
            id: "123",
            number: 1,
            title: "Title",
            body: "Body",
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            comments: commentCount,
            locked: false,
            state: .open
        )
        
        // When
        let count = discussion.commentsCount
        
        // Then
        XCTAssertEqual(count, 10)
    }
    
    // MARK: - Codable Tests
    
    func testDiscussionJSONEncoding() throws {
        // Given
        let discussion = Discussion(
            id: "123",
            number: 42,
            title: "Test Discussion",
            body: "Test body",
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "https://github.com/test/repo/discussions/42",
            comments: testCommentCount,
            locked: false,
            state: .open
        )
        
        // When
        let jsonData = try JSONEncoder().encode(discussion)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("Test Discussion") == true)
        XCTAssertTrue(jsonString?.contains("42") == true)
        XCTAssertTrue(jsonString?.contains("OPEN") == true)
    }
    
    func testDiscussionJSONDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "123",
            "number": 42,
            "title": "Test Discussion",
            "body": "Test body",
            "author": {
                "id": "user123",
                "login": "testuser",
                "avatarUrl": "https://github.com/testuser.png",
                "url": "https://github.com/testuser"
            },
            "category": {
                "id": "cat123",
                "name": "General",
                "emoji": "💬",
                "description": "General discussions"
            },
            "createdAt": "2022-01-01T00:00:00Z",
            "updatedAt": "2022-01-01T00:00:00Z",
            "url": "https://github.com/test/repo/discussions/42",
            "comments": {
                "totalCount": 5
            },
            "locked": false,
            "state": "OPEN"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // When
        let discussion = try decoder.decode(Discussion.self, from: jsonData)
        
        // Then
        XCTAssertEqual(discussion.id, "123")
        XCTAssertEqual(discussion.number, 42)
        XCTAssertEqual(discussion.title, "Test Discussion")
        XCTAssertEqual(discussion.body, "Test body")
        XCTAssertEqual(discussion.author.login, "testuser")
        XCTAssertEqual(discussion.category.name, "General")
        XCTAssertEqual(discussion.commentsCount, 5)
        XCTAssertEqual(discussion.locked, false)
        XCTAssertEqual(discussion.state, .open)
    }
    
    // MARK: - Equatable Tests
    
    func testDiscussionEquality() {
        // Given
        let discussion1 = Discussion(
            id: "123",
            number: 1,
            title: "Title",
            body: "Body",
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            comments: testCommentCount,
            locked: false,
            state: .open
        )
        
        let discussion2 = Discussion(
            id: "123",
            number: 1,
            title: "Title",
            body: "Body",
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            comments: testCommentCount,
            locked: false,
            state: .open
        )
        
        let discussion3 = Discussion(
            id: "456",
            number: 2,
            title: "Different Title",
            body: "Different Body",
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "different-url",
            comments: testCommentCount,
            locked: true,
            state: .closed
        )
        
        // Then
        XCTAssertEqual(discussion1, discussion2)
        XCTAssertNotEqual(discussion1, discussion3)
    }
    
    // MARK: - Hashable Tests
    
    func testDiscussionHashable() {
        // Given
        let discussion1 = Discussion(
            id: "123",
            number: 1,
            title: "Title",
            body: "Body",
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            comments: testCommentCount,
            locked: false,
            state: .open
        )
        
        let discussion2 = Discussion(
            id: "123",
            number: 1,
            title: "Title",
            body: "Body",
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "url",
            comments: testCommentCount,
            locked: false,
            state: .open
        )
        
        let discussion3 = Discussion(
            id: "456",
            number: 2,
            title: "Different",
            body: "Different",
            author: testUser,
            category: testCategory,
            createdAt: testDate,
            updatedAt: testDate,
            url: "different",
            comments: testCommentCount,
            locked: false,
            state: .open
        )
        
        let discussionSet: Set<Discussion> = [discussion1, discussion2, discussion3]
        
        // Then
        XCTAssertEqual(discussionSet.count, 2) // discussion1 and discussion2 are the same
    }
}

// MARK: - CommentCount Tests

final class CommentCountTests: XCTestCase {
    
    func testCommentCountInitialization() {
        // Given
        let totalCount = 42
        
        // When
        let commentCount = CommentCount(totalCount: totalCount)
        
        // Then
        XCTAssertEqual(commentCount.totalCount, totalCount)
    }
    
    func testCommentCountJSONEncoding() throws {
        // Given
        let commentCount = CommentCount(totalCount: 10)
        
        // When
        let jsonData = try JSONEncoder().encode(commentCount)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("10") == true)
    }
    
    func testCommentCountJSONDecoding() throws {
        // Given
        let jsonString = """
        {
            "totalCount": 15
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let commentCount = try JSONDecoder().decode(CommentCount.self, from: jsonData)
        
        // Then
        XCTAssertEqual(commentCount.totalCount, 15)
    }
    
    func testCommentCountEquality() {
        // Given
        let count1 = CommentCount(totalCount: 5)
        let count2 = CommentCount(totalCount: 5)
        let count3 = CommentCount(totalCount: 10)
        
        // Then
        XCTAssertEqual(count1, count2)
        XCTAssertNotEqual(count1, count3)
    }
}

// MARK: - DiscussionCategory Tests

final class DiscussionCategoryTests: XCTestCase {
    
    func testDiscussionCategoryInitialization() {
        // Given
        let id = "cat123"
        let name = "General"
        let emoji = "💬"
        let description = "General discussions"
        
        // When
        let category = DiscussionCategory(
            id: id,
            name: name,
            emoji: emoji,
            description: description
        )
        
        // Then
        XCTAssertEqual(category.id, id)
        XCTAssertEqual(category.name, name)
        XCTAssertEqual(category.emoji, emoji)
        XCTAssertEqual(category.description, description)
    }
    
    func testDiscussionCategoryWithNilDescription() {
        // Given
        let category = DiscussionCategory(
            id: "cat123",
            name: "General",
            emoji: "💬",
            description: nil
        )
        
        // Then
        XCTAssertNil(category.description)
    }
    
    func testDiscussionCategoryJSONDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "cat123",
            "name": "Ideas",
            "emoji": "💡",
            "description": "Share ideas for new features"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let category = try JSONDecoder().decode(DiscussionCategory.self, from: jsonData)
        
        // Then
        XCTAssertEqual(category.id, "cat123")
        XCTAssertEqual(category.name, "Ideas")
        XCTAssertEqual(category.emoji, "💡")
        XCTAssertEqual(category.description, "Share ideas for new features")
    }
}

// MARK: - DiscussionState Tests

final class DiscussionStateTests: XCTestCase {
    
    func testDiscussionStateRawValues() {
        // Then
        XCTAssertEqual(DiscussionState.open.rawValue, "OPEN")
        XCTAssertEqual(DiscussionState.closed.rawValue, "CLOSED")
        XCTAssertEqual(DiscussionState.locked.rawValue, "LOCKED")
    }
    
    func testDiscussionStateFromRawValue() {
        // When
        let openState = DiscussionState(rawValue: "OPEN")
        let closedState = DiscussionState(rawValue: "CLOSED")
        let lockedState = DiscussionState(rawValue: "LOCKED")
        let invalidState = DiscussionState(rawValue: "INVALID")
        
        // Then
        XCTAssertEqual(openState, .open)
        XCTAssertEqual(closedState, .closed)
        XCTAssertEqual(lockedState, .locked)
        XCTAssertNil(invalidState)
    }
    
    func testDiscussionStateCaseIterable() {
        // Given
        let allCases = DiscussionState.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.open))
        XCTAssertTrue(allCases.contains(.closed))
        XCTAssertTrue(allCases.contains(.locked))
    }
    
    func testDiscussionStateJSONDecoding() throws {
        // Given
        let jsonData = "\"OPEN\"".data(using: .utf8)!
        
        // When
        let state = try JSONDecoder().decode(DiscussionState.self, from: jsonData)
        
        // Then
        XCTAssertEqual(state, .open)
    }
}

// MARK: - GraphQL Response Types Tests

final class DiscussionsResponseTests: XCTestCase {
    
    func testDiscussionsResponseDecoding() throws {
        // Given
        let jsonString = """
        {
            "data": {
                "repository": {
                    "discussions": {
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
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(DiscussionsResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.data.repository.discussions.totalCount, 0)
        XCTAssertFalse(response.data.repository.discussions.pageInfo.hasNextPage)
        XCTAssertTrue(response.data.repository.discussions.nodes.isEmpty)
    }
}

final class PageInfoTests: XCTestCase {
    
    func testPageInfoWithNullCursors() throws {
        // Given
        let jsonString = """
        {
            "hasNextPage": true,
            "hasPreviousPage": false,
            "startCursor": null,
            "endCursor": "cursor123"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let pageInfo = try JSONDecoder().decode(PageInfo.self, from: jsonData)
        
        // Then
        XCTAssertTrue(pageInfo.hasNextPage)
        XCTAssertFalse(pageInfo.hasPreviousPage)
        XCTAssertNil(pageInfo.startCursor)
        XCTAssertEqual(pageInfo.endCursor, "cursor123")
    }
}