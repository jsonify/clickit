# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClickIt is a native macOS auto-clicker application built with Swift Package Manager and SwiftUI. It provides precision clicking automation for macOS with advanced window targeting and global hotkey support.

**Key Features:**
- Native macOS SwiftUI application
- Universal binary support (Intel x64 + Apple Silicon)
- Sub-10ms click timing accuracy
- Background operation without requiring app focus
- Global hotkey controls (ESC key)
- Preset configuration system
- Visual feedback with overlay indicators

## Development Commands

### Building & Testing
```bash
# Build the project
swift build

# Run the application
swift run

# Run tests
swift test

# Build for release
swift build -c release
```

### Package Management
```bash
# Generate Xcode project (if needed)
swift package generate-xcodeproj

# Resolve dependencies
swift package resolve

# Clean build artifacts
swift package clean
```

## Architecture Overview

The project follows a modular architecture with clear separation of concerns:

### Core Structure
- **Sources/ClickIt/**: Main application code
  - **UI/**: SwiftUI views and components
    - **Views/**: Main application views (ContentView.swift)
    - **Components/**: Reusable UI components (planned)
  - **Core/**: Business logic modules (planned structure)
    - **Click/**: Click engine and timing logic
    - **Window/**: Window detection and targeting
    - **Permissions/**: macOS permissions handling
  - **Utils/**: Utilities and helpers
    - **Constants/**: App-wide constants (AppConstants.swift)
    - **Extensions/**: Swift extensions (planned)
  - **Resources/**: Assets and resource files

### Key Technical Components

**Required Frameworks:**
- **CoreGraphics**: Mouse event generation and window targeting
- **Carbon**: Global hotkey registration (ESC key)
- **ApplicationServices**: Window detection and management
- **SwiftUI**: User interface framework

**Core Implementation Areas:**
- Window targeting using `CGWindowListCopyWindowInfo`
- Background clicking with `CGEventCreateMouseEvent` and `CGEventPostToPid`
- Global hotkey handling for ESC key controls
- Precision timing system with CPS randomization
- Visual overlay system using `NSWindow` with `NSWindowLevel.floating`

## System Requirements

- **macOS Version**: 15.0 or later
- **Architecture**: Universal binary (Intel x64 + Apple Silicon)
- **Required Permissions**:
  - Accessibility (for mouse event simulation)
  - Screen Recording (for window detection and visual overlay)

## Current Implementation Status

The project is in early development with basic structure established:
- ✅ Swift Package Manager configuration
- ✅ Basic SwiftUI app structure
- ✅ Framework imports and constants
- ⏳ Core clicking functionality (planned)
- ⏳ Window targeting system (planned)
- ⏳ Permission management (planned)

## Development Guidelines

### Code Organization
- Follow the established modular structure
- Keep UI logic separate from business logic
- Use the existing constants system in `AppConstants.swift`
- Import required frameworks at the top of relevant files

### Performance Considerations
- Target sub-10ms click timing accuracy
- Maintain minimal CPU/memory footprint (<50MB RAM, <5% CPU at idle)
- Optimize for both Intel and Apple Silicon architectures

### macOS Integration
- Utilize native macOS APIs for all core functionality
- Handle required permissions gracefully
- Support background operation without app focus
- Implement proper window targeting for minimized applications

## Key Implementation Notes

**Window Targeting**: Use process ID rather than window focus to enable clicking on minimized/hidden windows

**Timing System**: Implement dynamic timer with CPS randomization: `random(baseCPS - variation, baseCPS + variation)`

**Visual Feedback**: Create transparent overlay windows that persist during operation

**Preset System**: Store configurations in UserDefaults with custom naming support

## Known Issues & Solutions

### Application Crashes and Debugging (July 2025)

During development of Issue #8 (Visual Feedback System), several critical stability issues were discovered and resolved:

#### 🔐 **Code Signing Issues**
**Problem**: App crashes after running `./scripts/sign-app.sh`
- **Root Cause**: Expired Apple Development certificate (expired June 2021)
- **Secondary Issue**: Original signing script ran `swift build` which overwrote universal release binary with debug binary
- **Solution**: 
  - Updated to use valid certificate: `Apple Development: [DEVELOPER_NAME] ([TEAM_ID])` (certificate must be valid)
  - Fixed signing script to preserve universal binary (removed `swift build` command)
  - Check certificate validity: `security find-certificate -c "CERT_NAME" -p | openssl x509 -text -noout | grep "Not After"`

#### ⚡ **Permission System Crashes**
**Problem**: App crashes when Accessibility permission is toggled ON in System Settings
- **Root Cause**: Concurrency issues in permission monitoring system
- **Specific Issues**:
  - `PermissionManager.updatePermissionStatus()` used `DispatchQueue.main.async` despite being on `@MainActor`
  - `PermissionStatusChecker` timers used `Task { @MainActor in ... }` creating race conditions
- **Solution**:
  - Removed redundant `DispatchQueue.main.async` in `updatePermissionStatus()`
  - Changed Timer callbacks to use `DispatchQueue.main.async` instead of `Task { @MainActor }`
  - Fixed in: `PermissionManager.swift` lines 32-40, `PermissionStatusChecker.swift` lines 30-34

#### 📡 **Permission Detection Not Working**
**Problem**: App doesn't detect when permissions are granted/revoked
- **Root Cause**: Permission monitoring not started automatically
- **Solution**: Added `permissionManager.startPermissionMonitoring()` in ContentView.onAppear

#### 🧪 **Debugging Methodology**
**Approach**: Component isolation testing
1. Created minimal ContentView with only basic permission status
2. Added components incrementally: ClickPointSelector → ConfigurationPanel → Development Tools
3. Tested each addition for crash behavior when toggling permissions
4. **Result**: All UI components were safe; crashes were from underlying permission system issues

### Build & Deployment Pipeline

**Correct Workflow**:
```bash
# 1. Build universal release binary
./build_app.sh

# 2. Sign with valid certificate (preserves binary)
CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)" ./scripts/sign-app.sh

# 3. Launch for testing
open dist/ClickIt.app
```

**Certificate Setup**:
```bash
# List available certificates
security find-identity -v -p codesigning

# Set certificate for session
export CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)"

# Or add to shell profile for persistence
echo 'export CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)"' >> ~/.zshrc
```

**Critical**: Always verify certificate validity before signing. Use `scripts/skip-signing.sh` if only self-signed certificate is needed.

### Permission System Requirements

**Essential for Stability**:
1. **Start monitoring**: Call `permissionManager.startPermissionMonitoring()` in app initialization
2. **Avoid concurrency conflicts**: Use proper `@MainActor` isolation without redundant dispatch
3. **Test permission changes**: Always test toggling permissions ON/OFF during development

## Documentation References

- Full product requirements: `docs/clickit_autoclicker_prd.md`
- Implementation plan: `docs/issue1_implementation_plan.md`
- Task tracking: `docs/autoclicker_tasks.md`
- GitHub issues: `docs/github_issues_list.md`