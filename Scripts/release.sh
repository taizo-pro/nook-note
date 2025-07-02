#!/bin/bash

# NookNote Release Script
# Complete build, sign, and release process

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
VERSION="${1:-1.0.0}"
APP_NAME="NookNote"

echo "🚀 NookNote Release Process v$VERSION"
echo "====================================="

# Validate version format
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Error: Invalid version format. Use semantic versioning (e.g., 1.0.0)"
    echo "Usage: $0 <version>"
    exit 1
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  Warning: Not on main branch (current: $CURRENT_BRANCH)"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "❌ Error: Uncommitted changes detected"
    echo "Please commit or stash your changes before releasing"
    exit 1
fi

# Update version in Info.plist
echo "📝 Updating version in Info.plist..."
sed -i '' "s/<string>1\.0\.0<\/string>/<string>$VERSION<\/string>/g" "$PROJECT_DIR/Sources/Info.plist"

# Run tests
echo "🧪 Running tests..."
cd "$PROJECT_DIR"
swift test || {
    echo "❌ Tests failed. Fix tests before releasing."
    exit 1
}

# Build the app
echo "🔨 Building app..."
chmod +x "$SCRIPT_DIR/build-app.sh"
"$SCRIPT_DIR/build-app.sh" || {
    echo "❌ Build failed"
    exit 1
}

# Sign the app
echo "✍️ Signing app..."
chmod +x "$SCRIPT_DIR/sign-app.sh"
"$SCRIPT_DIR/sign-app.sh" || {
    echo "❌ Signing failed"
    exit 1
}

# Create DMG
echo "📀 Creating DMG..."
chmod +x "$SCRIPT_DIR/create-dmg.sh"
"$SCRIPT_DIR/create-dmg.sh" || {
    echo "❌ DMG creation failed"
    exit 1
}

# Generate checksums
echo "🔐 Generating checksums..."
cd "$PROJECT_DIR/build/Release"
DMG_FILE="$APP_NAME-$VERSION.dmg"

if [ -f "$DMG_FILE" ]; then
    shasum -a 256 "$DMG_FILE" > "$DMG_FILE.sha256"
    md5 "$DMG_FILE" > "$DMG_FILE.md5"
    
    echo "✅ Checksums generated:"
    cat "$DMG_FILE.sha256"
    cat "$DMG_FILE.md5"
else
    echo "❌ DMG file not found: $DMG_FILE"
    exit 1
fi

# Commit version change
echo "📝 Committing version change..."
cd "$PROJECT_DIR"
git add Sources/Info.plist
git commit -m "Bump version to $VERSION

🚀 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Create and push tag
echo "🏷️ Creating git tag..."
git tag -a "v$VERSION" -m "Release $VERSION

Features:
- macOS menubar integration
- GitHub Discussions access
- Real-time updates
- Native notifications
- Search and filtering

🚀 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

echo "📤 Pushing to remote..."
git push origin main
git push origin "v$VERSION"

echo ""
echo "🎉 Release Process Complete!"
echo ""
echo "📦 Release Assets:"
echo "   DMG: build/Release/$DMG_FILE"
echo "   Checksums: build/Release/$DMG_FILE.{sha256,md5}"
echo ""
echo "🔗 GitHub Release:"
echo "   Tag: v$VERSION"
echo "   Auto-deploy via GitHub Actions will start shortly"
echo "   Monitor: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
echo ""
echo "📋 Next Steps:"
echo "1. Wait for GitHub Actions to complete"
echo "2. Verify release at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases"
echo "3. Test download and installation"
echo "4. Announce release"
echo ""
echo "🎯 Download URL:"
echo "   https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/releases/download/v$VERSION/$DMG_FILE"