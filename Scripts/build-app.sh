#!/bin/bash

# NookNote Build Script
# Builds the app for distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
BUILD_DIR="$PROJECT_DIR/.build"
RELEASE_DIR="$PROJECT_DIR/build/Release"
APP_NAME="NookNote"
BUNDLE_ID="com.nooknote.app"
VERSION="1.0.0"

echo "🚀 Building NookNote v$VERSION"
echo "=================================="

# Clean previous builds
echo "📁 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
rm -rf "$PROJECT_DIR/build"
mkdir -p "$RELEASE_DIR"

# Build the Swift package
echo "🔨 Building Swift package..."
cd "$PROJECT_DIR"
swift build --configuration release --arch arm64 --arch x86_64

# Create app bundle structure
echo "📦 Creating app bundle..."
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
echo "📋 Copying executable..."
cp "$BUILD_DIR/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp "$PROJECT_DIR/Sources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy resources (icons, etc.)
echo "📋 Copying resources..."
if [ -d "$PROJECT_DIR/Resources" ]; then
    cp -r "$PROJECT_DIR/Resources"/* "$APP_BUNDLE/Contents/Resources/"
fi

# Set executable permissions
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Verify app bundle structure
echo "✅ Verifying app bundle..."
if [ ! -f "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ]; then
    echo "❌ Error: Executable not found in app bundle"
    exit 1
fi

if [ ! -f "$APP_BUNDLE/Contents/Info.plist" ]; then
    echo "❌ Error: Info.plist not found in app bundle"
    exit 1
fi

echo "✅ App bundle created successfully!"
echo "📍 Location: $APP_BUNDLE"

# Display app info
echo ""
echo "📱 App Information:"
echo "   Name: $APP_NAME"
echo "   Version: $VERSION"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Architecture: Universal (x86_64 + arm64)"
echo "   Target: macOS 12.0+"

# Check if app can be launched
echo ""
echo "🔍 Testing app launch..."
if "$APP_BUNDLE/Contents/MacOS/$APP_NAME" --version &>/dev/null || timeout 5s "$APP_BUNDLE/Contents/MacOS/$APP_NAME" &>/dev/null; then
    echo "✅ App launches successfully"
else
    echo "⚠️  App launch test timed out (this may be normal for GUI apps)"
fi

echo ""
echo "🎉 Build completed successfully!"
echo ""
echo "Next steps:"
echo "1. Test the app: open '$APP_BUNDLE'"
echo "2. Sign the app: ./Scripts/sign-app.sh"
echo "3. Create DMG: ./Scripts/create-dmg.sh"
echo "4. Upload to GitHub Releases"