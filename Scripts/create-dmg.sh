#!/bin/bash

# NookNote - DMG Creation Script
# This script builds the app, signs it, and creates a distributable DMG file

set -e

# Configuration
APP_NAME="NookNote"
BUILD_DIR=".build/release"
DMG_DIR="build/dmg"
TEMP_DMG_DIR="$DMG_DIR/temp"
FINAL_DMG_NAME="$APP_NAME.dmg"
CERT_NAME="NookNote Developer"
KEYCHAIN_NAME="nooknote-signing"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Building and packaging NookNote for distribution...${NC}"

# Check for required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}❌ Error: $1 is required but not installed${NC}"
        exit 1
    fi
}

echo "🔍 Checking required tools..."
check_tool "swift"
check_tool "codesign"
check_tool "hdiutil"

# Check if certificate exists
if ! security find-certificate -c "$CERT_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Warning: Code signing certificate not found${NC}"
    echo "Creating self-signed certificate..."
    ./Scripts/create-certificate.sh
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
rm -rf "$DMG_DIR"
swift package clean

# Build the application
echo "🔨 Building NookNote in release mode..."
swift build --configuration release

# Check if build succeeded
if [ ! -f "$BUILD_DIR/$APP_NAME" ]; then
    echo -e "${RED}❌ Build failed: $BUILD_DIR/$APP_NAME not found${NC}"
    exit 1
fi

# Create app bundle structure
echo "📦 Creating app bundle..."
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Copy app icon
cp -r "Resources/AppIcon.appiconset" "$APP_BUNDLE/Contents/Resources/"

# Create PkgInfo file
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Sign the application
echo "🔏 Code signing the application..."
codesign --sign "$CERT_NAME" \
         --keychain "$KEYCHAIN_NAME" \
         --options runtime \
         --force \
         --deep \
         "$APP_BUNDLE" || {
    echo -e "${YELLOW}⚠️  Code signing failed, continuing without signature...${NC}"
}

# Verify signature
echo "🔍 Verifying code signature..."
codesign --verify --verbose "$APP_BUNDLE" || {
    echo -e "${YELLOW}⚠️  Signature verification failed${NC}"
}

# Create DMG staging directory
echo "📂 Preparing DMG contents..."
mkdir -p "$TEMP_DMG_DIR"
cp -r "$APP_BUNDLE" "$TEMP_DMG_DIR/"

# Create Applications symlink
ln -sf /Applications "$TEMP_DMG_DIR/Applications"

# Create README for DMG
cat > "$TEMP_DMG_DIR/README.txt" << EOF
NookNote - GitHub Discussions MenuBar App

Installation Instructions:
1. Drag NookNote.app to the Applications folder
2. Right-click NookNote.app and select "Open" (first time only)
3. Click "Open" when macOS asks for confirmation
4. Configure your GitHub repository and access token

For help and support, visit:
https://github.com/taizo-pro/nook-note

Thank you for using NookNote!
EOF

# Create the DMG using hdiutil
echo "💿 Creating DMG file..."
mkdir -p "$DMG_DIR"

# Calculate size needed
SIZE=$(du -sm "$TEMP_DMG_DIR" | cut -f1)
SIZE=$((SIZE + 50)) # Add 50MB buffer

# Create temporary DMG
TEMP_DMG="$DMG_DIR/temp.dmg"
hdiutil create -size ${SIZE}m -fs HFS+ -volname "$APP_NAME" "$TEMP_DMG"

# Mount temporary DMG
MOUNT_DIR=$(hdiutil attach "$TEMP_DMG" | grep -E '^/dev/' | sed 's/^[^[:space:]]*[[:space:]]*[^[:space:]]*[[:space:]]*//')

# Copy contents
cp -r "$TEMP_DMG_DIR"/* "$MOUNT_DIR/"

# Unmount
hdiutil detach "$MOUNT_DIR"

# Convert to final DMG
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_DIR/$FINAL_DMG_NAME"
rm "$TEMP_DMG"

# Clean up temporary directory
rm -rf "$TEMP_DMG_DIR"

# Get file size
DMG_SIZE=$(du -h "$DMG_DIR/$FINAL_DMG_NAME" | cut -f1)

echo ""
echo -e "${GREEN}✅ DMG creation completed successfully!${NC}"
echo ""
echo "📊 Build Summary:"
echo "  App Bundle: $APP_BUNDLE"
echo "  DMG File: $DMG_DIR/$FINAL_DMG_NAME"
echo "  DMG Size: $DMG_SIZE"
echo ""
echo "🚀 Distribution Instructions:"
echo "  1. Upload $DMG_DIR/$FINAL_DMG_NAME to GitHub Releases"
echo "  2. Include installation instructions in release notes"
echo "  3. Tag the release with semantic version (e.g., v1.0.0)"
echo ""
echo -e "${YELLOW}⚠️  Important Security Note:${NC}"
echo "  This app uses a self-signed certificate. Users will see a security warning"
echo "  on first launch. Include clear instructions to right-click and select 'Open'."
echo ""
echo "🎉 Ready for distribution!"