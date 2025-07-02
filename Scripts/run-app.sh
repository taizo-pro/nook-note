#!/bin/bash

# NookNote Runner Script
# This script properly builds and runs NookNote as a macOS app

set -e

echo "🚀 Building NookNote..."

# Clean build directory
rm -rf .build

# Generate Xcode project for proper macOS app bundle
echo "📦 Generating Xcode project..."
swift package generate-xcodeproj

echo "🔨 Building with Xcode..."
xcodebuild -project NookNote.xcodeproj -scheme NookNote -configuration Release build

echo "🎯 Running NookNote..."
# Find the built executable
BUILT_APP=$(find .build -name "NookNote" -type f -perm +111 | head -1)

if [ -z "$BUILT_APP" ]; then
    echo "❌ Failed to find built executable"
    exit 1
fi

echo "✅ Starting NookNote from: $BUILT_APP"
"$BUILT_APP"