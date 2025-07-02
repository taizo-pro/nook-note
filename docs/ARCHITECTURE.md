# NookNote Architecture

This document provides a comprehensive overview of NookNote's technical architecture, design patterns, and implementation details.

## 🏗️ High-Level Architecture

NookNote follows a modern, layered architecture designed for maintainability, testability, and performance:

```
┌─────────────────────────────────────────────────┐
│                 Presentation Layer              │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
│  │   SwiftUI   │  │  MenuBar    │  │  Design  │ │
│  │    Views    │  │ Controller  │  │  System  │ │
│  └─────────────┘  └─────────────┘  └──────────┘ │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│                Business Logic Layer             │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
│  │ ViewModels  │  │  Services   │  │   State  │ │
│  │   (MVVM)    │  │             │  │ Manager  │ │
│  └─────────────┘  └─────────────┘  └──────────┘ │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│                   Data Layer                    │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
│  │  Models     │  │ API Client  │  │ Storage  │ │
│  │             │  │  (GitHub)   │  │          │ │
│  └─────────────┘  └─────────────┘  └──────────┘ │
└─────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────┐
│                 Foundation Layer                │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
│  │ Networking  │  │  Security   │  │  Utils   │ │
│  │             │  │ (Keychain)  │  │          │ │
│  └─────────────┘  └─────────────┘  └──────────┘ │
└─────────────────────────────────────────────────┘
```

## 🎯 Design Principles

### 1. **Separation of Concerns**
- Clear boundaries between UI, business logic, and data
- Each component has a single, well-defined responsibility
- Minimal coupling between layers

### 2. **Testability**
- Dependency injection for all services
- Protocol-based abstractions
- Pure functions where possible
- Comprehensive test coverage

### 3. **Performance**
- Reactive architecture with Combine
- Efficient memory management
- Background processing for API calls
- Lazy loading and caching

### 4. **Maintainability**
- Consistent code organization
- Clear naming conventions
- Comprehensive documentation
- Type-safe implementations

## 📱 Application Structure

### MenuBar Application Lifecycle

```swift
┌─────────────────┐
│   AppDelegate   │ ← Entry point, manages app lifecycle
└─────────────────┘
         │
         ▼
┌─────────────────┐
│ StatusBarItem   │ ← Creates and manages MenuBar presence
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   NSPopover     │ ← Houses the main SwiftUI interface
└─────────────────┘
         │
         ▼
┌─────────────────┐
│  ContentView    │ ← Root SwiftUI view with tab navigation
└─────────────────┘
```

### Component Hierarchy

```
ContentView (Root)
├── DiscussionsView
│   ├── DiscussionListView
│   ├── DiscussionDetailView
│   └── SearchBar
├── NewPostView
│   ├── CategorySelector
│   ├── TitleField
│   └── BodyEditor
└── SettingsView
    ├── TokenField
    ├── RepositorySettings
    └── PreferencesPanel
```

## 🔄 MVVM Pattern Implementation

### ViewModels

Each major view has a corresponding ViewModel that:
- Manages view state using `@Published` properties
- Handles user interactions
- Coordinates with services
- Provides data binding for SwiftUI

```swift
class DiscussionsViewModel: ObservableObject {
    @Published var discussions: [Discussion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service: DiscussionsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Business logic methods
}
```

### Reactive Data Flow

```
User Interaction → ViewModel → Service → API/Storage
                     ↓
              @Published Property
                     ↓
               SwiftUI View Updates
```

## 🌐 GitHub API Integration

### API Architecture

NookNote integrates with GitHub using both GraphQL API v4 and REST API v3:

```
┌─────────────────┐
│  GitHubClient   │ ← Main API coordinator
└─────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌─────────┐
│GraphQL  │ │ REST    │
│Client   │ │ Client  │
└─────────┘ └─────────┘
```

### GraphQL Usage
- **Discussions**: Fetching discussion lists and details
- **Comments**: Loading comment threads
- **Users**: User profile information
- **Repository**: Repository metadata

### REST API Usage
- **Authentication**: Token validation
- **Rate Limiting**: Checking API limits
- **Repository Access**: Verifying permissions

### API Client Implementation

```swift
protocol GitHubAPIClientProtocol {
    func fetchDiscussions(owner: String, repository: String) async throws -> [Discussion]
    func createDiscussion(_ discussion: NewDiscussion) async throws -> Discussion
    func addComment(to discussionId: String, body: String) async throws -> Comment
}

final class GitHubAPIClient: GitHubAPIClientProtocol {
    private let graphQLClient: GraphQLClient
    private let restClient: RESTClient
    private let authService: AuthenticationService
    
    // Implementation details...
}
```

## 💾 Data Management

### Data Models

Core data models represent GitHub entities:

```swift
struct Discussion: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let category: Category
    let author: User
    let createdAt: Date
    let updatedAt: Date
    let comments: [Comment]
    let state: DiscussionState
}

struct Comment: Identifiable, Codable {
    let id: String
    let body: String
    let author: User
    let createdAt: Date
    let updatedAt: Date
}
```

### State Management

Application state is managed through:

1. **Settings**: UserDefaults for app preferences
2. **Authentication**: Keychain for secure token storage
3. **Cache**: In-memory caching for discussions
4. **Reactive Updates**: Combine publishers for real-time updates

```swift
class AppState: ObservableObject {
    @Published var settings: AppSettings
    @Published var authenticationState: AuthenticationState
    @Published var discussions: [Discussion] = []
    
    private let settingsService: SettingsService
    private let authService: AuthenticationService
}
```

## 🔐 Security Architecture

### Authentication Flow

```
1. User enters PAT → 2. Token validation → 3. Secure storage
                                              ↓
4. API requests ← 5. Token retrieval ← 6. Keychain access
```

### Security Measures

- **Token Storage**: GitHub Personal Access Tokens stored in macOS Keychain
- **HTTPS Only**: All network communication uses TLS/SSL
- **No Data Collection**: Zero analytics or tracking
- **Sandboxing**: App runs in macOS sandbox for security

### Keychain Integration

```swift
protocol KeychainServiceProtocol {
    func store(token: String) throws
    func retrieveToken() throws -> String?
    func deleteToken() throws
}

final class KeychainService: KeychainServiceProtocol {
    private let service = "com.nooknote.app"
    private let account = "github-token"
    
    // Secure implementation using Security framework
}
```

## 🎨 UI Architecture

### Design System

NookNote implements a comprehensive design system for consistency:

```swift
enum DesignTokens {
    enum Colors {
        static let primary = Color("PrimaryColor")
        static let secondary = Color("SecondaryColor")
        static let background = Color("BackgroundColor")
    }
    
    enum Typography {
        static let heading = Font.title2.weight(.semibold)
        static let body = Font.body
        static let caption = Font.caption
    }
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
}
```

### Responsive Design

The UI adapts to different window sizes:

```swift
struct ResponsiveLayout: ViewModifier {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    func body(content: Content) -> some View {
        if sizeClass == .compact {
            content.compactLayout()
        } else {
            content.regularLayout()
        }
    }
}
```

### Accessibility Implementation

- **VoiceOver**: Complete screen reader support
- **Keyboard Navigation**: Full keyboard control
- **Dynamic Type**: Supports system text scaling
- **Color Contrast**: WCAG AA compliant colors

## ⚡ Performance Optimizations

### Memory Management

- **Weak References**: Preventing retain cycles in Combine chains
- **Lazy Loading**: Loading discussions on-demand
- **Image Caching**: Efficient avatar image caching
- **Background Processing**: API calls on background queues

### Networking Optimization

- **Request Batching**: Combining multiple API requests
- **Caching**: Intelligent caching of discussion data
- **Rate Limiting**: Respecting GitHub API limits
- **Error Recovery**: Automatic retry with exponential backoff

### UI Performance

- **SwiftUI Best Practices**: Efficient view updates
- **Debouncing**: Search input debouncing
- **Virtual Scrolling**: Efficient list rendering
- **Animation Optimization**: Smooth, performant animations

## 🧪 Testing Architecture

### Test Pyramid

```
                    ┌─────────────┐
                    │ UI Tests    │ ← End-to-end workflows
                    └─────────────┘
                ┌───────────────────┐
                │ Integration Tests │ ← Service interactions
                └───────────────────┘
        ┌─────────────────────────────────┐
        │         Unit Tests              │ ← Business logic, models
        └─────────────────────────────────┘
```

### Testing Strategy

1. **Unit Tests**: Pure business logic, models, utilities
2. **Integration Tests**: API integration, service coordination
3. **UI Tests**: User workflows, accessibility
4. **Performance Tests**: Memory usage, response times

### Mock Implementation

```swift
class MockGitHubAPIClient: GitHubAPIClientProtocol {
    var fetchDiscussionsResult: Result<[Discussion], Error> = .success([])
    
    func fetchDiscussions(owner: String, repository: String) async throws -> [Discussion] {
        try fetchDiscussionsResult.get()
    }
}
```

## 🚀 Deployment Architecture

### Build Configuration

- **Debug**: Development with detailed logging
- **Release**: Optimized for distribution
- **Testing**: Special configuration for CI/CD

### Distribution Pipeline

```
Source Code → Build → Test → Code Sign → Package → Release
     │                                      │
     └──── CI/CD (GitHub Actions) ──────────┘
```

### Release Management

- **Semantic Versioning**: Clear version numbering
- **Automated Builds**: GitHub Actions CI/CD
- **Code Signing**: Self-signed certificates
- **DMG Creation**: Automated packaging

## 🔄 Error Handling

### Error Architecture

```swift
enum NookNoteError: LocalizedError {
    case authentication(AuthenticationError)
    case api(APIError)
    case network(NetworkError)
    case storage(StorageError)
    
    var errorDescription: String? {
        // User-friendly error messages
    }
}
```

### Error Recovery

- **Automatic Retry**: Network requests with exponential backoff
- **Graceful Degradation**: Offline functionality where possible
- **User Feedback**: Clear error messages and recovery suggestions
- **Logging**: Comprehensive error logging for debugging

## 📈 Monitoring & Analytics

### Performance Monitoring

- **Memory Usage**: Tracking memory consumption
- **Response Times**: API call performance
- **Error Rates**: Monitoring failure rates
- **User Flows**: Understanding usage patterns

### Privacy-First Approach

- **No Tracking**: Zero user behavior tracking
- **Local Metrics**: Performance data stays local
- **Opt-in Diagnostics**: Optional crash reporting
- **Transparency**: Open source for full visibility

## 🔮 Future Architecture Considerations

### Scalability

- **Plugin System**: Architecture for future extensibility
- **Multi-Repository**: Support for multiple GitHub repositories
- **Cross-Platform**: Shared business logic for iOS companion

### Technology Evolution

- **Swift 6**: Preparing for language updates
- **SwiftUI Evolution**: Adopting new SwiftUI features
- **API Changes**: Adapting to GitHub API evolution

---

This architecture document is maintained alongside the codebase. For questions or suggestions about the architecture, please [open a discussion](https://github.com/taizo-pro/nook-note/discussions) or [submit an issue](https://github.com/taizo-pro/nook-note/issues).