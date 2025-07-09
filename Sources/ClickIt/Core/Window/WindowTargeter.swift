import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

/// Handles targeting and validation of windows for clicking operations
@MainActor
class WindowTargeter: ObservableObject {
    static let shared = WindowTargeter()
    
    @Published var currentTarget: WindowTargetingConfig?
    @Published var isTargetValid = false
    @Published var lastValidationError: WindowError?
    
    private let windowManager = WindowManager.shared
    private var validationTask: Task<Void, Never>?
    
    private init() {}
    
    deinit {
        validationTask?.cancel()
    }
    
    // MARK: - Target Selection
    
    /// Set a window as the current target
    func setTarget(_ window: WindowInfo) {
        currentTarget = window.createTargetingConfig()
        startTargetValidation()
    }
    
    /// Set a targeting configuration as the current target
    func setTarget(_ config: WindowTargetingConfig) {
        currentTarget = config
        startTargetValidation()
    }
    
    /// Clear the current target
    func clearTarget() {
        currentTarget = nil
        isTargetValid = false
        lastValidationError = nil
        stopTargetValidation()
    }
    
    // MARK: - Target Validation
    
    /// Validate the current target and update status
    func validateCurrentTarget() async -> Bool {
        guard let target = currentTarget else {
            isTargetValid = false
            lastValidationError = WindowError.windowNotFound(kCGNullWindowID)
            return false
        }
        
        return await validateTarget(target)
    }
    
    /// Validate a specific targeting configuration
    func validateTarget(_ config: WindowTargetingConfig) async -> Bool {
        lastValidationError = nil
        
        do {
            let isValid = try await performTargetValidation(config)
            isTargetValid = isValid
            return isValid
        } catch {
            lastValidationError = error as? WindowError ?? WindowError.unknown(error.localizedDescription)
            isTargetValid = false
            return false
        }
    }
    
    /// Get the current target window bounds (updated)
    func getCurrentTargetBounds() async -> CGRect? {
        guard let target = currentTarget else { return nil }
        
        // Try to find the window with updated info
        let windows = await windowManager.findWindows(for: target.processID)
        let matchingWindow = windows.first { window in
            window.windowID == target.windowID ||
            (window.applicationName == target.applicationName && window.windowTitle == target.windowTitle)
        }
        
        return matchingWindow?.bounds
    }
    
    /// Check if the target supports background/minimized clicking
    func supportsBackgroundClicking() -> Bool {
        guard let target = currentTarget else { return false }
        return target.preferProcessID && target.processID > 0
    }
    
    // MARK: - Process ID Targeting
    
    /// Get targeting information for process ID based clicking
    func getProcessTargetingInfo() async -> ProcessTargetingInfo? {
        guard let target = currentTarget else { return nil }
        
        // Verify the process still exists
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.processIdentifier == target.processID }) else {
            return nil
        }
        
        return ProcessTargetingInfo(
            processID: target.processID,
            applicationName: target.applicationName,
            bundleIdentifier: app.bundleIdentifier,
            isActive: app.isActive,
            isHidden: app.isHidden,
            supportsBackgroundClicking: true
        )
    }
    
    /// Check if process ID targeting is available
    func isProcessTargetingAvailable() async -> Bool {
        guard let target = currentTarget else { return false }
        
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.processIdentifier == target.processID }
    }
    
    // MARK: - Multiple Instance Support
    
    /// Find all windows for the target application
    func findAllInstancesOfTargetApp() async -> [WindowInfo] {
        guard let target = currentTarget else { return [] }
        return await windowManager.findWindows(for: target.applicationName)
    }
    
    /// Select a specific instance when multiple exist
    func selectInstance(_ window: WindowInfo) {
        setTarget(window)
    }
    
    /// Get disambiguation options for multiple instances
    func getInstanceDisambiguationOptions() async -> [WindowInstanceOption] {
        guard let target = currentTarget else { return [] }
        
        let allWindows = await windowManager.findWindows(for: target.applicationName)
        return allWindows.map { window in
            WindowInstanceOption(
                window: window,
                isCurrentTarget: window.windowID == target.windowID,
                distinguishingFeature: getDistinguishingFeature(for: window, in: allWindows)
            )
        }
    }
    
    // MARK: - Private Implementation
    
    private func startTargetValidation() {
        stopTargetValidation()
        
        validationTask = Task {
            while !Task.isCancelled {
                _ = await validateCurrentTarget()
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        }
    }
    
    private func stopTargetValidation() {
        validationTask?.cancel()
        validationTask = nil
    }
    
    private func performTargetValidation(_ config: WindowTargetingConfig) async throws -> Bool {
        // First, check if the process is still running
        let runningApps = NSWorkspace.shared.runningApplications
        guard runningApps.contains(where: { $0.processIdentifier == config.processID }) else {
            throw WindowError.processNotFound(config.processID)
        }
        
        // Then check if the window still exists
        let windows = await windowManager.findWindows(for: config.processID)
        let windowExists = windows.contains { window in
            window.windowID == config.windowID ||
            (window.applicationName == config.applicationName && window.windowTitle == config.windowTitle)
        }
        
        if !windowExists {
            throw WindowError.windowNotFound(config.windowID)
        }
        
        return true
    }
    
    private func getDistinguishingFeature(for window: WindowInfo, in allWindows: [WindowInfo]) -> String {
        // If there's only one window, no distinguishing feature needed
        guard allWindows.count > 1 else { return "" }
        
        // Try window title first
        if !window.windowTitle.isEmpty {
            let titlesCount = allWindows.filter { $0.windowTitle == window.windowTitle }.count
            if titlesCount == 1 {
                return window.windowTitle
            }
        }
        
        // Try position
        let positionsCount = allWindows.filter { $0.bounds.origin == window.bounds.origin }.count
        if positionsCount == 1 {
            return window.positionString
        }
        
        // Try dimensions
        let dimensionsCount = allWindows.filter { $0.bounds.size == window.bounds.size }.count
        if dimensionsCount == 1 {
            return window.dimensionsString
        }
        
        // Try status
        let statusCount = allWindows.filter { $0.statusDescription == window.statusDescription }.count
        if statusCount == 1 {
            return window.statusDescription
        }
        
        // Fallback to window ID
        return "Window #\(window.windowID)"
    }
}

// MARK: - Supporting Types

/// Information about a process for targeting
struct ProcessTargetingInfo {
    let processID: pid_t
    let applicationName: String
    let bundleIdentifier: String?
    let isActive: Bool
    let isHidden: Bool
    let supportsBackgroundClicking: Bool
    
    var statusDescription: String {
        if isHidden {
            return "Hidden"
        } else if !isActive {
            return "Background"
        } else {
            return "Active"
        }
    }
}

/// Option for disambiguating between multiple window instances
struct WindowInstanceOption: Identifiable {
    let id = UUID()
    let window: WindowInfo
    let isCurrentTarget: Bool
    let distinguishingFeature: String
    
    var displayName: String {
        if distinguishingFeature.isEmpty {
            return window.shortDisplayName
        } else {
            return "\(window.shortDisplayName) (\(distinguishingFeature))"
        }
    }
}

// MARK: - Targeting Extensions

extension WindowTargetingConfig {
    /// Check if this configuration is valid for process ID targeting
    var isValidForProcessTargeting: Bool {
        return processID > 0 && preferProcessID
    }
    
    /// Check if this configuration supports minimized window clicking
    var supportsMinimizedClicking: Bool {
        return isValidForProcessTargeting
    }
}