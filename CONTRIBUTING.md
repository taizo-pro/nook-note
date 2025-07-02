# Contributing to NookNote

Thank you for your interest in contributing to NookNote! We welcome contributions from everyone, whether you're fixing bugs, adding features, improving documentation, or helping with testing.

## 🚀 Quick Start

1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. **Set up** the development environment
4. **Create** a feature branch
5. **Make** your changes
6. **Test** your changes
7. **Submit** a pull request

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Documentation](#documentation)
- [Community](#community)

## 📜 Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

**In short**: Be respectful, inclusive, and constructive. We're all here to make NookNote better together.

## 🏁 Getting Started

### Prerequisites

- **macOS 12.0+** (Monterey or later)
- **Xcode 15.0+** with Command Line Tools
- **Swift 5.9+** (included with Xcode)
- **Git** for version control

### Optional Tools

```bash
# Install recommended development tools
brew install swiftlint swift-format
```

### Finding Something to Work On

- 🐛 **Bug Reports**: Check [Issues](https://github.com/taizo-pro/nook-note/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
- ✨ **Feature Requests**: See [Enhancement Issues](https://github.com/taizo-pro/nook-note/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
- 📖 **Documentation**: Look for [Documentation Issues](https://github.com/taizo-pro/nook-note/issues?q=is%3Aissue+is%3Aopen+label%3Adocumentation)
- 🆕 **Good First Issues**: Perfect for new contributors - [Good First Issue](https://github.com/taizo-pro/nook-note/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

## 🛠️ Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/nook-note.git
cd nook-note

# Add upstream remote
git remote add upstream https://github.com/taizo-pro/nook-note.git
```

### 2. Set Up Development Environment

```bash
# Install development dependencies
brew install swiftlint swift-format

# Set up development environment (if script exists)
./Scripts/setup-dev.sh

# Open in Xcode
open Package.swift
```

### 3. Verify Setup

```bash
# Run tests to ensure everything works
swift test

# Build the project
swift build

# Run linting
swiftlint
```

## 🔄 Making Changes

### Workflow

1. **Sync** with upstream before starting
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Commit** with clear messages
6. **Push** and create a pull request

### Detailed Steps

```bash
# 1. Sync with upstream
git checkout main
git pull upstream main
git push origin main

# 2. Create a feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description

# 3. Make your changes
# Edit code, add features, fix bugs...

# 4. Test your changes
swift test
swift build --configuration release

# 5. Commit changes
git add .
git commit -m "feat: add amazing new feature"

# 6. Push and create PR
git push origin feature/your-feature-name
# Then create a pull request on GitHub
```

### Branch Naming

Use descriptive branch names:

- `feature/multi-repository-support`
- `fix/memory-leak-in-discussions`
- `docs/improve-installation-guide`
- `test/add-integration-tests`

## 🧪 Testing

Testing is crucial for maintaining code quality. We have several types of tests:

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter "UserTests"

# Run with code coverage
swift test --enable-code-coverage

# Run performance tests
swift test --filter "PerformanceTests"
```

### Test Types

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test component interactions
3. **UI Tests**: Test user interface behavior
4. **Performance Tests**: Test memory usage and speed
5. **Accessibility Tests**: Test VoiceOver and keyboard navigation

### Writing Tests

When adding new features or fixing bugs:

1. **Write tests first** (TDD approach encouraged)
2. **Test both success and failure cases**
3. **Include edge cases and boundary conditions**
4. **Mock external dependencies** (GitHub API, etc.)
5. **Keep tests focused and independent**

Example test structure:

```swift
final class YourFeatureTests: XCTestCase {
    private var sut: YourFeature!
    
    override func setUp() {
        super.setUp()
        sut = YourFeature()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testYourFeatureBehavior() {
        // Given
        let input = "test input"
        
        // When
        let result = sut.processInput(input)
        
        // Then
        XCTAssertEqual(result, "expected output")
    }
}
```

## 📤 Submitting Changes

### Pull Request Process

1. **Ensure** your code follows our style guidelines
2. **Add tests** for new functionality
3. **Update documentation** if needed
4. **Run the full test suite** and ensure it passes
5. **Create** a clear pull request description

### Pull Request Template

Use this template for your PR description:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] All tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings introduced
```

### Review Process

1. **Automated checks** must pass (CI/CD)
2. **Code review** by project maintainers
3. **Testing** on different configurations
4. **Final approval** and merge

## 🎨 Code Style

We follow Swift best practices and use SwiftLint for consistency.

### Style Guidelines

1. **Swift API Design Guidelines**: Follow [Apple's guidelines](https://swift.org/documentation/api-design-guidelines/)
2. **SwiftLint**: Run `swiftlint` before committing
3. **Naming**: Use clear, descriptive names
4. **Comments**: Document public APIs and complex logic
5. **Error Handling**: Use proper Swift error handling patterns

### Formatting

```bash
# Run SwiftLint to check style
swiftlint

# Auto-fix formatting issues
swiftlint --fix

# Format code (if swift-format is available)
swift-format --in-place --recursive Sources/
```

### Code Organization

- **MVVM Architecture**: Follow established patterns
- **Single Responsibility**: Each class/struct has one purpose
- **Dependency Injection**: Use dependency injection for testability
- **Service Layer**: Keep business logic in services
- **Extensions**: Use extensions to organize code

### Example Code Style

```swift
// MARK: - Protocol Definition
protocol DiscussionServiceProtocol {
    func loadDiscussions() async throws -> [Discussion]
}

// MARK: - Implementation
final class DiscussionsService: DiscussionServiceProtocol {
    // MARK: - Properties
    private let apiClient: GitHubAPIClient
    private let settingsManager: SettingsManager
    
    // MARK: - Initialization
    init(apiClient: GitHubAPIClient, settingsManager: SettingsManager) {
        self.apiClient = apiClient
        self.settingsManager = settingsManager
    }
    
    // MARK: - Public Methods
    func loadDiscussions() async throws -> [Discussion] {
        guard settingsManager.settings.isConfigured else {
            throw DiscussionError.notConfigured
        }
        
        return try await apiClient.fetchDiscussions(
            owner: settingsManager.settings.repositoryOwner,
            repository: settingsManager.settings.repositoryName
        )
    }
}
```

## 📚 Documentation

### Types of Documentation

1. **Code Comments**: For complex algorithms and public APIs
2. **README Updates**: For new features or setup changes
3. **User Guides**: For new user-facing functionality
4. **Developer Docs**: For architectural changes
5. **API Documentation**: For public interfaces

### Documentation Standards

- **Public APIs**: Must have documentation comments
- **Complex Logic**: Should be explained with comments
- **User Guides**: Should include examples and screenshots
- **Changelog**: Update for all user-visible changes

### Writing Documentation

```swift
/// Loads discussions from the configured GitHub repository.
/// 
/// This method fetches discussions using the GitHub GraphQL API and
/// returns them sorted by creation date (newest first).
/// 
/// - Parameters:
///   - refresh: Whether to bypass cache and fetch fresh data
/// - Returns: Array of discussions
/// - Throws: `DiscussionError` if repository is not configured or API fails
func loadDiscussions(refresh: Bool = false) async throws -> [Discussion] {
    // Implementation...
}
```

## 🐛 Bug Reports

When reporting bugs, please include:

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- macOS version: [e.g. 13.0]
- NookNote version: [e.g. 1.0.0]
- GitHub repository: [if relevant]

**Additional context**
Any other context about the problem.
```

## ✨ Feature Requests

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Other solutions you've considered.

**Additional context**
Screenshots, mockups, or examples.
```

## 🏷️ Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/) for clear commit history:

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `chore`: Build process or auxiliary tool changes

### Examples

```bash
feat(discussions): add real-time update notifications
fix(auth): resolve token validation for enterprise accounts
docs(readme): update installation instructions for Apple Silicon
test(models): add comprehensive user model tests
chore(ci): update GitHub Actions to use latest runner
```

## 🚀 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Workflow

1. **Version bump**: Update version numbers
2. **Changelog**: Update CHANGELOG.md
3. **Testing**: Run full test suite
4. **Tagging**: Create git tag
5. **Release**: GitHub Actions handles the rest

## 🌍 Community

### Communication Channels

- 💬 **GitHub Discussions**: [Community forum](https://github.com/taizo-pro/nook-note/discussions)
- 🐛 **GitHub Issues**: [Bug reports and feature requests](https://github.com/taizo-pro/nook-note/issues)
- 📧 **Email**: [security@nooknote.app](mailto:security@nooknote.app) for security issues

### Getting Help

- **First time contributing?** Look for [Good First Issue](https://github.com/taizo-pro/nook-note/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) labels
- **Questions about the code?** Ask in [GitHub Discussions](https://github.com/taizo-pro/nook-note/discussions)
- **Need development help?** Check [DEVELOPMENT.md](DEVELOPMENT.md)

### Recognition

Contributors are recognized in:

- **README.md**: Listed in acknowledgments
- **Release Notes**: Mentioned in changelog
- **GitHub**: Contributor statistics and profile

## ⚠️ Security

### Reporting Security Issues

**Do NOT** report security vulnerabilities through public GitHub issues.

Instead, please email [security@nooknote.app](mailto:security@nooknote.app) with:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Security Best Practices

When contributing:

- **Never commit secrets** (tokens, passwords, keys)
- **Validate all inputs** from external sources
- **Use secure communication** (HTTPS only)
- **Follow OWASP guidelines** for security
- **Test security implications** of changes

## 📞 Getting Support

### For Contributors

- **Development questions**: [GitHub Discussions](https://github.com/taizo-pro/nook-note/discussions)
- **Bug reports**: [GitHub Issues](https://github.com/taizo-pro/nook-note/issues)
- **Feature ideas**: [Feature Requests](https://github.com/taizo-pro/nook-note/discussions/categories/ideas)

### For Users

- **Installation help**: See [INSTALLATION.md](INSTALLATION.md)
- **Usage questions**: [GitHub Discussions](https://github.com/taizo-pro/nook-note/discussions)
- **Troubleshooting**: Check documentation or create an issue

## 🎉 Thank You!

Every contribution makes NookNote better for everyone. Whether you're:

- 🐛 Fixing bugs
- ✨ Adding features  
- 📖 Improving documentation
- 🧪 Writing tests
- 💡 Suggesting ideas
- 🎨 Improving design
- 🌍 Spreading the word

**You're making a difference!** Thank you for being part of the NookNote community.

---

*This contributing guide is a living document. If you have suggestions for improvements, please open an issue or submit a pull request.*