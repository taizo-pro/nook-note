import XCTest
@testable import NookNote

final class UserTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testUserInitialization() {
        // Given
        let id = "123"
        let login = "testuser"
        let avatarUrl = "https://github.com/testuser.png"
        let url = "https://github.com/testuser"
        
        // When
        let user = User(id: id, login: login, avatarUrl: avatarUrl, url: url)
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.login, login)
        XCTAssertEqual(user.avatarUrl, avatarUrl)
        XCTAssertEqual(user.url, url)
    }
    
    // MARK: - Codable Tests
    
    func testUserJSONEncoding() throws {
        // Given
        let user = User(
            id: "123",
            login: "testuser",
            avatarUrl: "https://github.com/testuser.png",
            url: "https://github.com/testuser"
        )
        
        // When
        let jsonData = try JSONEncoder().encode(user)
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("testuser") == true)
        XCTAssertTrue(jsonString?.contains("123") == true)
    }
    
    func testUserJSONDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "123",
            "login": "testuser",
            "avatarUrl": "https://github.com/testuser.png",
            "url": "https://github.com/testuser"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let user = try JSONDecoder().decode(User.self, from: jsonData)
        
        // Then
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.login, "testuser")
        XCTAssertEqual(user.avatarUrl, "https://github.com/testuser.png")
        XCTAssertEqual(user.url, "https://github.com/testuser")
    }
    
    func testUserJSONDecodingWithSnakeCase() throws {
        // Given - GitHub API uses snake_case
        let jsonString = """
        {
            "id": "123",
            "login": "testuser",
            "avatar_url": "https://github.com/testuser.png",
            "url": "https://github.com/testuser"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // When
        let user = try decoder.decode(User.self, from: jsonData)
        
        // Then
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.login, "testuser")
        XCTAssertEqual(user.avatarUrl, "https://github.com/testuser.png")
        XCTAssertEqual(user.url, "https://github.com/testuser")
    }
    
    // MARK: - Equatable Tests
    
    func testUserEquality() {
        // Given
        let user1 = User(id: "123", login: "testuser", avatarUrl: "url1", url: "url1")
        let user2 = User(id: "123", login: "testuser", avatarUrl: "url1", url: "url1")
        let user3 = User(id: "456", login: "otheruser", avatarUrl: "url2", url: "url2")
        
        // Then
        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }
    
    // MARK: - Hashable Tests
    
    func testUserHashable() {
        // Given
        let user1 = User(id: "123", login: "testuser", avatarUrl: "url1", url: "url1")
        let user2 = User(id: "123", login: "testuser", avatarUrl: "url1", url: "url1")
        let user3 = User(id: "456", login: "otheruser", avatarUrl: "url2", url: "url2")
        
        let userSet: Set<User> = [user1, user2, user3]
        
        // Then
        XCTAssertEqual(userSet.count, 2) // user1 and user2 are the same
    }
    
    // MARK: - Edge Cases
    
    func testUserWithEmptyValues() {
        // Given
        let user = User(id: "", login: "", avatarUrl: "", url: "")
        
        // Then
        XCTAssertEqual(user.id, "")
        XCTAssertEqual(user.login, "")
        XCTAssertEqual(user.avatarUrl, "")
        XCTAssertEqual(user.url, "")
    }
    
    func testUserWithSpecialCharacters() {
        // Given
        let user = User(
            id: "user-123_test",
            login: "test-user_123",
            avatarUrl: "https://github.com/test-user_123.png?s=460&v=4",
            url: "https://github.com/test-user_123"
        )
        
        // Then
        XCTAssertEqual(user.id, "user-123_test")
        XCTAssertEqual(user.login, "test-user_123")
        XCTAssertTrue(user.avatarUrl.contains("s=460&v=4"))
    }
}