# NookNote

<p align="center">
  <img src="Resources/AppIcon.appiconset/icon_512x512.png" alt="NookNote Icon" width="128" height="128">
</p>

<p align="center">
  <strong>A modern macOS MenuBar app for GitHub Discussions</strong><br>
  Quick access to discussions, seamless posting, and real-time updates
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-12.0+-blue.svg" alt="macOS 12.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

## ✨ Features

- 🚀 **MenuBar Integration** - Quick access from macOS MenuBar
- 📝 **Discussion Management** - Create and comment on GitHub Discussions
- 🔄 **Real-time Updates** - Auto-refresh every 5 minutes
- 🔍 **Advanced Search** - Filter by category, state, and content
- ⌨️ **Keyboard Shortcuts** - Efficient navigation and actions
- 🎨 **Modern UI** - Native SwiftUI with smooth animations
- 🔐 **Secure Authentication** - Token stored safely in Keychain
- 📱 **Responsive Design** - Adaptive layouts for different window sizes

## 🚀 Quick Start

### Prerequisites

- **macOS 12.0 (Monterey) or later**
- **GitHub Personal Access Token** with the following permissions:
  - `repo` (Repository access)
  - `read:discussion` (Read discussions)
  - `write:discussion` (Write discussions)

### Option 1: Download Pre-built App (Recommended)

1. Go to [Releases](https://github.com/taizo-pro/nook-note/releases)
2. Download the latest `NookNote.dmg`
3. Open the DMG and drag NookNote to Applications
4. **Important**: Right-click → "Open" on first launch (due to self-signed certificate)

### Option 2: Build from Source

**Method A: Xcode (Recommended)**
```bash
# Clone the repository
git clone https://github.com/taizo-pro/nook-note.git
cd nook-note

# Open in Xcode
open Package.swift

# Then press ⌘R to run in Xcode
```

**Method B: Command Line (Basic Testing)**
```bash
# Clone and build
git clone https://github.com/taizo-pro/nook-note.git
cd nook-note

# Build and run (some features may be limited in CLI mode)
swift build --configuration release
swift run --configuration release
```

> **Note**: For full functionality including notifications and proper MenuBar integration, use Xcode. CLI mode is suitable for basic testing only.

## ⚙️ Setup

### 1. Get GitHub Personal Access Token

1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select these scopes:
   - `repo` - Full control of private repositories
   - `read:discussion` - Read discussions
   - `write:discussion` - Write discussions
4. Copy the generated token

### 2. Configure NookNote

1. Launch NookNote (look for the icon in your MenuBar)
2. Click the gear icon or press `⌘,` to open Settings
3. Enter your **Repository Information**:
   - **Owner**: Your GitHub username or organization
   - **Repository**: The repository name (e.g., "my-project")
4. Enter your **Personal Access Token**
5. Click "Save Settings"

### 3. Start Using!

- Click the NookNote icon in MenuBar to open
- Browse discussions in the "Discussions" tab
- Create new discussions in the "New Post" tab
- Use keyboard shortcuts for efficient navigation

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘N` | New discussion |
| `⌘R` | Refresh discussions |
| `⌘L` | Toggle filters |
| `⌘F` | Focus search |
| `⌘K` | Clear form/search |
| `⌘W` | Close window |
| `⌘,` | Open settings |
| `⌘⏎` | Post (in editor) |
| `Escape` | Cancel/close |
| `Control+Tab` | Switch tabs |

## 📖 Usage

### Viewing Discussions

- **Browse**: Scroll through discussions in the main view
- **Search**: Use the search bar to find specific discussions
- **Filter**: Toggle filters with `⌘L` to filter by category or state
- **Open Details**: Click on any discussion to view comments
- **Open in GitHub**: Right-click → "Open in GitHub" for full web interface

### Creating Discussions

1. Switch to "New Post" tab or press `⌘N`
2. Select a category (General, Ideas, Q&A, Show and tell)
3. Enter title and description (Markdown supported)
4. Press `⌘⏎` or click "Post Discussion"

### Managing Comments

- **View Comments**: Click on a discussion to see all comments
- **Add Comment**: Click the "+" button or scroll to bottom
- **Post Comment**: Write your comment and press `⌘⏎`

## 🔧 Troubleshooting

### App Won't Open
- **macOS Security Warning**: Right-click the app → "Open" → "Open" again
- **Outdated macOS**: Ensure you're running macOS 12.0 or later

### Authentication Issues
- **Invalid Token**: Regenerate your GitHub token with correct permissions
- **Repository Not Found**: Verify owner/repository names are correct
- **No Discussions Permission**: Ensure your token has `read:discussion` and `write:discussion` scopes

### Performance Issues
- **Slow Loading**: Check your internet connection
- **High CPU Usage**: Disable auto-refresh in settings if needed

### Getting Help
- Check [Issues](https://github.com/taizo-pro/nook-note/issues) for known problems
- Create a new issue with details about your problem
- Include macOS version, app version, and error messages

## 🛠️ Development

### Building from Source

```bash
# Requirements
# - Xcode 15+
# - Swift 5.9+
# - macOS 12.0+

# Clone and open in Xcode (recommended)
git clone https://github.com/taizo-pro/nook-note.git
cd nook-note
open Package.swift

# Or build from command line
swift build --configuration release
swift run --configuration release

# Create DMG (future feature)
# ./Scripts/create-dmg.sh
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed development setup and troubleshooting.

### Testing

```bash
# Run tests
swift test

# Run with coverage
swift test --enable-code-coverage
```

### Architecture

- **SwiftUI + Combine** - Modern reactive UI framework
- **MVVM Pattern** - Clean separation of concerns
- **Service Layer** - GitHub API, Authentication, Notifications
- **Design System** - Consistent UI components and styling

## 📋 Roadmap

- [x] **Phase 1-5**: Core functionality with modern UI/UX (Complete)
- [ ] **Phase 6**: Comprehensive testing and quality assurance
- [ ] **Phase 7**: Distribution setup and GitHub Actions CI/CD
- [ ] **Phase 8**: Documentation and community support

See [implementation-plan.md](implementation-plan.md) for detailed development roadmap.

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start for Contributors

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `swift test`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with ❤️ using SwiftUI and Combine
- GitHub GraphQL API for discussions integration
- Community feedback and testing

---

<p align="center">
  Made with ❤️ for the GitHub community<br>
  <a href="https://github.com/taizo-pro/nook-note/issues">Report Bug</a> •
  <a href="https://github.com/taizo-pro/nook-note/issues">Request Feature</a>
</p>