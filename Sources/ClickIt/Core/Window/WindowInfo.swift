import Foundation
import CoreGraphics

/// Information about a detected window
struct WindowInfo: Identifiable, Hashable, Codable {
    let id = UUID()
    let windowID: CGWindowID
    let processID: pid_t
    let applicationName: String
    let windowTitle: String
    let bounds: CGRect
    let windowLayer: Int32
    let isOnScreen: Bool
    let isMinimized: Bool
    let lastUpdated: Date
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case windowID, processID, applicationName, windowTitle, bounds, windowLayer, isOnScreen, isMinimized, lastUpdated
    }
    
    /// Display name combining app name and window title
    var displayName: String {
        if windowTitle.isEmpty {
            return applicationName
        } else {
            return "\(applicationName) - \(windowTitle)"
        }
    }
    
    /// Short display name for compact views
    var shortDisplayName: String {
        if windowTitle.isEmpty {
            return applicationName
        } else {
            // Truncate long titles
            let maxLength = 30
            if windowTitle.count > maxLength {
                return "\(applicationName) - \(String(windowTitle.prefix(maxLength)))..."
            } else {
                return "\(applicationName) - \(windowTitle)"
            }
        }
    }
    
    /// Window dimensions as a readable string
    var dimensionsString: String {
        return "\(Int(bounds.width)) × \(Int(bounds.height))"
    }
    
    /// Window position as a readable string
    var positionString: String {
        return "(\(Int(bounds.origin.x)), \(Int(bounds.origin.y)))"
    }
    
    /// Full window description
    var description: String {
        return "\(displayName) - \(dimensionsString) at \(positionString)"
    }
    
    /// Whether the window is suitable for clicking
    var isClickable: Bool {
        return bounds.width > 0 && bounds.height > 0 && !isSystemWindow
    }
    
    /// Whether this appears to be a system window
    var isSystemWindow: Bool {
        let systemApps = [
            "Window Server", "Dock", "SystemUIServer", "Control Center",
            "NotificationCenter", "Spotlight", "Mission Control"
        ]
        return systemApps.contains(applicationName)
    }
    
    /// Window status for UI display
    var statusDescription: String {
        if isMinimized {
            return "Minimized"
        } else if !isOnScreen {
            return "Off-screen"
        } else if windowLayer < 0 {
            return "Background"
        } else {
            return "Active"
        }
    }
    
    /// Convert point from screen coordinates to window coordinates
    func convertToWindowCoordinates(_ screenPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: screenPoint.x - bounds.origin.x,
            y: screenPoint.y - bounds.origin.y
        )
    }
    
    /// Convert point from window coordinates to screen coordinates
    func convertToScreenCoordinates(_ windowPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: windowPoint.x + bounds.origin.x,
            y: windowPoint.y + bounds.origin.y
        )
    }
    
    /// Check if a point is within the window bounds
    func contains(_ point: CGPoint) -> Bool {
        return bounds.contains(point)
    }
    
    /// Get center point of the window
    var centerPoint: CGPoint {
        return CGPoint(
            x: bounds.midX,
            y: bounds.midY
        )
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(windowID)
        hasher.combine(processID)
    }
    
    static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
        return lhs.windowID == rhs.windowID && lhs.processID == rhs.processID
    }
}

// MARK: - Window Collections

extension Array where Element == WindowInfo {
    /// Filter windows by application name
    func forApplication(_ name: String) -> [WindowInfo] {
        return filter { $0.applicationName.lowercased().contains(name.lowercased()) }
    }
    
    /// Filter windows by process ID
    func forProcess(_ pid: pid_t) -> [WindowInfo] {
        return filter { $0.processID == pid }
    }
    
    /// Filter only clickable windows
    var clickableWindows: [WindowInfo] {
        return filter { $0.isClickable }
    }
    
    /// Filter only visible windows
    var visibleWindows: [WindowInfo] {
        return filter { $0.isOnScreen && !$0.isMinimized }
    }
    
    /// Filter only minimized windows
    var minimizedWindows: [WindowInfo] {
        return filter { $0.isMinimized }
    }
    
    /// Group windows by application
    var groupedByApplication: [String: [WindowInfo]] {
        return Dictionary(grouping: self) { $0.applicationName }
    }
    
    /// Sort windows by application name and then by window title
    var sortedByApplication: [WindowInfo] {
        return sorted { first, second in
            if first.applicationName == second.applicationName {
                return first.windowTitle < second.windowTitle
            }
            return first.applicationName < second.applicationName
        }
    }
    
    /// Sort windows by last updated time (most recent first)
    var sortedByUpdated: [WindowInfo] {
        return sorted { $0.lastUpdated > $1.lastUpdated }
    }
}

// MARK: - WindowInfo Extensions for Targeting

extension WindowInfo {
    /// Create a window targeting configuration
    func createTargetingConfig() -> WindowTargetingConfig {
        return WindowTargetingConfig(
            windowID: windowID,
            processID: processID,
            applicationName: applicationName,
            windowTitle: windowTitle,
            bounds: bounds,
            preferProcessID: true // Always prefer process ID for minimized window support
        )
    }
}

/// Configuration for targeting a specific window
struct WindowTargetingConfig: Codable {
    let windowID: CGWindowID
    let processID: pid_t
    let applicationName: String
    let windowTitle: String
    let bounds: CGRect
    let preferProcessID: Bool
    
    var displayName: String {
        if windowTitle.isEmpty {
            return applicationName
        } else {
            return "\(applicationName) - \(windowTitle)"
        }
    }
}