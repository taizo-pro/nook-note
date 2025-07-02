#!/bin/bash

# NookNote DMG Creation Script
# Creates a distributable DMG file for the signed app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
RELEASE_DIR="$PROJECT_DIR/build/Release"
APP_NAME="NookNote"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
VERSION="1.0.0"
DMG_NAME="$APP_NAME-$VERSION"
TEMP_DMG="$RELEASE_DIR/temp_$DMG_NAME.dmg"
FINAL_DMG="$RELEASE_DIR/$DMG_NAME.dmg"

echo "📀 Creating DMG for NookNote v$VERSION"
echo "======================================"

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: App bundle not found at $APP_BUNDLE"
    echo "   Run './Scripts/build-app.sh' and './Scripts/sign-app.sh' first"
    exit 1
fi

# Clean up previous DMG files
echo "🧹 Cleaning up previous DMG files..."
rm -f "$TEMP_DMG" "$FINAL_DMG"

# Check for create-dmg tool
if command -v create-dmg &> /dev/null; then
    echo "📦 Using create-dmg tool"
    
    # Create DMG using create-dmg
    create-dmg \
        --volname "$APP_NAME $VERSION" \
        --volicon "$APP_BUNDLE/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 175 190 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 425 190 \
        --skip-jenkins \
        "$FINAL_DMG" \
        "$APP_BUNDLE"
        
elif command -v hdiutil &> /dev/null; then
    echo "📦 Using hdiutil (macOS built-in)"
    
    # Calculate size needed (app size + 50MB buffer)
    APP_SIZE=$(du -sm "$APP_BUNDLE" | cut -f1)
    DMG_SIZE=$((APP_SIZE + 50))
    
    # Create temporary DMG
    echo "   Creating temporary DMG (${DMG_SIZE}MB)..."
    hdiutil create -srcfolder "$APP_BUNDLE" -volname "$APP_NAME $VERSION" -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "$TEMP_DMG"
    
    # Mount the temporary DMG
    echo "   Mounting temporary DMG..."
    MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | \
        egrep '^/dev/' | sed 1q | awk '{print $3}')
    
    # Configure the DMG appearance
    echo "   Configuring DMG appearance..."
    
    # Create Applications symlink
    ln -sf /Applications "$MOUNT_DIR/Applications"
    
    # Set background and icon positions (if possible)
    if command -v osascript &> /dev/null; then
        osascript << EOF
tell application "Finder"
    tell disk "$APP_NAME $VERSION"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        set position of item "$APP_NAME.app" of container window to {175, 190}
        set position of item "Applications" of container window to {425, 190}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF
    fi
    
    # Set custom icon if available
    if [ -f "$APP_BUNDLE/Contents/Resources/AppIcon.icns" ]; then
        cp "$APP_BUNDLE/Contents/Resources/AppIcon.icns" "$MOUNT_DIR/.VolumeIcon.icns"
        SetFile -c icnC "$MOUNT_DIR/.VolumeIcon.icns"
        SetFile -a C "$MOUNT_DIR"
    fi
    
    # Unmount the temporary DMG
    echo "   Unmounting temporary DMG..."
    hdiutil detach "$MOUNT_DIR"
    
    # Convert to compressed, read-only DMG
    echo "   Creating final compressed DMG..."
    hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"
    
    # Clean up temporary DMG
    rm -f "$TEMP_DMG"
    
else
    echo "❌ Error: No DMG creation tools available"
    echo "   Please install create-dmg: brew install create-dmg"
    echo "   Or ensure hdiutil is available (should be on macOS)"
    exit 1
fi

# Verify the DMG
echo "🔍 Verifying DMG..."
if [ -f "$FINAL_DMG" ]; then
    DMG_SIZE=$(du -h "$FINAL_DMG" | cut -f1)
    echo "✅ DMG created successfully!"
    echo "   File: $FINAL_DMG"
    echo "   Size: $DMG_SIZE"
    
    # Test mounting the DMG
    echo "   Testing DMG mount..."
    if hdiutil attach -readonly -noverify "$FINAL_DMG" &>/dev/null; then
        MOUNT_POINT=$(hdiutil info | grep "$APP_NAME $VERSION" | awk '{print $3}')
        if [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT/$APP_NAME.app" ]; then
            echo "✅ DMG mounts correctly and contains app"
            hdiutil detach "$MOUNT_POINT" &>/dev/null
        else
            echo "⚠️  DMG mount test inconclusive"
        fi
    else
        echo "⚠️  Could not test DMG mount"
    fi
    
else
    echo "❌ Error: DMG creation failed"
    exit 1
fi

echo ""
echo "🎉 DMG Creation Complete!"
echo ""
echo "📋 Distribution Information:"
echo "   DMG File: $FINAL_DMG"
echo "   App Name: $APP_NAME"
echo "   Version: $VERSION"
echo "   Size: $DMG_SIZE"
echo ""
echo "📤 Ready for distribution:"
echo "1. Upload to GitHub Releases"
echo "2. Share download link with users"
echo "3. Provide installation instructions"
echo ""
echo "⚠️  Installation Notes for Users:"
echo "• macOS will show security warnings for unsigned apps"
echo "• Users should right-click DMG and select 'Open'"
echo "• After mounting, drag app to Applications folder"
echo "• Right-click app and select 'Open' on first launch"
echo "• Users may need to allow app in System Preferences > Security"