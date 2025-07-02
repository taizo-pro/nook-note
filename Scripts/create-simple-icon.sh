#!/bin/bash

# Simple icon creator using basic macOS tools
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/../Resources"
APPICON_DIR="$RESOURCES_DIR/AppIcon.appiconset"

# Create a simple blue square with rounded corners as base icon
BASE_ICON="$RESOURCES_DIR/icon_1024x1024.png"

# For now, create placeholder files that can be replaced later
echo "Creating placeholder icon files..."

# Create base icon using built-in tools
cat > "$RESOURCES_DIR/create_base_icon.applescript" << 'APPLESCRIPT_EOF'
#!/usr/bin/osascript

-- Create a simple blue square icon
tell application "Image Events"
    launch
    
    -- Create new image
    set newImage to make new image with properties {name:"NookNote Icon", dimensions:{1024, 1024}}
    
    -- Fill with blue color (this is simplified - actual implementation would need more setup)
    -- For now, we'll create an empty image that can be replaced
    
    -- Save the image
    save newImage as PNG in POSIX file "/Users/taizo-pro/NookNote/Resources/icon_1024x1024.png"
    
    close newImage
end tell
APPLESCRIPT_EOF

# Instead of complex image creation, let's create a simple text-based approach
echo "Creating simple icon representation..."

# Create a basic blue background using available tools
if command -v sips &> /dev/null; then
    # Create a simple colored image
    sips -c 1024 1024 --setProperty format png /System/Library/CoreServices/DefaultDesktop.jpg --out "$BASE_ICON" 2>/dev/null || {
        echo "Creating minimal placeholder..."
        # Create an empty 1024x1024 PNG (minimal valid PNG)
        base64 -d > "$BASE_ICON" << 'BASE64_EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChAI/hRNuLQAAAABJRU5ErkJggg==
BASE64_EOF
        
        # Resize to 1024x1024
        sips -z 1024 1024 "$BASE_ICON" --out "$BASE_ICON"
    }
else
    echo "Creating text placeholder..."
    # Create a simple text file that indicates an icon is needed
    cat > "$BASE_ICON.txt" << 'PLACEHOLDER_EOF'
NookNote App Icon Placeholder

This file represents where the NookNote app icon should be placed.

Required:
- 1024x1024 PNG file
- Blue theme (#007AFF)
- Speech bubble or discussion-related design
- Clean, modern appearance suitable for macOS menubar

Replace this placeholder with actual icon file:
/Users/taizo-pro/NookNote/Resources/icon_1024x1024.png
PLACEHOLDER_EOF
fi

# Create all required icon sizes as placeholders
declare -a sizes=(
    "16:icon_16x16.png"
    "32:icon_16x16@2x.png" 
    "32:icon_32x32.png"
    "64:icon_32x32@2x.png"
    "128:icon_128x128.png"
    "256:icon_128x128@2x.png"
    "256:icon_256x256.png"
    "512:icon_256x256@2x.png"
    "512:icon_512x512.png"
    "1024:icon_512x512@2x.png"
)

echo "Creating icon placeholders..."

for size_file in "${sizes[@]}"; do
    IFS=':' read -r size filename <<< "$size_file"
    output_path="$APPICON_DIR/$filename"
    
    # Create a minimal 1x1 PNG and resize it
    base64 -d > "$output_path" << 'MINI_PNG_EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==
MINI_PNG_EOF
    
    if command -v sips &> /dev/null; then
        sips -z "$size" "$size" "$output_path" --out "$output_path" 2>/dev/null
    fi
    
    echo "Created placeholder: $filename (${size}x${size})"
done

echo ""
echo "Icon placeholders created successfully!"
echo "Location: $APPICON_DIR"
echo ""
echo "IMPORTANT: Replace placeholder files with actual icon designs"
echo "Base icon location: $BASE_ICON"
echo ""
echo "Design requirements:"
echo "- Blue theme (#007AFF) to match app UI"
echo "- Speech bubble or discussion icon theme"
echo "- Clean, minimal design suitable for menubar"
echo "- Professional appearance for GitHub Discussions client"

# Clean up temporary files
rm -f "$RESOURCES_DIR/create_base_icon.applescript"