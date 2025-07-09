# Issue #2: macOS Permissions System

**Link to Issue**: https://github.com/jsonify/clickit/issues/2

## Issue Analysis

### Problem Statement
ClickIt requires two critical macOS permissions to function:
1. **Accessibility Permission** - Required for mouse event simulation and global hotkey registration
2. **Screen Recording Permission** - Required for window detection and visual overlay system

### Current State
- Basic app structure established with SwiftUI
- Framework imports in place (CoreGraphics, Carbon, ApplicationServices)
- Constants defined for required permissions
- Empty permissions directory structure created
- No permission handling implementation yet

### Technical Requirements

#### Core Permissions Needed
1. **Accessibility (`kAXTrustedCheckOptionPrompt`)**
   - Required for: `CGEventCreateMouseEvent`, `CGEventPostToPid`, global hotkeys
   - API: `AXIsProcessTrustedWithOptions`
   - User Path: System Settings > Privacy & Security > Accessibility

2. **Screen Recording (`kCGWindowListOptionAll`)**
   - Required for: `CGWindowListCopyWindowInfo`, overlay windows
   - API: `CGRequestScreenCaptureAccess`
   - User Path: System Settings > Privacy & Security > Screen Recording

#### Implementation Approach
1. **Permission Manager Class** - Centralized permission handling
2. **Status Checking Utilities** - Real-time permission status monitoring
3. **Request Flow UI** - User-friendly permission request interface
4. **Retry Mechanism** - Graceful handling of permission denial

## Implementation Plan

### Phase 1: Core Permission Manager
- Create `PermissionManager.swift` in `Sources/ClickIt/Core/Permissions/`
- Implement accessibility permission checking and requesting
- Implement screen recording permission checking and requesting
- Add permission status monitoring

### Phase 2: Status Utilities
- Create `PermissionStatusChecker.swift` 
- Implement real-time status monitoring
- Add notification system for permission changes

### Phase 3: User Interface
- Create `PermissionRequestView.swift` in `Sources/ClickIt/UI/Views/`
- Design clear permission explanations
- Implement step-by-step permission request flow
- Add system settings navigation helpers

### Phase 4: Error Handling & Retry
- Implement graceful permission denial handling
- Add retry mechanism for failed permissions
- Create user-friendly error messages
- Add permission troubleshooting guide

## Technical Implementation Details

### Permission Manager Structure
```swift
class PermissionManager: ObservableObject {
    @Published var accessibilityPermissionGranted: Bool = false
    @Published var screenRecordingPermissionGranted: Bool = false
    
    // Status checking
    func checkAccessibilityPermission() -> Bool
    func checkScreenRecordingPermission() -> Bool
    
    // Permission requesting
    func requestAccessibilityPermission() async -> Bool
    func requestScreenRecordingPermission() async -> Bool
    
    // Utilities
    func checkAllPermissions() -> Bool
    func openSystemSettings(for permission: PermissionType)
}
```

### UI Integration Points
- Integrate permission checks into app launch flow
- Add permission status indicators to main UI
- Create dedicated permission setup screen
- Update ContentView to handle permission states

### Error Scenarios to Handle
1. User denies permission initially
2. User revokes permission while app is running
3. System settings navigation failures
4. Permission API failures

## Testing Strategy

### Unit Tests
- Permission status checking accuracy
- Permission request flow validation
- Error handling for denied permissions
- System settings navigation

### Integration Tests
- Full permission request flow
- UI state management during permission changes
- App behavior with partial permissions

### Manual Testing
- Fresh macOS install permission flow
- Permission revocation scenarios
- System settings integration
- User experience validation

## Success Criteria

- [x] App properly requests both permission types
- [x] Clear user-friendly permission request UI
- [x] Graceful handling of permission denial
- [x] Retry mechanism for failed permissions
- [x] Real-time permission status monitoring
- [x] System settings navigation integration

## Files to Create/Modify

### New Files
1. `Sources/ClickIt/Core/Permissions/PermissionManager.swift`
2. `Sources/ClickIt/Core/Permissions/PermissionStatusChecker.swift`
3. `Sources/ClickIt/UI/Views/PermissionRequestView.swift`
4. `Sources/ClickIt/UI/Components/PermissionStatusIndicator.swift`

### Modified Files
1. `Sources/ClickIt/UI/Views/ContentView.swift` - Add permission integration
2. `Sources/ClickIt/ClickItApp.swift` - Add permission manager initialization
3. `Sources/ClickIt/Utils/Constants/AppConstants.swift` - Add permission constants

## Implementation Order
1. Create PermissionManager core functionality
2. Implement permission status checking utilities
3. Create permission request UI components
4. Integrate permission flow into main app
5. Add error handling and retry mechanisms
6. Create comprehensive tests
7. Validate user experience

---

*Created: 2025-07-09*
*Issue: #2 - macOS Permissions System*
*Priority: High (Milestone 1)*