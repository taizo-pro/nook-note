import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case authenticationRequired
    case rateLimited(resetTime: Date?)
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required"
        case .rateLimited(let resetTime):
            if let resetTime = resetTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Rate limit exceeded. Try again after \(formatter.string(from: resetTime))"
            }
            return "Rate limit exceeded"
        case .serverError(let statusCode):
            return "Server error (\(statusCode))"
        }
    }
}

class GitHubAPIClient {
    private let urlSession: URLSession
    private let authenticationService: AuthenticationService
    private let decoder: JSONDecoder
    
    init(authenticationService: AuthenticationService, urlSession: URLSession = .shared) {
        self.authenticationService = authenticationService
        self.urlSession = urlSession
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Base Request Methods
    
    private func createRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("NookNote/1.0", forHTTPHeaderField: "User-Agent")
        
        if let authHeader = authenticationService.authorizationHeader {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func createGraphQLRequest(query: String, variables: [String: Any]? = nil) throws -> URLRequest {
        guard let url = URL(string: "https://api.github.com/graphql") else {
            throw APIError.invalidURL
        }
        
        var request = createRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["query": query]
        if let variables = variables {
            body["variables"] = variables
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(URLError(.badServerResponse))
            }
            
            // Handle HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw APIError.authenticationRequired
            case 403:
                // Check for rate limiting
                if let rateLimitReset = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Reset"),
                   let resetTimestamp = TimeInterval(rateLimitReset) {
                    let resetDate = Date(timeIntervalSince1970: resetTimestamp)
                    throw APIError.rateLimited(resetTime: resetDate)
                }
                throw APIError.rateLimited(resetTime: nil)
            case 404:
                throw APIError.networkError(URLError(.fileDoesNotExist))
            case 500...599:
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw APIError.noData
            }
            
            do {
                return try decoder.decode(responseType, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - GraphQL Queries
    
    func fetchDiscussions(owner: String, repository: String, first: Int = 20, after: String? = nil) async throws -> DiscussionsResponse {
        let afterClause = after != nil ? ", after: \"\(after!)\"" : ""
        
        let query = """
        query GetDiscussions($owner: String!, $repo: String!) {
          repository(owner: $owner, name: $repo) {
            discussions(first: \(first)\(afterClause), orderBy: {field: UPDATED_AT, direction: DESC}) {
              totalCount
              pageInfo {
                hasNextPage
                hasPreviousPage
                startCursor
                endCursor
              }
              nodes {
                id
                number
                title
                body
                createdAt
                updatedAt
                url
                locked
                state
                comments {
                  totalCount
                }
                category {
                  id
                  name
                  emoji
                  description
                }
                author {
                  login
                  avatarUrl
                  url
                  ... on User {
                    id
                  }
                }
              }
            }
          }
        }
        """
        
        let variables: [String: Any] = [
            "owner": owner,
            "repo": repository
        ]
        
        let request = try createGraphQLRequest(query: query, variables: variables)
        return try await performRequest(request, responseType: DiscussionsResponse.self)
    }
    
    func fetchDiscussionComments(owner: String, repository: String, discussionNumber: Int, first: Int = 20, after: String? = nil) async throws -> CommentsResponse {
        let afterClause = after != nil ? ", after: \"\(after!)\"" : ""
        
        let query = """
        query GetDiscussionComments($owner: String!, $repo: String!, $number: Int!) {
          repository(owner: $owner, name: $repo) {
            discussion(number: $number) {
              comments(first: \(first)\(afterClause), orderBy: {field: CREATED_AT, direction: ASC}) {
                totalCount
                pageInfo {
                  hasNextPage
                  hasPreviousPage
                  startCursor
                  endCursor
                }
                nodes {
                  id
                  body
                  createdAt
                  updatedAt
                  url
                  isMinimized
                  author {
                    login
                    avatarUrl
                    url
                    ... on User {
                      id
                    }
                  }
                }
              }
            }
          }
        }
        """
        
        let variables: [String: Any] = [
            "owner": owner,
            "repo": repository,
            "number": discussionNumber
        ]
        
        let request = try createGraphQLRequest(query: query, variables: variables)
        return try await performRequest(request, responseType: CommentsResponse.self)
    }
    
    // MARK: - Mutations
    
    func createDiscussion(owner: String, repository: String, title: String, body: String, categoryId: String) async throws -> CreateDiscussionResponse {
        let mutation = """
        mutation CreateDiscussion($repositoryId: ID!, $categoryId: ID!, $title: String!, $body: String!) {
          createDiscussion(input: {
            repositoryId: $repositoryId,
            categoryId: $categoryId,
            title: $title,
            body: $body
          }) {
            discussion {
              id
              number
              title
              body
              createdAt
              updatedAt
              url
              locked
              state
              category {
                id
                name
                emoji
                description
              }
              author {
                login
                avatarUrl
                url
                ... on User {
                  id
                }
              }
            }
          }
        }
        """
        
        // First, get repository and category IDs
        let repoId = try await getRepositoryId(owner: owner, name: repository)
        let resolvedCategoryId = try await getDiscussionCategoryId(owner: owner, repository: repository, categoryName: categoryId)
        
        let variables: [String: Any] = [
            "repositoryId": repoId,
            "categoryId": resolvedCategoryId,
            "title": title,
            "body": body
        ]
        
        let request = try createGraphQLRequest(query: mutation, variables: variables)
        return try await performRequest(request, responseType: CreateDiscussionResponse.self)
    }
    
    func addDiscussionComment(discussionId: String, body: String) async throws -> CreateCommentResponse {
        let mutation = """
        mutation AddDiscussionComment($discussionId: ID!, $body: String!) {
          addDiscussionComment(input: {
            discussionId: $discussionId,
            body: $body
          }) {
            comment {
              id
              body
              createdAt
              updatedAt
              url
              isMinimized
              author {
                login
                avatarUrl
                url
                ... on User {
                  id
                }
              }
            }
          }
        }
        """
        
        let variables: [String: Any] = [
            "discussionId": discussionId,
            "body": body
        ]
        
        let request = try createGraphQLRequest(query: mutation, variables: variables)
        return try await performRequest(request, responseType: CreateCommentResponse.self)
    }
    
    // MARK: - Helper Methods
    
    private func getRepositoryId(owner: String, name: String) async throws -> String {
        let query = """
        query GetRepositoryId($owner: String!, $name: String!) {
          repository(owner: $owner, name: $name) {
            id
          }
        }
        """
        
        let variables: [String: Any] = [
            "owner": owner,
            "name": name
        ]
        
        let request = try createGraphQLRequest(query: query, variables: variables)
        let response = try await performRequest(request, responseType: RepositoryIdResponse.self)
        return response.data.repository.id
    }
    
    private func getDiscussionCategoryId(owner: String, repository: String, categoryName: String) async throws -> String {
        let query = """
        query GetDiscussionCategories($owner: String!, $repo: String!) {
          repository(owner: $owner, name: $repo) {
            discussionCategories(first: 20) {
              nodes {
                id
                name
                emoji
                description
              }
            }
          }
        }
        """
        
        let variables: [String: Any] = [
            "owner": owner,
            "repo": repository
        ]
        
        let request = try createGraphQLRequest(query: query, variables: variables)
        let response = try await performRequest(request, responseType: DiscussionCategoriesResponse.self)
        
        // Find category by name (case-insensitive)
        guard let category = response.data.repository.discussionCategories.nodes.first(where: { 
            $0.name.lowercased() == categoryName.lowercased()
        }) else {
            throw APIError.networkError(URLError(.fileDoesNotExist))
        }
        
        return category.id
    }
}

// MARK: - Response Models

struct CreateDiscussionResponse: Codable {
    let data: CreateDiscussionData
}

struct CreateDiscussionData: Codable {
    let createDiscussion: CreateDiscussionPayload
}

struct CreateDiscussionPayload: Codable {
    let discussion: Discussion
}

struct RepositoryIdResponse: Codable {
    let data: RepositoryIdData
}

struct RepositoryIdData: Codable {
    let repository: RepositoryIdInfo
}

struct RepositoryIdInfo: Codable {
    let id: String
}

struct DiscussionCategoriesResponse: Codable {
    let data: DiscussionCategoriesData
}

struct DiscussionCategoriesData: Codable {
    let repository: DiscussionCategoriesRepository
}

struct DiscussionCategoriesRepository: Codable {
    let discussionCategories: DiscussionCategoriesConnection
}

struct DiscussionCategoriesConnection: Codable {
    let nodes: [DiscussionCategory]
}