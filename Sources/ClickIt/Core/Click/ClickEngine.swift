import Foundation
import CoreGraphics
import ApplicationServices

/// High-performance click engine for mouse event generation
class ClickEngine: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Shared instance of the click engine
    static let shared = ClickEngine()
    
    /// Queue for handling click operations
    private let clickQueue = DispatchQueue(label: "com.clickit.click-engine", qos: .userInteractive)
    
    /// Timer for precision measurement
    private var precisionTimer: CFAbsoluteTime = 0
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Performs a single click operation
    /// - Parameter configuration: Click configuration specifying type, location, and options
    /// - Returns: Result of the click operation
    func performClick(configuration: ClickConfiguration) async -> ClickResult {
        return await withCheckedContinuation { continuation in
            clickQueue.async {
                let result = self.executeClick(configuration: configuration)
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Performs a click operation synchronously
    /// - Parameter configuration: Click configuration specifying type, location, and options
    /// - Returns: Result of the click operation
    func performClickSync(configuration: ClickConfiguration) -> ClickResult {
        return executeClick(configuration: configuration)
    }
    
    /// Performs a sequence of clicks
    /// - Parameter configurations: Array of click configurations
    /// - Returns: Array of click results
    func performClickSequence(configurations: [ClickConfiguration]) async -> [ClickResult] {
        var results: [ClickResult] = []
        
        for config in configurations {
            let result = await performClick(configuration: config)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Private Methods
    
    /// Executes a click operation on the current queue
    /// - Parameter configuration: Click configuration
    /// - Returns: Result of the click operation
    private func executeClick(configuration: ClickConfiguration) -> ClickResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Validate location
        guard isValidLocation(configuration.location) else {
            return ClickResult(
                success: false,
                actualLocation: configuration.location,
                timestamp: startTime,
                error: .invalidLocation
            )
        }
        
        // Create mouse down event
        guard let mouseDownEvent = createMouseEvent(
            type: configuration.type.mouseDownEventType,
            location: configuration.location,
            button: configuration.type.mouseButton
        ) else {
            return ClickResult(
                success: false,
                actualLocation: configuration.location,
                timestamp: startTime,
                error: .eventCreationFailed
            )
        }
        
        // Create mouse up event
        guard let mouseUpEvent = createMouseEvent(
            type: configuration.type.mouseUpEventType,
            location: configuration.location,
            button: configuration.type.mouseButton
        ) else {
            return ClickResult(
                success: false,
                actualLocation: configuration.location,
                timestamp: startTime,
                error: .eventCreationFailed
            )
        }
        
        // Post events
        let postResult = postMouseEvents(
            downEvent: mouseDownEvent,
            upEvent: mouseUpEvent,
            targetPID: configuration.targetPID,
            delay: configuration.delayBetweenDownUp
        )
        
        let _ = CFAbsoluteTimeGetCurrent()
        
        return ClickResult(
            success: postResult.success,
            actualLocation: configuration.location,
            timestamp: startTime,
            error: postResult.error
        )
    }
    
    /// Creates a mouse event
    /// - Parameters:
    ///   - type: Type of mouse event
    ///   - location: Location of the event
    ///   - button: Mouse button
    /// - Returns: Created mouse event or nil if creation failed
    private func createMouseEvent(type: CGEventType, location: CGPoint, button: CGMouseButton) -> CGEvent? {
        return CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: location,
            mouseButton: button
        )
    }
    
    /// Posts mouse down and up events with precise timing
    /// - Parameters:
    ///   - downEvent: Mouse down event
    ///   - upEvent: Mouse up event
    ///   - targetPID: Target process ID (nil for system-wide)
    ///   - delay: Delay between down and up events
    /// - Returns: Result of posting operation
    private func postMouseEvents(
        downEvent: CGEvent,
        upEvent: CGEvent,
        targetPID: pid_t?,
        delay: TimeInterval
    ) -> (success: Bool, error: ClickError?) {
        
        let startTime = mach_absolute_time()
        
        // Post mouse down event
        let downResult = postEvent(downEvent, targetPID: targetPID)
        guard downResult.success else {
            return (false, downResult.error)
        }
        
        // Precise delay between down and up
        if delay > 0 {
            usleep(UInt32(delay * 1_000_000)) // Convert to microseconds
        }
        
        // Post mouse up event
        let upResult = postEvent(upEvent, targetPID: targetPID)
        guard upResult.success else {
            return (false, upResult.error)
        }
        
        let endTime = mach_absolute_time()
        
        // Validate timing precision (within 5ms)
        let timeInfo = mach_timebase_info()
        let elapsedNanos = (endTime - startTime) * UInt64(timeInfo.numer) / UInt64(timeInfo.denom)
        let elapsedMillis = Double(elapsedNanos) / 1_000_000.0
        
        if elapsedMillis > (delay * 1000 + AppConstants.maxClickTimingDeviation * 1000) {
            return (false, .timingConstraintViolation)
        }
        
        return (true, nil)
    }
    
    /// Posts a single event to the system or target process
    /// - Parameters:
    ///   - event: Event to post
    ///   - targetPID: Target process ID (nil for system-wide)
    /// - Returns: Result of posting operation
    private func postEvent(_ event: CGEvent, targetPID: pid_t?) -> (success: Bool, error: ClickError?) {
        if let pid = targetPID {
            // Post to specific process
            event.postToPid(pid)
        } else {
            // Post system-wide
            event.post(tap: .cghidEventTap)
        }
        
        return (true, nil)
    }
    
    /// Validates if a location is within screen bounds
    /// - Parameter location: Location to validate
    /// - Returns: True if location is valid, false otherwise
    private func isValidLocation(_ location: CGPoint) -> Bool {
        let screenBounds = CGDisplayBounds(CGMainDisplayID())
        return screenBounds.contains(location)
    }
}

// MARK: - Extensions

extension ClickEngine {
    
    /// Convenience method for performing a left click
    /// - Parameters:
    ///   - location: Location to click
    ///   - targetPID: Target process ID (optional)
    /// - Returns: Result of the click operation
    func leftClick(at location: CGPoint, targetPID: pid_t? = nil) async -> ClickResult {
        let config = ClickConfiguration(type: .left, location: location, targetPID: targetPID)
        return await performClick(configuration: config)
    }
    
    /// Convenience method for performing a right click
    /// - Parameters:
    ///   - location: Location to click
    ///   - targetPID: Target process ID (optional)
    /// - Returns: Result of the click operation
    func rightClick(at location: CGPoint, targetPID: pid_t? = nil) async -> ClickResult {
        let config = ClickConfiguration(type: .right, location: location, targetPID: targetPID)
        return await performClick(configuration: config)
    }
    
    /// Convenience method for performing a left click synchronously
    /// - Parameters:
    ///   - location: Location to click
    ///   - targetPID: Target process ID (optional)
    /// - Returns: Result of the click operation
    func leftClickSync(at location: CGPoint, targetPID: pid_t? = nil) -> ClickResult {
        let config = ClickConfiguration(type: .left, location: location, targetPID: targetPID)
        return performClickSync(configuration: config)
    }
    
    /// Convenience method for performing a right click synchronously
    /// - Parameters:
    ///   - location: Location to click
    ///   - targetPID: Target process ID (optional)
    /// - Returns: Result of the click operation
    func rightClickSync(at location: CGPoint, targetPID: pid_t? = nil) -> ClickResult {
        let config = ClickConfiguration(type: .right, location: location, targetPID: targetPID)
        return performClickSync(configuration: config)
    }
}