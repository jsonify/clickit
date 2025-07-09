import Foundation
import CoreGraphics
import ApplicationServices

/// Manages window detection and targeting for universal auto-clicking
@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var availableWindows: [WindowInfo] = []
    @Published var selectedWindow: WindowInfo?
    @Published var isDetecting = false
    @Published var lastError: WindowError?
    
    private init() {}
    
    // MARK: - Window Detection
    
    /// Detect all available windows using CGWindowListCopyWindowInfo
    func detectAllWindows() async -> [WindowInfo] {
        isDetecting = true
        lastError = nil
        
        do {
            let windows = try await performWindowDetection()
            availableWindows = windows
            return windows
        } catch {
            lastError = error as? WindowError ?? WindowError.unknown(error.localizedDescription)
            return []
        }
    }
    
    /// Refresh window list and update published properties
    func refreshWindows() async {
        _ = await detectAllWindows()
    }
    
    /// Find windows for a specific application
    func findWindows(for applicationName: String) async -> [WindowInfo] {
        let allWindows = await detectAllWindows()
        return allWindows.filter { $0.applicationName.lowercased().contains(applicationName.lowercased()) }
    }
    
    /// Find windows by process ID
    func findWindows(for processID: pid_t) async -> [WindowInfo] {
        let allWindows = await detectAllWindows()
        return allWindows.filter { $0.processID == processID }
    }
    
    // MARK: - Window Targeting
    
    /// Select a window for targeting
    func selectWindow(_ window: WindowInfo) {
        selectedWindow = window
    }
    
    /// Get the currently selected window with updated info
    func getSelectedWindowInfo() async -> WindowInfo? {
        guard let selected = selectedWindow else { return nil }
        
        // Refresh the selected window's info
        let allWindows = await detectAllWindows()
        return allWindows.first { $0.windowID == selected.windowID }
    }
    
    /// Check if a window is still valid and accessible
    func isWindowValid(_ window: WindowInfo) async -> Bool {
        let allWindows = await detectAllWindows()
        return allWindows.contains { $0.windowID == window.windowID }
    }
    
    // MARK: - Private Implementation
    
    private func performWindowDetection() async throws -> [WindowInfo] {
        let windows = try getCGWindowList()
        isDetecting = false
        return windows
    }
    
    private func getCGWindowList() throws -> [WindowInfo] {
        // Get window list using CGWindowListCopyWindowInfo
        guard let windowListInfo = CGWindowListCopyWindowInfo(
            CGWindowListOption.optionOnScreenOnly,
            kCGNullWindowID
        ) as? [[CFString: Any]] else {
            throw WindowError.detectionFailed("Failed to get window list")
        }
        
        var windows: [WindowInfo] = []
        
        for windowDict in windowListInfo {
            do {
                let window = try parseWindowInfo(from: windowDict)
                // Filter out system windows and invalid entries
                if isValidWindow(window) {
                    windows.append(window)
                }
            } catch {
                // Skip invalid windows but continue processing others
                continue
            }
        }
        
        return windows.sorted { $0.applicationName < $1.applicationName }
    }
    
    private func parseWindowInfo(from dict: [CFString: Any]) throws -> WindowInfo {
        // Extract window ID
        guard let windowID = dict[kCGWindowNumber] as? CGWindowID else {
            throw WindowError.invalidWindowData("Missing window ID")
        }
        
        // Extract process ID
        guard let processID = dict[kCGWindowOwnerPID] as? pid_t else {
            throw WindowError.invalidWindowData("Missing process ID")
        }
        
        // Extract application name
        let applicationName = dict[kCGWindowOwnerName] as? String ?? "Unknown"
        
        // Extract window title
        let windowTitle = dict[kCGWindowName] as? String ?? ""
        
        // Extract window bounds
        var bounds = CGRect.zero
        if let boundsDict = dict[kCGWindowBounds] as? [CFString: Any] {
            bounds = CGRect(
                x: boundsDict["X" as CFString] as? CGFloat ?? 0,
                y: boundsDict["Y" as CFString] as? CGFloat ?? 0,
                width: boundsDict["Width" as CFString] as? CGFloat ?? 0,
                height: boundsDict["Height" as CFString] as? CGFloat ?? 0
            )
        }
        
        // Extract window layer
        let windowLayer = dict[kCGWindowLayer] as? Int32 ?? 0
        
        // Check if window is on screen
        let isOnScreen = dict[kCGWindowIsOnscreen] as? Bool ?? false
        
        return WindowInfo(
            windowID: windowID,
            processID: processID,
            applicationName: applicationName,
            windowTitle: windowTitle,
            bounds: bounds,
            windowLayer: windowLayer,
            isOnScreen: isOnScreen,
            isMinimized: windowLayer < 0 || !isOnScreen,
            lastUpdated: Date()
        )
    }
    
    private func isValidWindow(_ window: WindowInfo) -> Bool {
        // Filter out system windows and invalid entries
        guard !window.applicationName.isEmpty else { return false }
        guard window.bounds.width > 0 && window.bounds.height > 0 else { return false }
        
        // Filter out common system applications
        let systemApps = ["Window Server", "Dock", "SystemUIServer", "Control Center"]
        guard !systemApps.contains(window.applicationName) else { return false }
        
        // Filter out windows that are too small (likely system dialogs)
        guard window.bounds.width >= 100 && window.bounds.height >= 50 else { return false }
        
        return true
    }
}

// MARK: - Window Error Types

enum WindowError: Error, LocalizedError {
    case detectionFailed(String)
    case invalidWindowData(String)
    case windowNotFound(CGWindowID)
    case processNotFound(pid_t)
    case permissionDenied
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .detectionFailed(let message):
            return "Window detection failed: \(message)"
        case .invalidWindowData(let message):
            return "Invalid window data: \(message)"
        case .windowNotFound(let id):
            return "Window not found: \(id)"
        case .processNotFound(let pid):
            return "Process not found: \(pid)"
        case .permissionDenied:
            return "Permission denied for window access"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .detectionFailed:
            return "Try refreshing the window list or check system permissions"
        case .invalidWindowData:
            return "The window data is corrupted. Try refreshing the window list"
        case .windowNotFound:
            return "The window may have been closed. Refresh the window list"
        case .processNotFound:
            return "The target application may have been closed. Select a new target"
        case .permissionDenied:
            return "Grant Screen Recording permission in System Settings"
        case .unknown:
            return "Try restarting the application"
        }
    }
}