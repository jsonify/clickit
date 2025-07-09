import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

/// Specialized click engine for background clicking to specific applications
class BackgroundClicker: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Shared instance of the background clicker
    static let shared = BackgroundClicker()
    
    /// Cache for process information
    private var processCache: [String: pid_t] = [:]
    private var cacheUpdateTime: TimeInterval = 0
    private let cacheValidityDuration: TimeInterval = AppConstants.processCacheValidityDuration
    
    /// Queue for background operations
    private let backgroundQueue = DispatchQueue(label: "com.clickit.background-clicker", qos: .userInteractive)
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Performs a click on a specific application by bundle identifier
    /// - Parameters:
    ///   - bundleIdentifier: Bundle identifier of the target application
    ///   - location: Location to click
    ///   - clickType: Type of click to perform
    /// - Returns: Result of the click operation
    func clickOnApplication(
        bundleIdentifier: String,
        location: CGPoint,
        clickType: ClickType = .left
    ) async -> ClickResult {
        
        guard let pid = await getProcessID(for: bundleIdentifier) else {
            return ClickResult(
                success: false,
                actualLocation: location,
                timestamp: CFAbsoluteTimeGetCurrent(),
                error: .targetProcessNotFound
            )
        }
        
        let config = ClickConfiguration(
            type: clickType,
            location: location,
            targetPID: pid
        )
        
        return await ClickEngine.shared.performClick(configuration: config)
    }
    
    /// Performs a click on a specific application by process name
    /// - Parameters:
    ///   - processName: Name of the target process
    ///   - location: Location to click
    ///   - clickType: Type of click to perform
    /// - Returns: Result of the click operation
    func clickOnProcess(
        processName: String,
        location: CGPoint,
        clickType: ClickType = .left
    ) async -> ClickResult {
        
        guard let pid = await getProcessID(for: processName) else {
            return ClickResult(
                success: false,
                actualLocation: location,
                timestamp: CFAbsoluteTimeGetCurrent(),
                error: .targetProcessNotFound
            )
        }
        
        let config = ClickConfiguration(
            type: clickType,
            location: location,
            targetPID: pid
        )
        
        return await ClickEngine.shared.performClick(configuration: config)
    }
    
    /// Performs a click on a specific window
    /// - Parameters:
    ///   - windowInfo: Information about the target window
    ///   - relativeLocation: Location relative to the window
    ///   - clickType: Type of click to perform
    /// - Returns: Result of the click operation
    func clickOnWindow(
        windowInfo: WindowInfo,
        relativeLocation: CGPoint,
        clickType: ClickType = .left
    ) async -> ClickResult {
        
        // Convert relative location to absolute screen coordinates
        let absoluteLocation = CGPoint(
            x: windowInfo.bounds.origin.x + relativeLocation.x,
            y: windowInfo.bounds.origin.y + relativeLocation.y
        )
        
        let config = ClickConfiguration(
            type: clickType,
            location: absoluteLocation,
            targetPID: windowInfo.processID
        )
        
        return await ClickEngine.shared.performClick(configuration: config)
    }
    
    /// Performs multiple clicks on different applications
    /// - Parameter operations: Array of background click operations
    /// - Returns: Array of click results
    func performMultipleClicks(operations: [BackgroundClickOperation]) async -> [ClickResult] {
        var results: [ClickResult] = []
        
        for operation in operations {
            let result = await performBackgroundClick(operation: operation)
            results.append(result)
        }
        
        return results
    }
    
    /// Gets all running applications that can be targeted
    /// - Returns: Dictionary of application names to process IDs
    func getRunningApplications() async -> [String: pid_t] {
        return await withCheckedContinuation { continuation in
            backgroundQueue.async {
                let runningApps = self.getAllRunningApplications()
                continuation.resume(returning: runningApps)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Performs a background click operation
    /// - Parameter operation: Background click operation to perform
    /// - Returns: Result of the click operation
    private func performBackgroundClick(operation: BackgroundClickOperation) async -> ClickResult {
        let pid: pid_t?
        
        switch operation.target {
        case .bundleIdentifier(let bundleId):
            pid = await getProcessID(for: bundleId)
        case .processName(let processName):
            pid = await getProcessID(for: processName)
        case .processId(let processId):
            pid = processId
        }
        
        guard let targetPID = pid else {
            return ClickResult(
                success: false,
                actualLocation: operation.location,
                timestamp: CFAbsoluteTimeGetCurrent(),
                error: .targetProcessNotFound
            )
        }
        
        let config = ClickConfiguration(
            type: operation.clickType,
            location: operation.location,
            targetPID: targetPID
        )
        
        return await ClickEngine.shared.performClick(configuration: config)
    }
    
    /// Gets the process ID for a given application identifier
    /// - Parameter identifier: Bundle identifier or process name
    /// - Returns: Process ID if found, nil otherwise
    private func getProcessID(for identifier: String) async -> pid_t? {
        return await withCheckedContinuation { continuation in
            backgroundQueue.async {
                // Check cache first
                if let cachedPID = self.getCachedProcessID(for: identifier) {
                    continuation.resume(returning: cachedPID)
                    return
                }
                
                // Search running applications
                let runningApps = NSWorkspace.shared.runningApplications
                
                for app in runningApps {
                    if app.bundleIdentifier == identifier || app.localizedName == identifier {
                        let pid = app.processIdentifier
                        self.cacheProcessID(pid, for: identifier)
                        continuation.resume(returning: pid)
                        return
                    }
                }
                
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Gets a cached process ID if available and valid
    /// - Parameter identifier: Application identifier
    /// - Returns: Cached process ID if valid, nil otherwise
    private func getCachedProcessID(for identifier: String) -> pid_t? {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        if currentTime - cacheUpdateTime > cacheValidityDuration {
            processCache.removeAll()
            cacheUpdateTime = currentTime
            return nil
        }
        
        return processCache[identifier]
    }
    
    /// Caches a process ID for an identifier
    /// - Parameters:
    ///   - pid: Process ID to cache
    ///   - identifier: Application identifier
    private func cacheProcessID(_ pid: pid_t, for identifier: String) {
        processCache[identifier] = pid
        cacheUpdateTime = CFAbsoluteTimeGetCurrent()
    }
    
    /// Gets all running applications with their process IDs
    /// - Returns: Dictionary of application names to process IDs
    private func getAllRunningApplications() -> [String: pid_t] {
        var apps: [String: pid_t] = [:]
        
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if let name = app.localizedName {
                apps[name] = app.processIdentifier
            }
            if let bundleId = app.bundleIdentifier {
                apps[bundleId] = app.processIdentifier
            }
        }
        
        return apps
    }
}

// MARK: - Supporting Types

/// Target for background click operations
enum BackgroundClickTarget {
    case bundleIdentifier(String)
    case processName(String)
    case processId(pid_t)
}

/// Configuration for background click operations
struct BackgroundClickOperation {
    let target: BackgroundClickTarget
    let location: CGPoint
    let clickType: ClickType
    let delay: TimeInterval?
    
    init(target: BackgroundClickTarget, location: CGPoint, clickType: ClickType = .left, delay: TimeInterval? = nil) {
        self.target = target
        self.location = location
        self.clickType = clickType
        self.delay = delay
    }
}

// MARK: - Extensions

extension BackgroundClicker {
    
    /// Convenience method for left-clicking on an application
    /// - Parameters:
    ///   - bundleIdentifier: Bundle identifier of the target application
    ///   - location: Location to click
    /// - Returns: Result of the click operation
    func leftClickOnApp(bundleIdentifier: String, at location: CGPoint) async -> ClickResult {
        return await clickOnApplication(bundleIdentifier: bundleIdentifier, location: location, clickType: .left)
    }
    
    /// Convenience method for right-clicking on an application
    /// - Parameters:
    ///   - bundleIdentifier: Bundle identifier of the target application
    ///   - location: Location to click
    /// - Returns: Result of the click operation
    func rightClickOnApp(bundleIdentifier: String, at location: CGPoint) async -> ClickResult {
        return await clickOnApplication(bundleIdentifier: bundleIdentifier, location: location, clickType: .right)
    }
}