# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS application project called "discuss-bar" that creates a menubar application for easy access to GitHub Discussions. The goal is to allow users to post comments to GitHub Discussions directly from a macOS menubar app, streamlining the note-taking and work logging workflow.

## Project Goals

- Create a macOS menubar application that provides quick access to GitHub Discussions
- Enable thread-style commenting similar to GitHub Discussions interface
- Support direct posting to GitHub (comments should be submitted to the actual GitHub repository)
- Custom SwiftUI interface optimized for quick note-taking and work logging
- Focus on menubar integration for instant access
- Free distribution via GitHub Releases

## Technology Stack (Decided)

**Frontend:**
- Swift 5.9+ with SwiftUI
- Combine for async operations
- NSStatusItem + NSPopover for menubar interface

**Backend/API:**
- GitHub GraphQL API v4 and REST API v3
- Personal Access Token authentication
- URLSession for networking

**Data Storage:**
- UserDefaults for app settings
- Keychain Services for secure token storage

**Distribution:**
- GitHub Releases with .dmg packages
- Self-signed certificates (free distribution)

## Current State

The project has completed planning phase with:
- Requirements analysis (概要.md)
- Technology decision (ADR-001-technology-stack.md)
- Detailed implementation plan (implementation-plan.md)
- 8-phase development roadmap (8-12 weeks)

## Development Setup

Required environment:
- macOS 12.0 (Monterey) or later
- Xcode 15+
- Swift Package Manager
- GitHub Personal Access Token with repo and discussions permissions

## Architecture

**App Structure:**
- MenuBar App (NSStatusItem-based)
- SwiftUI Views with MVVM pattern
- Service layer for GitHub API communication
- Keychain wrapper for secure storage

**Key Components:**
- StatusBarController: Manages menubar presence
- DiscussionsService: GitHub API integration
- SettingsManager: Configuration and token management
- Models: Discussion, Comment, User data structures

## Common Development Commands

When the project structure is established:
```bash
# Build the project
xcodebuild -scheme discuss-bar build

# Run tests
xcodebuild -scheme discuss-bar test

# Create release build
xcodebuild -scheme discuss-bar -configuration Release build

# Create DMG (after implementing packaging)
./scripts/create-dmg.sh
```

## Project Structure (Future)

```
discuss-bar/
├── Sources/
│   ├── App/
│   ├── Models/
│   ├── Views/
│   ├── Services/
│   └── Utils/
├── Tests/
├── Resources/
└── Scripts/
```