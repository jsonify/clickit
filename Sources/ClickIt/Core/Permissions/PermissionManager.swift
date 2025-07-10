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
    
    // App lifecycle management
    nonisolated(unsafe) private var willResignActiveObserver: NSObjectProtocol?
    nonisolated(unsafe) private var didBecomeActiveObserver: NSObjectProtocol?
    
    private init() {
        setupAppLifecycleObservers()
        updatePermissionStatus()
    }
    
    deinit {
        // Clean up observers synchronously
        if let observer = willResignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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
        
        // Update properties directly (already on MainActor)
        self.accessibilityPermissionGranted = accessibility
        self.screenRecordingPermissionGranted = screenRecording
        self.allPermissionsGranted = accessibility && screenRecording
        
        print("PermissionManager: Status updated - Accessibility: \(accessibility), Screen Recording: \(screenRecording)")
    }
    
    // MARK: - Permission Requesting
    
    func requestAccessibilityPermission() async -> Bool {
        print("PermissionManager: Opening accessibility permission dialog")
        
        // Simply trigger the system dialog without trying to manage it
        let accessibilityDialogKey = "AXTrustedCheckOptionPrompt"
        let options = [accessibilityDialogKey: true] as CFDictionary
        
        // This call shows the system dialog and returns immediately
        // We don't try to manage the dialog state or wait for completion
        let _ = AXIsProcessTrustedWithOptions(options)
        
        print("PermissionManager: System permission dialog opened - user must complete it manually")
        
        // Return current status (will be false until user grants permission)
        // The UI will update automatically when permissions are actually granted
        return checkAccessibilityPermission()
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        guard #available(macOS 10.15, *) else { 
            self.screenRecordingPermissionGranted = true
            self.updateAllPermissionsStatus()
            return true 
        }
        
        print("PermissionManager: Opening screen recording permission dialog")
        
        // Simply trigger the system dialog without trying to manage it
        // This call shows the system dialog and returns immediately
        let _ = CGRequestScreenCaptureAccess()
        
        print("PermissionManager: System permission dialog opened - user must complete it manually")
        
        // Return current status (will be false until user grants permission)
        // The UI will update automatically when permissions are actually granted
        return checkScreenRecordingPermission()
    }
    
    func requestAllPermissions() async -> Bool {
        print("PermissionManager: Opening all permission dialogs")
        
        // Open accessibility permission dialog
        let _ = await requestAccessibilityPermission()
        
        // Open screen recording permission dialog  
        let _ = await requestScreenRecordingPermission()
        
        print("PermissionManager: All permission dialogs opened - user must complete them manually")
        
        // Return current status - will be updated automatically when user grants permissions
        updatePermissionStatus()
        return allPermissionsGranted
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
    
    // MARK: - App Lifecycle Management
    
    private func setupAppLifecycleObservers() {
        // Monitor when app goes to background (during system dialogs)
        willResignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppWillResignActive()
            }
        }
        
        // Monitor when app returns to foreground (after system dialogs)
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppDidBecomeActive()
            }
        }
    }
    
    private func removeAppLifecycleObservers() {
        if let observer = willResignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            willResignActiveObserver = nil
        }
        
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            didBecomeActiveObserver = nil
        }
    }
    
    private func handleAppWillResignActive() {
        print("PermissionManager: App will resign active")
    }
    
    private func handleAppDidBecomeActive() {
        print("PermissionManager: App did become active - refreshing permission status")
        
        // Refresh permission status when app becomes active (user might have changed permissions)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            updatePermissionStatus()
        }
    }
    
    // Event-driven permission status refresh
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