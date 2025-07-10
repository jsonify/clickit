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
    
    
    // MARK: - Permission Status Checking
    
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
        let accessibility = checkAccessibilityPermission()
        let screenRecording = checkScreenRecordingPermission()
        
        // Already on MainActor, no need for DispatchQueue.main.async
        self.accessibilityPermissionGranted = accessibility
        self.screenRecordingPermissionGranted = screenRecording
        self.allPermissionsGranted = accessibility && screenRecording
    }
    
    // MARK: - Permission Requesting
    
    func requestAccessibilityPermission() async -> Bool {
        // This triggers the system permission dialog
        let accessibilityDialogKey = "AXTrustedCheckOptionPrompt"
        let options = [accessibilityDialogKey: true] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(options)
        
        self.accessibilityPermissionGranted = granted
        self.updateAllPermissionsStatus()
        
        return granted
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        guard #available(macOS 10.15, *) else { 
            self.screenRecordingPermissionGranted = true
            self.updateAllPermissionsStatus()
            return true 
        }
        
        // Request screen recording permission asynchronously to avoid blocking the UI
        let granted = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = CGRequestScreenCaptureAccess()
                continuation.resume(returning: result)
            }
        }
        
        self.screenRecordingPermissionGranted = granted
        self.updateAllPermissionsStatus()
        
        return granted
    }
    
    func requestAllPermissions() async -> Bool {
        // Request accessibility permission first
        let accessibilityGranted = await requestAccessibilityPermission()
        
        // Give a brief moment for the system dialog to be handled
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Request screen recording permission
        let screenRecordingGranted = await requestScreenRecordingPermission()
        
        // Update the final status
        updatePermissionStatus()
        
        return accessibilityGranted && screenRecordingGranted
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
    
    private var monitoringTimer: Timer?
    
    func startPermissionMonitoring() {
        // Prevent multiple timers
        stopPermissionMonitoring()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePermissionStatus()
            }
        }
    }
    
    func stopPermissionMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
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