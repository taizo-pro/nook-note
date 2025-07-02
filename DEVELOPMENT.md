# 🛠️ NookNote Development Guide

## 🚀 Quick Development Setup

### Prerequisites
- **macOS 12.0+** (Monterey, Ventura, Sonoma)
- **Xcode 15+** (for full development experience)
- **Swift 5.9+** (comes with Xcode)

### Option 1: Xcode Development (Recommended)

1. **Open in Xcode**:
   ```bash
   open Package.swift
   ```

2. **Set Scheme**: 
   - Select "NookNote" scheme
   - Choose "My Mac" as destination

3. **Run**: Press `⌘R` or click the Run button

### Option 2: Command Line (Basic Testing)

```bash
# Clone and build
git clone https://github.com/taizo-pro/nook-note.git
cd nook-note

# Build in release mode (avoids some bundle issues)
swift build --configuration release

# Run (note: some features like notifications may not work in CLI mode)
swift run --configuration release
```

## 🔧 Development Notes

### Known Issues with CLI Execution

- **Notifications**: UserNotifications framework requires proper app bundle context
- **MenuBar Integration**: Works best when run through Xcode
- **Keychain Access**: May have limitations in CLI mode

### Recommended Development Workflow

1. **Use Xcode** for full feature development and testing
2. **Use CLI** only for quick builds and basic functionality testing
3. **Use simulator/device** for final testing before release

### Project Structure

```
NookNote/
├── Sources/
│   ├── App/              # App lifecycle and main entry point
│   ├── Models/           # Data models (Discussion, Comment, User, etc.)
│   ├── Views/            # SwiftUI views
│   ├── Services/         # Business logic (GitHub API, Auth, etc.)
│   └── Utils/            # Utilities (Design system, animations, etc.)
├── Resources/            # App resources (icons, plist)
├── Tests/                # Unit and integration tests
└── Scripts/              # Build and deployment scripts
```

### Key Components

- **AppDelegate**: NSStatusItem management and MenuBar integration
- **ContentView**: Main UI with tab navigation
- **DiscussionsService**: GitHub API integration
- **DesignSystem**: UI components and styling
- **NotificationService**: System notifications

### Testing Features

1. **Setup GitHub Token** (see main README.md)
2. **Configure Repository** in app settings
3. **Test Core Features**:
   - Browse discussions
   - Create new discussions
   - Comment on discussions
   - Search and filter

### Building for Distribution

```bash
# Build optimized release
swift build --configuration release -Xswiftc -Osize

# Create app bundle (future enhancement)
# See implementation-plan.md Phase 7 for distribution setup
```

## 🐛 Troubleshooting Development Issues

### "Bundle identifier is nil" Errors

**Solution**: Run through Xcode instead of command line:
```bash
open Package.swift
# Then press ⌘R in Xcode
```

### Notification Framework Crashes

The app gracefully handles bundle context issues, but for full testing:
- Use Xcode for development
- Notifications will be disabled in CLI mode

### Build Warnings

Common warnings and their meanings:
- `Invalid Resource 'Resources'`: Safe to ignore, doesn't affect functionality
- `Unused variable 'breakpoint'`: Minor code cleanup needed, doesn't affect functionality

### Performance Issues

- **First build**: May take longer due to dependency compilation
- **Subsequent builds**: Much faster with incremental compilation
- **Release builds**: Optimized for performance

## 📝 Contributing

### Code Style

- Follow SwiftUI and Swift best practices
- Use the established design system (`DesignSystem.swift`)
- Maintain MVVM architecture pattern
- Add comprehensive documentation for new features

### Testing

```bash
# Run tests
swift test

# Run with coverage (Xcode)
# Product → Test (⌘U) with code coverage enabled
```

### Commit Messages

Follow conventional commit format:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/changes

### Pull Request Process

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and test thoroughly
4. Update documentation if needed
5. Submit pull request with clear description

## 🎯 Next Development Phases

See [implementation-plan.md](implementation-plan.md) for the complete roadmap:

- **Phase 6**: Testing and quality assurance
- **Phase 7**: Distribution and CI/CD setup
- **Phase 8**: Documentation and community support

---

For user installation and usage instructions, see [README.md](README.md) and [QUICKSTART.md](QUICKSTART.md).