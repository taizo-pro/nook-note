#!/bin/bash

# NookNote Icon Generator
# Generates app icons from a base 1024x1024 icon using sips

# Colors and styling for NookNote
# - Primary: Discussion bubble theme
# - Colors: Blue (#007AFF), White, Gray
# - Style: Clean, modern, menubar-friendly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/../Resources"
APPICON_DIR="$RESOURCES_DIR/AppIcon.appiconset"

# Create base icon if it doesn't exist
BASE_ICON="$RESOURCES_DIR/icon_1024x1024.png"

if [ ! -f "$BASE_ICON" ]; then
    echo "Creating base icon..."
    
    # Create a basic icon using Python/PIL
    cat > "$RESOURCES_DIR/create_icon.py" << 'PYTHON_EOF'
import os
from PIL import Image, ImageDraw, ImageFont

def create_nook_note_icon(size=1024):
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    primary_blue = (0, 122, 255, 255)  # #007AFF
    secondary_blue = (52, 152, 255, 255)  # Lighter blue
    white = (255, 255, 255, 255)
    
    # Draw main circle background
    margin = size * 0.05
    circle_size = size - (margin * 2)
    draw.ellipse([margin, margin, margin + circle_size, margin + circle_size], 
                 fill=primary_blue, outline=None)
    
    # Draw speech bubble design
    bubble_margin = size * 0.2
    bubble_size = size - (bubble_margin * 2)
    
    # Main bubble
    draw.rounded_rectangle([bubble_margin, bubble_margin, 
                           bubble_margin + bubble_size * 0.7, 
                           bubble_margin + bubble_size * 0.6], 
                          radius=size * 0.08, fill=white, outline=None)
    
    # Smaller bubble
    small_bubble_x = bubble_margin + bubble_size * 0.75
    small_bubble_y = bubble_margin + bubble_size * 0.65
    small_bubble_size = bubble_size * 0.25
    draw.ellipse([small_bubble_x, small_bubble_y, 
                  small_bubble_x + small_bubble_size, 
                  small_bubble_y + small_bubble_size], 
                 fill=secondary_blue, outline=None)
    
    # Add GitHub-style dots in main bubble
    dot_size = size * 0.02
    dot_y = bubble_margin + bubble_size * 0.3
    
    for i in range(3):
        dot_x = bubble_margin + bubble_size * (0.15 + i * 0.15)
        draw.ellipse([dot_x, dot_y, dot_x + dot_size, dot_y + dot_size], 
                     fill=primary_blue, outline=None)
    
    return img

# Generate the icon
icon = create_nook_note_icon(1024)
icon.save('$BASE_ICON', 'PNG')
print("Base icon created: $BASE_ICON")
PYTHON_EOF
        
    # Try to run Python script
    if command -v python3 &> /dev/null; then
        python3 "$RESOURCES_DIR/create_icon.py"
        rm "$RESOURCES_DIR/create_icon.py"
    else
        echo "Python3 not available. Creating simple placeholder icon."
        # Create a simple colored rectangle as absolute fallback
        if command -v convert &> /dev/null; then
            convert -size 1024x1024 xc:"#007AFF" "$BASE_ICON"
        else
            echo "No icon creation tools available. Please create $BASE_ICON manually."
            exit 1
        fi
    fi
fi

echo "Generating app icon sizes..."

# Required icon sizes for macOS apps
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

# Generate each size
for size_file in "${sizes[@]}"; do
    IFS=':' read -r size filename <<< "$size_file"
    output_path="$APPICON_DIR/$filename"
    
    echo "Generating $filename (${size}x${size})"
    
    if command -v sips &> /dev/null; then
        sips -z "$size" "$size" "$BASE_ICON" --out "$output_path"
    elif command -v convert &> /dev/null; then
        convert "$BASE_ICON" -resize "${size}x${size}" "$output_path"
    else
        echo "Warning: Neither sips nor ImageMagick available. Copying base icon."
        cp "$BASE_ICON" "$output_path"
    fi
done

echo "App icons generated successfully!"
echo "Location: $APPICON_DIR"
echo ""
echo "Icon files created:"
ls -la "$APPICON_DIR"/*.png 2>/dev/null || echo "No PNG files found"

# Verify Package.swift includes the icon
echo ""
echo "To use the icon, ensure your Package.swift includes:"
echo "resources: ["
echo "    .process(\"Resources\")"
echo "]"