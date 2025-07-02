# NookNote Installation Guide

This guide provides detailed instructions for installing NookNote on macOS, including how to handle security warnings for self-signed applications.

## 📋 System Requirements

- **macOS 12.0 (Monterey) or later**
- **Intel Mac or Apple Silicon Mac**
- **Internet connection** for GitHub API access
- **GitHub Personal Access Token** with discussion permissions

## 📥 Installation Methods

### Option 1: Download from GitHub Releases (Recommended)

This is the easiest way to install NookNote for most users.

#### Step 1: Download the DMG

1. Go to [NookNote Releases](https://github.com/taizo-pro/nook-note/releases)
2. Find the latest release
3. Download the `NookNote-vX.X.X.dmg` file
4. **Optional**: Download the `.sha256` file to verify integrity

#### Step 2: Verify Download (Optional but Recommended)

```bash
# Verify the DMG integrity
shasum -a 256 -c NookNote-vX.X.X.dmg.sha256
```

If the output shows "OK", the download is verified and safe.

#### Step 3: Install from DMG

1. **Double-click** the downloaded DMG file
2. A new window will open showing the NookNote app and Applications folder
3. **Drag** `NookNote.app` to the `Applications` folder
4. **Close** the DMG window
5. **Eject** the DMG from Finder sidebar (optional)

#### Step 4: Handle macOS Security Warning

⚠️ **Important**: NookNote uses a self-signed certificate, so macOS will show a security warning on first launch.

**DO NOT** double-click the app from Applications folder initially. Instead:

1. **Open Finder** and go to Applications folder
2. **Find NookNote.app** in the Applications folder
3. **Right-click** on NookNote.app
4. **Select "Open"** from the context menu
5. A security dialog will appear with the message:
   ```
   "NookNote" cannot be opened because the developer cannot be verified.
   macOS cannot verify that this app is free from malware.
   ```
6. **Click "Open"** in the dialog
7. NookNote will launch successfully

**After this first launch**, you can open NookNote normally by:
- Double-clicking the app
- Using Spotlight search
- Clicking the MenuBar icon

### Option 2: Build from Source

For developers or users who prefer to build from source:

#### Prerequisites

- **Xcode 15.0 or later**
- **Swift 5.9 or later**
- **Git**

#### Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/taizo-pro/nook-note.git
   cd nook-note
   ```

2. **Open in Xcode**:
   ```bash
   open Package.swift
   ```

3. **Build and run**:
   - Select "NookNote" scheme
   - Choose "My Mac" as destination
   - Press `⌘R` to build and run

4. **Create distributable app** (optional):
   ```bash
   # Build release version
   swift build --configuration release
   
   # Create DMG (requires additional setup)
   ./Scripts/create-dmg.sh
   ```

## ⚙️ Initial Setup

After installation, you need to configure NookNote with your GitHub repository and access token.

### Step 1: Get GitHub Personal Access Token

1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Click **"Generate new token (classic)"**
3. Give it a descriptive name like "NookNote App"
4. Select the following scopes:
   - ✅ `repo` - Full control of private repositories
   - ✅ `read:discussion` - Read discussions
   - ✅ `write:discussion` - Write discussions
5. **Copy the generated token** (you won't see it again!)

### Step 2: Configure NookNote

1. **Launch NookNote** (look for the icon in your MenuBar)
2. **Click the MenuBar icon** to open the app
3. **Click the gear icon** or press `⌘,` to open Settings
4. **Enter your repository information**:
   - **Owner**: Your GitHub username or organization name
   - **Repository**: The repository name (e.g., "my-project")
5. **Enter your Personal Access Token** in the token field
6. **Click "Save Settings"**

### Step 3: Verify Setup

1. The app should automatically load discussions from your repository
2. If successful, you'll see discussions in the main view
3. You can now create new discussions and comment on existing ones

## 🔧 Troubleshooting

### Common Installation Issues

#### "App is damaged and can't be opened"

This usually happens if the download was corrupted or if macOS Gatekeeper is being overly strict.

**Solution**:
1. Delete the downloaded DMG and app
2. Clear the quarantine attribute:
   ```bash
   sudo xattr -rd com.apple.quarantine /Applications/NookNote.app
   ```
3. Or re-download and verify with checksums

#### "No mountable file systems" when opening DMG

The DMG file may be corrupted.

**Solution**:
1. Re-download the DMG file
2. Verify integrity with the SHA256 checksum
3. If problem persists, try downloading with a different browser

#### App won't start after installation

**Solution**:
1. Check Console.app for error messages
2. Ensure you're running macOS 12.0 or later
3. Try the "right-click → Open" method again
4. If still failing, try the source build method

### Configuration Issues

#### "GitHub repository not configured" error

You need to set up your GitHub repository and token.

**Solution**:
1. Press `⌘,` to open Settings
2. Ensure Owner and Repository fields are filled correctly
3. Verify your Personal Access Token is valid
4. Check that the token has required permissions

#### "Invalid Personal Access Token" error

Your token may be expired, revoked, or lack necessary permissions.

**Solution**:
1. Generate a new token with correct scopes
2. Ensure the token has `repo`, `read:discussion`, and `write:discussion` permissions
3. Update the token in NookNote settings

#### "Repository not found" error

The repository name or owner may be incorrect, or the repository may not exist.

**Solution**:
1. Verify the repository exists and is accessible
2. Check spelling of owner and repository name
3. Ensure your token has access to the repository
4. For private repositories, ensure the token has appropriate permissions

### Performance Issues

#### App is slow or unresponsive

**Solutions**:
1. Check your internet connection
2. Verify the GitHub API is accessible
3. Try refreshing with `⌘R`
4. Restart the app
5. Check Activity Monitor for high CPU usage

#### High memory usage

**Solutions**:
1. Restart the app
2. Check for runaway processes in Activity Monitor
3. Report the issue with details about your usage

## 🔒 Security Considerations

### Self-Signed Certificate

NookNote is distributed with a self-signed certificate to keep it free. This means:

✅ **Safe practices**:
- Download only from official GitHub Releases
- Verify checksums when provided
- Use right-click → Open for first launch

❌ **Avoid**:
- Downloading from unofficial sources
- Ignoring checksum verification
- Disabling macOS security features permanently

### Data Privacy

NookNote only communicates with:
- **GitHub API** (api.github.com) for discussions
- **Your configured repository** for content

NookNote does NOT:
- Send data to third parties
- Track usage analytics
- Store data outside your Mac
- Access repositories beyond what you configure

### Token Security

Your Personal Access Token is stored securely:
- ✅ Stored in macOS UserDefaults (encrypted on disk)
- ✅ Never logged or exposed in error messages
- ✅ Only transmitted to GitHub API over HTTPS
- ⚠️ Visible in Settings UI (as expected for user configuration)

## 🆘 Getting Help

### Documentation

- **README**: [Basic usage and features](README.md)
- **Quick Start**: [5-minute setup guide](QUICKSTART.md)
- **Development**: [Developer setup guide](DEVELOPMENT.md)

### Support Channels

1. **GitHub Issues**: [Report bugs or request features](https://github.com/taizo-pro/nook-note/issues)
2. **Discussions**: [Ask questions or share feedback](https://github.com/taizo-pro/nook-note/discussions)
3. **Documentation**: Check the docs folder for additional guides

### When Reporting Issues

Please include:

1. **macOS version** (⌘ → About This Mac)
2. **NookNote version** (shown in app or filename)
3. **Steps to reproduce** the issue
4. **Error messages** (if any)
5. **Screenshots** (if helpful)
6. **Console logs** (if the app crashes)

### Emergency Uninstall

If you need to completely remove NookNote:

1. **Quit the app** if running
2. **Delete from Applications**:
   ```bash
   rm -rf /Applications/NookNote.app
   ```
3. **Remove settings** (optional):
   ```bash
   defaults delete com.nooknote.app
   ```
4. **Remove from MenuBar** (automatic when app is deleted)

## 🎉 Enjoy NookNote!

Once installed and configured, NookNote provides quick access to your GitHub Discussions right from your MenuBar. Use keyboard shortcuts for efficiency and enjoy the streamlined workflow for discussion management.

For the best experience:
- Keep the app updated by checking for new releases
- Use keyboard shortcuts (press `⌘,` in app to see them)
- Report any issues to help improve the app for everyone

Thank you for using NookNote! 🚀