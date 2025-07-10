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
    @Published var isSystemDialogActive: Bool = false
    
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
        // Don't update during system dialogs to prevent crashes
        guard !isSystemDialogActive else { 
            print("PermissionManager: Skipping status update during system dialog")
            return 
        }
        
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
        print("PermissionManager: Requesting accessibility permission")
        
        // Mark dialog as active to prevent conflicts
        isSystemDialogActive = true
        
        // This triggers the system permission dialog
        let accessibilityDialogKey = "AXTrustedCheckOptionPrompt"
        let options = [accessibilityDialogKey: true] as CFDictionary
        
        // The initial call will return false but show the dialog
        let _ = AXIsProcessTrustedWithOptions(options)
        
        // Wait for user to potentially grant permission
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Check the actual permission status after dialog
        let granted = checkAccessibilityPermission()
        
        // Mark dialog as no longer active
        isSystemDialogActive = false
        
        // Update status safely
        updatePermissionStatus()
        
        print("PermissionManager: Accessibility permission request completed - granted: \(granted)")
        return granted
    }
    
    func requestScreenRecordingPermission() async -> Bool {
        guard #available(macOS 10.15, *) else { 
            self.screenRecordingPermissionGranted = true
            self.updateAllPermissionsStatus()
            return true 
        }
        
        print("PermissionManager: Requesting screen recording permission")
        
        // Mark dialog as active to prevent conflicts
        isSystemDialogActive = true
        
        // Request screen recording permission asynchronously to avoid blocking the UI
        let granted = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = CGRequestScreenCaptureAccess()
                continuation.resume(returning: result)
            }
        }
        
        // Mark dialog as no longer active
        isSystemDialogActive = false
        
        // Update status safely
        updatePermissionStatus()
        
        print("PermissionManager: Screen recording permission request completed - granted: \(granted)")
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
        print("PermissionManager: App will resign active - pausing permission monitoring")
        isSystemDialogActive = true
    }
    
    private func handleAppDidBecomeActive() {
        print("PermissionManager: App did become active - resuming permission monitoring")
        isSystemDialogActive = false
        
        // Safe delay before updating status to ensure app is fully active
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            updatePermissionStatus()
        }
    }
    
    // Replace timer-based monitoring with event-driven approach
    func refreshPermissionStatus() {
        guard !isSystemDialogActive else { 
            print("PermissionManager: Refresh requested during system dialog - deferring")
            return 
        }
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