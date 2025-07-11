import Foundation
import ApplicationServices
import AVFoundation
import SwiftUI

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var accessibilityPermissionGranted: Bool = false
    @Published var screenRecordingPermissionGranted: Bool = false
    @Published var allPermissionsGranted: Bool = false
    
    private init() {
        updatePermissionStatus()
    }
    
    
    // MARK: - Permission Status Checking (AutoCliq's Safe Approach)
    
    nonisolated func hasAccessibilityPermission() -> Bool {
        // Check without prompting first (AutoCliq's approach)
        let options = ["AXTrustedCheckOptionPrompt": false]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // For debugging, let's also try the simple check
        let simpleTrusted = AXIsProcessTrusted()
        
        // Get bundle info for debugging
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let bundlePath = Bundle.main.bundlePath
        
        NSLog("PermissionManager: Bundle ID: \(bundleId)")
        NSLog("PermissionManager: Bundle Path: \(bundlePath)")
        NSLog("PermissionManager: AXIsProcessTrusted returned: \(isTrusted)")
        NSLog("PermissionManager: AXIsProcessTrusted (simple) returned: \(simpleTrusted)")
        
        // Try to create a test event to verify actual permissions
        let canCreateEvent = canCreateTestEvent()
        NSLog("PermissionManager: Can create test event: \(canCreateEvent)")
        
        // For now, just return the trusted status since event creation might fail for other reasons
        return isTrusted
    }
    
    nonisolated private func canCreateTestEvent() -> Bool {
        // Try to create a test CGEvent to verify we actually have permission
        let testEvent = CGEvent(mouseEventSource: nil, 
                               mouseType: .leftMouseDown, 
                               mouseCursorPosition: CGPoint(x: 0, y: 0), 
                               mouseButton: .left)
        let canCreate = testEvent != nil
        NSLog("PermissionManager: Can create test event: \(canCreate)")
        return canCreate
    }
    
    nonisolated func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrustedWithOptions(nil)
    }
    
    nonisolated func checkScreenRecordingPermission() -> Bool {
        guard #available(macOS 10.15, *) else { return true }
        
        // Create a small window list request to test screen recording permission
        let windowList = CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)
        return windowList != nil
    }
    
    func updatePermissionStatus() {
        let accessibility = hasAccessibilityPermission()
        let screenRecording = checkScreenRecordingPermission()
        
        // Already on MainActor, no need for DispatchQueue
        self.accessibilityPermissionGranted = accessibility
        self.screenRecordingPermissionGranted = screenRecording
        self.allPermissionsGranted = accessibility && screenRecording
    }
    
    // MARK: - Permission Requesting
    
    nonisolated func requestAccessibilityPermission() {
        // AutoCliq's simple approach - just trigger the dialog
        let options = ["AXTrustedCheckOptionPrompt": true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    nonisolated func resetPermissions() {
        // This will force a new permission prompt (AutoCliq's approach)
        let options = ["AXTrustedCheckOptionPrompt": true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    nonisolated func requestScreenRecordingPermission() {
        guard #available(macOS 10.15, *) else { 
            return
        }
        
        // Simple approach - just request the permission
        _ = CGRequestScreenCaptureAccess()
    }
    
    func requestAllPermissions() {
        requestAccessibilityPermission()
        requestScreenRecordingPermission()
    }
    
    // MARK: - Utilities
    
    private func updateAllPermissionsStatus() {
        allPermissionsGranted = accessibilityPermissionGranted && screenRecordingPermissionGranted
    }
    
    func openSystemSettings(for permission: PermissionType) {
        let urlString: String
        
        switch permission {
        case .accessibility:
            urlString = AppConstants.accessibilitySettingsURL
        case .screenRecording:
            urlString = AppConstants.screenRecordingSettingsURL
        }
        
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL string for \(permission.rawValue) settings")
            return
        }
        
        NSWorkspace.shared.open(url)
    }
    
    nonisolated func openSystemPreferences() {
        // AutoCliq's approach - Open the Accessibility settings directly
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func startPermissionMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePermissionStatus()
            }
        }
    }
    
    // For backward compatibility with new UI components
    func refreshPermissionStatus() {
        updatePermissionStatus()
    }
    
    func getPermissionDescription(for permission: PermissionType) -> String {
        switch permission {
        case .accessibility:
            return "ClickIt needs Accessibility permission to simulate mouse clicks and register global hotkeys (ESC key). This allows the app to send click events to other applications."
        case .screenRecording:
            return "ClickIt needs Screen Recording permission to detect windows and display visual feedback overlays. This allows the app to identify target windows and show click indicators."
        }
    }
    
    func getPermissionInstructions(for permission: PermissionType) -> String {
        switch permission {
        case .accessibility:
            return "1. Open System Settings\n2. Go to Privacy & Security\n3. Select Accessibility\n4. Enable ClickIt in the list"
        case .screenRecording:
            return "1. Open System Settings\n2. Go to Privacy & Security\n3. Select Screen Recording\n4. Enable ClickIt in the list"
        }
    }
}

// MARK: - Permission Types

enum PermissionType: String, CaseIterable {
    case accessibility = "Accessibility"
    case screenRecording = "Screen Recording"
    
    var systemIcon: String {
        switch self {
        case .accessibility:
            return "accessibility"
        case .screenRecording:
            return "rectangle.on.rectangle"
        }
    }
    
    var description: String {
        switch self {
        case .accessibility:
            return "Required for mouse simulation and global hotkeys"
        case .screenRecording:
            return "Required for window detection and visual overlays"
        }
    }
}