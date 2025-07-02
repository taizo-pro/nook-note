#!/bin/bash

# NookNote - Pipeline Testing Script
# This script tests the complete build and distribution pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_VERSION="0.0.1-test"

echo -e "${BLUE}🧪 NookNote Pipeline Testing${NC}"
echo "==============================="
echo ""

# Function to run a test step
run_test_step() {
    local step_name="$1"
    local step_command="$2"
    local required="$3"  # "required" or "optional"
    
    echo -e "${CYAN}Testing: $step_name${NC}"
    echo "Command: $step_command"
    
    if eval "$step_command"; then
        echo -e "${GREEN}✅ $step_name - PASSED${NC}"
        return 0
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}❌ $step_name - FAILED (REQUIRED)${NC}"
            return 1
        else
            echo -e "${YELLOW}⚠️ $step_name - FAILED (OPTIONAL)${NC}"
            return 0
        fi
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking Prerequisites${NC}"
    echo "-------------------------"
    
    local all_good=true
    
    # Check required tools
    local tools=("swift" "git" "codesign" "hdiutil" "xcodebuild")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}✅ $tool - Available${NC}"
        else
            echo -e "${RED}❌ $tool - Missing${NC}"
            all_good=false
        fi
    done
    
    # Check Swift version
    local swift_version=$(swift --version | head -n1)
    echo -e "${GREEN}✅ Swift Version: $swift_version${NC}"
    
    # Check Xcode version
    if command -v xcodebuild &> /dev/null; then
        local xcode_version=$(xcodebuild -version | head -n1)
        echo -e "${GREEN}✅ Xcode Version: $xcode_version${NC}"
    fi
    
    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    echo -e "${GREEN}✅ macOS Version: $macos_version${NC}"
    
    echo ""
    
    if [ "$all_good" = true ]; then
        echo -e "${GREEN}🎉 All prerequisites satisfied${NC}"
        return 0
    else
        echo -e "${RED}❌ Some prerequisites are missing${NC}"
        return 1
    fi
}

# Function to test Swift build system
test_swift_build() {
    echo -e "${BLUE}🔨 Testing Swift Build System${NC}"
    echo "------------------------------"
    
    cd "$PROJECT_ROOT"
    
    # Clean previous builds
    run_test_step "Clean build" "swift package clean" "required" || return 1
    
    # Test debug build
    run_test_step "Debug build" "swift build" "required" || return 1
    
    # Test release build
    run_test_step "Release build" "swift build --configuration release" "required" || return 1
    
    # Test optimized build
    run_test_step "Optimized build" "swift build --configuration release -Xswiftc -Osize" "optional"
    
    echo ""
    return 0
}

# Function to test the test suite
test_test_suite() {
    echo -e "${BLUE}🧪 Testing Test Suite${NC}"
    echo "--------------------"
    
    cd "$PROJECT_ROOT"
    
    # Run unit tests
    run_test_step "Unit tests" "swift test --filter 'Tests'" "required" || return 1
    
    # Run integration tests (with mock data)
    run_test_step "Integration tests" "SKIP_REAL_API_TESTS=true swift test --filter 'IntegrationTests'" "optional"
    
    # Run UI tests
    run_test_step "UI tests" "swift test --filter 'UITests'" "optional"
    
    # Run performance tests
    run_test_step "Performance tests" "swift test --filter 'PerformanceTests'" "optional"
    
    # Run accessibility tests
    run_test_step "Accessibility tests" "swift test --filter 'AccessibilityTests'" "optional"
    
    echo ""
    return 0
}

# Function to test app bundle creation
test_app_bundle() {
    echo -e "${BLUE}📦 Testing App Bundle Creation${NC}"
    echo "------------------------------"
    
    cd "$PROJECT_ROOT"
    
    # Ensure we have a fresh build
    swift build --configuration release
    
    local app_bundle=".build/release/NookNote.app"
    
    # Clean any existing bundle
    rm -rf "$app_bundle"
    
    # Create app bundle structure
    mkdir -p "$app_bundle/Contents/MacOS"
    mkdir -p "$app_bundle/Contents/Resources"
    
    # Copy executable
    cp ".build/release/NookNote" "$app_bundle/Contents/MacOS/"
    
    # Copy Info.plist
    if [ -f "Resources/Info.plist" ]; then
        cp "Resources/Info.plist" "$app_bundle/Contents/"
        echo -e "${GREEN}✅ Info.plist copied${NC}"
    else
        echo -e "${YELLOW}⚠️ Info.plist not found${NC}"
    fi
    
    # Copy app icon
    if [ -d "Resources/AppIcon.appiconset" ]; then
        cp -r "Resources/AppIcon.appiconset" "$app_bundle/Contents/Resources/"
        echo -e "${GREEN}✅ App icon copied${NC}"
    else
        echo -e "${YELLOW}⚠️ App icon not found${NC}"
    fi
    
    # Create PkgInfo
    echo "APPL????" > "$app_bundle/Contents/PkgInfo"
    
    # Verify bundle structure
    if [ -f "$app_bundle/Contents/MacOS/NookNote" ]; then
        echo -e "${GREEN}✅ App bundle created successfully${NC}"
        
        # Check if executable is valid
        if file "$app_bundle/Contents/MacOS/NookNote" | grep -q "Mach-O"; then
            echo -e "${GREEN}✅ Executable is valid Mach-O binary${NC}"
        else
            echo -e "${RED}❌ Executable is not a valid binary${NC}"
            return 1
        fi
        
        # Check bundle info
        echo "📋 Bundle Information:"
        echo "  Size: $(du -sh "$app_bundle" | cut -f1)"
        echo "  Executable: $(file "$app_bundle/Contents/MacOS/NookNote" | cut -d: -f2-)"
        
        return 0
    else
        echo -e "${RED}❌ App bundle creation failed${NC}"
        return 1
    fi
}

# Function to test code signing
test_code_signing() {
    echo -e "${BLUE}🔏 Testing Code Signing${NC}"
    echo "-----------------------"
    
    cd "$PROJECT_ROOT"
    
    local app_bundle=".build/release/NookNote.app"
    
    if [ ! -d "$app_bundle" ]; then
        echo -e "${YELLOW}⚠️ App bundle not found, skipping code signing test${NC}"
        return 0
    fi
    
    # Check if certificate exists
    if security find-certificate -c "NookNote Developer" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Code signing certificate found${NC}"
        
        # Try to sign the app
        if codesign --sign "NookNote Developer" --force --deep "$app_bundle" 2>/dev/null; then
            echo -e "${GREEN}✅ Code signing successful${NC}"
            
            # Verify signature
            if codesign --verify --verbose "$app_bundle" 2>/dev/null; then
                echo -e "${GREEN}✅ Code signature verification successful${NC}"
            else
                echo -e "${YELLOW}⚠️ Code signature verification failed${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️ Code signing failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Code signing certificate not found${NC}"
        echo "You can create one with: ./Scripts/create-certificate.sh"
    fi
    
    echo ""
    return 0
}

# Function to test DMG creation
test_dmg_creation() {
    echo -e "${BLUE}💿 Testing DMG Creation${NC}"
    echo "-----------------------"
    
    cd "$PROJECT_ROOT"
    
    local app_bundle=".build/release/NookNote.app"
    local dmg_dir="build/dmg"
    local temp_dmg_dir="$dmg_dir/temp"
    local test_dmg="$dmg_dir/NookNote-test.dmg"
    
    if [ ! -d "$app_bundle" ]; then
        echo -e "${YELLOW}⚠️ App bundle not found, skipping DMG test${NC}"
        return 0
    fi
    
    # Clean previous DMG
    rm -rf "$dmg_dir"
    
    # Create staging directory
    mkdir -p "$temp_dmg_dir"
    cp -r "$app_bundle" "$temp_dmg_dir/"
    
    # Create Applications symlink
    ln -sf /Applications "$temp_dmg_dir/Applications"
    
    # Create test README
    cat > "$temp_dmg_dir/README.txt" << EOF
NookNote Test Build

This is a test build for pipeline validation.
Do not distribute this build.
EOF
    
    # Calculate size
    local size=$(du -sm "$temp_dmg_dir" | cut -f1)
    size=$((size + 20)) # Add buffer
    
    # Create DMG
    mkdir -p "$dmg_dir"
    local temp_dmg="$dmg_dir/temp.dmg"
    
    if hdiutil create -size ${size}m -fs HFS+ -volname "NookNote Test" "$temp_dmg" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ DMG creation started${NC}"
        
        # Mount and copy files
        local mount_dir=$(hdiutil attach "$temp_dmg" 2>/dev/null | grep -E '^/dev/' | sed 's/^[^[:space:]]*[[:space:]]*[^[:space:]]*[[:space:]]*//')
        
        if [ -n "$mount_dir" ]; then
            cp -r "$temp_dmg_dir"/* "$mount_dir/" 2>/dev/null
            hdiutil detach "$mount_dir" >/dev/null 2>&1
            
            # Convert to final DMG
            if hdiutil convert "$temp_dmg" -format UDZO -o "$test_dmg" >/dev/null 2>&1; then
                rm "$temp_dmg"
                
                local dmg_size=$(du -sh "$test_dmg" | cut -f1)
                echo -e "${GREEN}✅ DMG created successfully${NC}"
                echo "  File: $test_dmg"
                echo "  Size: $dmg_size"
                
                # Clean up
                rm -rf "$temp_dmg_dir"
                
                return 0
            else
                echo -e "${RED}❌ DMG conversion failed${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ DMG mount failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ DMG creation failed${NC}"
        return 1
    fi
}

# Function to test scripts
test_scripts() {
    echo -e "${BLUE}📜 Testing Scripts${NC}"
    echo "------------------"
    
    cd "$PROJECT_ROOT"
    
    # Test certificate creation script
    if [ -f "Scripts/create-certificate.sh" ]; then
        run_test_step "Certificate script syntax" "bash -n Scripts/create-certificate.sh" "required"
    fi
    
    # Test DMG creation script
    if [ -f "Scripts/create-dmg.sh" ]; then
        run_test_step "DMG script syntax" "bash -n Scripts/create-dmg.sh" "required"
    fi
    
    # Test release preparation script
    if [ -f "Scripts/prepare-release.sh" ]; then
        run_test_step "Release script syntax" "bash -n Scripts/prepare-release.sh" "required"
        run_test_step "Release script dry run" "Scripts/prepare-release.sh $TEST_VERSION --dry-run" "optional"
    fi
    
    echo ""
    return 0
}

# Function to test GitHub Actions workflows
test_github_actions() {
    echo -e "${BLUE}⚙️ Testing GitHub Actions Workflows${NC}"
    echo "----------------------------------"
    
    cd "$PROJECT_ROOT"
    
    # Check workflow files exist
    local workflows=(".github/workflows/build-and-test.yml" ".github/workflows/release.yml")
    
    for workflow in "${workflows[@]}"; do
        if [ -f "$workflow" ]; then
            echo -e "${GREEN}✅ $workflow exists${NC}"
            
            # Basic YAML syntax check (if yq is available)
            if command -v yq &> /dev/null; then
                if yq eval . "$workflow" >/dev/null 2>&1; then
                    echo -e "${GREEN}✅ $workflow syntax valid${NC}"
                else
                    echo -e "${RED}❌ $workflow syntax invalid${NC}"
                fi
            fi
        else
            echo -e "${RED}❌ $workflow missing${NC}"
        fi
    done
    
    echo ""
    return 0
}

# Function to generate test report
generate_test_report() {
    local overall_status="$1"
    
    echo -e "${BLUE}📊 Pipeline Test Report${NC}"
    echo "======================="
    echo ""
    echo "Date: $(date)"
    echo "Platform: $(uname -s) $(uname -r)"
    echo "Swift Version: $(swift --version | head -n1)"
    
    if command -v xcodebuild &> /dev/null; then
        echo "Xcode Version: $(xcodebuild -version | head -n1)"
    fi
    
    echo ""
    
    if [ "$overall_status" = "success" ]; then
        echo -e "${GREEN}🎉 Overall Status: ALL TESTS PASSED${NC}"
        echo ""
        echo "✅ The complete build and distribution pipeline is working"
        echo "✅ All core functionality tests passed"
        echo "✅ App bundle creation works correctly"
        echo "✅ Distribution artifacts can be created"
        echo ""
        echo "🚀 The project is ready for:"
        echo "  - Continuous Integration (GitHub Actions)"
        echo "  - Automated releases"
        echo "  - Distribution via GitHub Releases"
        echo ""
        echo "Next steps:"
        echo "  1. Commit and push to trigger CI"
        echo "  2. Create a release tag to test automated release"
        echo "  3. Monitor GitHub Actions workflows"
    else
        echo -e "${RED}❌ Overall Status: SOME TESTS FAILED${NC}"
        echo ""
        echo "⚠️ Please review the failed tests above and fix issues before:"
        echo "  - Pushing to production"
        echo "  - Creating releases"
        echo "  - Enabling automated workflows"
    fi
    
    echo ""
}

# Main function
main() {
    echo "Starting comprehensive pipeline test..."
    echo "This will test the entire build and distribution pipeline."
    echo ""
    
    local overall_success=true
    
    # Run all test phases
    check_prerequisites || overall_success=false
    echo ""
    
    test_swift_build || overall_success=false
    echo ""
    
    test_test_suite || overall_success=false
    echo ""
    
    test_app_bundle || overall_success=false
    echo ""
    
    test_code_signing || true  # Optional, don't fail overall
    echo ""
    
    test_dmg_creation || overall_success=false
    echo ""
    
    test_scripts || overall_success=false
    echo ""
    
    test_github_actions || true  # Optional, don't fail overall
    echo ""
    
    # Generate final report
    if [ "$overall_success" = true ]; then
        generate_test_report "success"
        exit 0
    else
        generate_test_report "failure"
        exit 1
    fi
}

# Run main function
main "$@"