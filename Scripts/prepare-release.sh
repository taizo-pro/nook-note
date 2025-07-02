#!/bin/bash

# NookNote - Release Preparation Script
# This script prepares a new release by updating version numbers and creating tags

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INFO_PLIST="$PROJECT_ROOT/Resources/Info.plist"
PACKAGE_SWIFT="$PROJECT_ROOT/Package.swift"

echo -e "${BLUE}🚀 NookNote Release Preparation${NC}"
echo "=================================="

# Function to show usage
show_usage() {
    echo "Usage: $0 <version> [options]"
    echo ""
    echo "Arguments:"
    echo "  version     Version number (e.g., 1.0.0, 1.2.3-beta1)"
    echo ""
    echo "Options:"
    echo "  --dry-run   Show what would be done without making changes"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 1.0.0                 # Release version 1.0.0"
    echo "  $0 1.1.0-beta1           # Beta release"
    echo "  $0 2.0.0 --dry-run       # Preview changes without applying"
    echo ""
}

# Function to validate version format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        echo -e "${RED}❌ Invalid version format: $version${NC}"
        echo "Version must follow semantic versioning (e.g., 1.0.0, 1.2.3-beta1)"
        exit 1
    fi
}

# Function to check if git is clean
check_git_status() {
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${RED}❌ Git working directory is not clean${NC}"
        echo "Please commit or stash your changes before preparing a release"
        git status --short
        exit 1
    fi
}

# Function to check if version already exists
check_version_exists() {
    local version="$1"
    local tag="v$version"
    
    if git tag | grep -q "^$tag$"; then
        echo -e "${RED}❌ Version $version already exists as git tag $tag${NC}"
        echo "Use a different version number or delete the existing tag:"
        echo "  git tag -d $tag"
        exit 1
    fi
}

# Function to update Info.plist
update_info_plist() {
    local version="$1"
    local dry_run="$2"
    
    if [ ! -f "$INFO_PLIST" ]; then
        echo -e "${YELLOW}⚠️ Warning: Info.plist not found at $INFO_PLIST${NC}"
        return
    fi
    
    echo "📝 Updating Info.plist..."
    
    if [ "$dry_run" = "true" ]; then
        echo "  Would update CFBundleShortVersionString to: $version"
        echo "  Would update CFBundleVersion to: $version"
    else
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$INFO_PLIST"
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $version" "$INFO_PLIST"
        echo -e "  ${GREEN}✅ Updated CFBundleShortVersionString and CFBundleVersion${NC}"
    fi
}

# Function to run tests
run_tests() {
    local dry_run="$1"
    
    echo "🧪 Running tests..."
    
    if [ "$dry_run" = "true" ]; then
        echo "  Would run: swift test"
        return
    fi
    
    if swift test; then
        echo -e "  ${GREEN}✅ All tests passed${NC}"
    else
        echo -e "  ${RED}❌ Tests failed${NC}"
        echo "Fix failing tests before creating a release"
        exit 1
    fi
}

# Function to build release
build_release() {
    local dry_run="$1"
    
    echo "🔨 Building release..."
    
    if [ "$dry_run" = "true" ]; then
        echo "  Would run: swift build --configuration release"
        return
    fi
    
    if swift build --configuration release; then
        echo -e "  ${GREEN}✅ Release build successful${NC}"
    else
        echo -e "  ${RED}❌ Release build failed${NC}"
        exit 1
    fi
}

# Function to create changelog entry
create_changelog_entry() {
    local version="$1"
    local dry_run="$2"
    
    local changelog_file="$PROJECT_ROOT/CHANGELOG.md"
    local temp_changelog=$(mktemp)
    
    echo "📝 Creating changelog entry..."
    
    # Create changelog if it doesn't exist
    if [ ! -f "$changelog_file" ]; then
        if [ "$dry_run" = "true" ]; then
            echo "  Would create new CHANGELOG.md"
            return
        fi
        
        cat > "$changelog_file" << EOF
# Changelog

All notable changes to NookNote will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

EOF
    fi
    
    if [ "$dry_run" = "true" ]; then
        echo "  Would add entry for version $version to CHANGELOG.md"
        return
    fi
    
    # Get current date
    local current_date=$(date +%Y-%m-%d)
    
    # Create new changelog entry
    cat > "$temp_changelog" << EOF
# Changelog

All notable changes to NookNote will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [$version] - $current_date

### Added
- New features and enhancements

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes and improvements

### Security
- Security improvements

EOF
    
    # Append existing changelog (skip the header)
    if [ -f "$changelog_file" ]; then
        tail -n +7 "$changelog_file" >> "$temp_changelog"
    fi
    
    mv "$temp_changelog" "$changelog_file"
    echo -e "  ${GREEN}✅ Changelog entry created${NC}"
    echo -e "  ${YELLOW}⚠️ Please edit CHANGELOG.md to add specific changes${NC}"
}

# Function to commit changes
commit_changes() {
    local version="$1"
    local dry_run="$2"
    
    echo "📦 Committing version changes..."
    
    if [ "$dry_run" = "true" ]; then
        echo "  Would run: git add -A"
        echo "  Would run: git commit -m \"chore: prepare release v$version\""
        return
    fi
    
    git add -A
    git commit -m "chore: prepare release v$version

- Update version to $version in Info.plist
- Add changelog entry for v$version
- Ready for release"
    
    echo -e "  ${GREEN}✅ Changes committed${NC}"
}

# Function to create git tag
create_git_tag() {
    local version="$1"
    local dry_run="$2"
    local tag="v$version"
    
    echo "🏷️ Creating git tag..."
    
    if [ "$dry_run" = "true" ]; then
        echo "  Would run: git tag -a $tag -m \"Release $version\""
        return
    fi
    
    git tag -a "$tag" -m "Release $version

NookNote $version - GitHub Discussions MenuBar App

This release includes:
- Complete GitHub Discussions integration
- MenuBar interface with modern SwiftUI
- Keyboard shortcuts and accessibility support
- Real-time updates and notifications

For installation instructions and changelog, see:
https://github.com/taizo-pro/nook-note/releases/tag/$tag"
    
    echo -e "  ${GREEN}✅ Git tag $tag created${NC}"
}

# Function to show next steps
show_next_steps() {
    local version="$1"
    local dry_run="$2"
    local tag="v$version"
    
    echo ""
    echo -e "${GREEN}🎉 Release preparation completed!${NC}"
    echo ""
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}This was a dry run. No changes were made.${NC}"
        echo ""
        echo "To actually prepare the release, run:"
        echo "  $0 $version"
        echo ""
        return
    fi
    
    echo "📋 Next steps:"
    echo ""
    echo "1. Review the changes:"
    echo "   git log --oneline -3"
    echo "   git show $tag"
    echo ""
    echo "2. Edit CHANGELOG.md to add specific changes"
    echo ""
    echo "3. Push the changes and tag:"
    echo "   git push origin main"
    echo "   git push origin $tag"
    echo ""
    echo "4. The GitHub Actions workflow will automatically:"
    echo "   - Build the release"
    echo "   - Run all tests"
    echo "   - Create DMG file"
    echo "   - Create GitHub Release with assets"
    echo ""
    echo "5. Monitor the release workflow:"
    echo "   https://github.com/taizo-pro/nook-note/actions"
    echo ""
    echo -e "${BLUE}🚀 Release $version is ready to ship!${NC}"
}

# Main script logic
main() {
    local version=""
    local dry_run="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run="true"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$version" ]; then
                    version="$1"
                else
                    echo -e "${RED}❌ Multiple version arguments provided${NC}"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if version was provided
    if [ -z "$version" ]; then
        echo -e "${RED}❌ Version argument is required${NC}"
        show_usage
        exit 1
    fi
    
    # Validate inputs
    validate_version "$version"
    
    if [ "$dry_run" = "false" ]; then
        check_git_status
        check_version_exists "$version"
    fi
    
    # Show what we're doing
    echo "📋 Release Summary:"
    echo "  Version: $version"
    echo "  Tag: v$version"
    echo "  Dry run: $dry_run"
    echo ""
    
    if [ "$dry_run" = "false" ]; then
        read -p "Continue with release preparation? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Release preparation cancelled"
            exit 0
        fi
    fi
    
    # Execute preparation steps
    run_tests "$dry_run"
    build_release "$dry_run"
    update_info_plist "$version" "$dry_run"
    create_changelog_entry "$version" "$dry_run"
    
    if [ "$dry_run" = "false" ]; then
        commit_changes "$version" "$dry_run"
        create_git_tag "$version" "$dry_run"
    fi
    
    show_next_steps "$version" "$dry_run"
}

# Run main function with all arguments
main "$@"