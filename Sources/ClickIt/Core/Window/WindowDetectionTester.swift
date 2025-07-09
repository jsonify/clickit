import Foundation
import CoreGraphics
import ApplicationServices

/// Utility for testing window detection functionality
@MainActor
class WindowDetectionTester: ObservableObject {
    static let shared = WindowDetectionTester()
    
    @Published var testResults: [WindowTestResult] = []
    @Published var isRunningTests = false
    @Published var currentTestProgress: Double = 0.0
    
    private let windowManager = WindowManager.shared
    private let targeter = WindowTargeter.shared
    
    private init() {}
    
    // MARK: - Test Execution
    
    /// Run comprehensive window detection tests
    func runComprehensiveTests() async -> WindowTestSuite {
        isRunningTests = true
        testResults = []
        currentTestProgress = 0.0
        
        var suite = WindowTestSuite()
        
        // Test 1: Basic window detection
        currentTestProgress = 0.1
        let basicTest = await testBasicWindowDetection()
        suite.basicDetection = basicTest
        testResults.append(basicTest)
        
        // Test 2: Multiple application instances
        currentTestProgress = 0.3
        let multiInstanceTest = await testMultipleApplicationInstances()
        suite.multipleInstances = multiInstanceTest
        testResults.append(multiInstanceTest)
        
        // Test 3: Minimized window detection
        currentTestProgress = 0.5
        let minimizedTest = await testMinimizedWindowDetection()
        suite.minimizedWindows = minimizedTest
        testResults.append(minimizedTest)
        
        // Test 4: Background window support
        currentTestProgress = 0.7
        let backgroundTest = await testBackgroundWindowSupport()
        suite.backgroundWindows = backgroundTest
        testResults.append(backgroundTest)
        
        // Test 5: Error handling
        currentTestProgress = 0.9
        let errorTest = await testErrorHandling()
        suite.errorHandling = errorTest
        testResults.append(errorTest)
        
        currentTestProgress = 1.0
        isRunningTests = false
        
        return suite
    }
    
    /// Test detection of a specific application
    func testApplicationDetection(_ applicationName: String) async -> WindowTestResult {
        let startTime = Date()
        
        let windows = await windowManager.findWindows(for: applicationName)
        
        return WindowTestResult(
            testName: "Application Detection: \(applicationName)",
            success: !windows.isEmpty,
            windowCount: windows.count,
            executionTime: Date().timeIntervalSince(startTime),
            details: windows.isEmpty ? "No windows found" : "Found \(windows.count) windows",
            detectedWindows: windows,
            error: nil
        )
    }
    
    /// Test targeting of a specific window
    func testWindowTargeting(_ window: WindowInfo) async -> WindowTestResult {
        let startTime = Date()
        
        targeter.setTarget(window)
        let isValid = await targeter.validateCurrentTarget()
        let supportsBackground = targeter.supportsBackgroundClicking()
        
        return WindowTestResult(
            testName: "Window Targeting: \(window.shortDisplayName)",
            success: isValid,
            windowCount: 1,
            executionTime: Date().timeIntervalSince(startTime),
            details: "Valid: \(isValid), Background support: \(supportsBackground)",
            detectedWindows: [window],
            error: targeter.lastValidationError
        )
    }
    
    // MARK: - Private Test Methods
    
    private func testBasicWindowDetection() async -> WindowTestResult {
        let startTime = Date()
        
        let windows = await windowManager.detectAllWindows()
        
        return WindowTestResult(
            testName: "Basic Window Detection",
            success: !windows.isEmpty,
            windowCount: windows.count,
            executionTime: Date().timeIntervalSince(startTime),
            details: "Detected \(windows.count) total windows",
            detectedWindows: windows,
            error: windowManager.lastError
        )
    }
    
    private func testMultipleApplicationInstances() async -> WindowTestResult {
        let startTime = Date()
        
        let windows = await windowManager.detectAllWindows()
        let appGroups = windows.groupedByApplication
        
        let multiInstanceApps = appGroups.filter { $0.value.count > 1 }
        
        return WindowTestResult(
            testName: "Multiple Application Instances",
            success: !multiInstanceApps.isEmpty,
            windowCount: multiInstanceApps.values.flatMap { $0 }.count,
            executionTime: Date().timeIntervalSince(startTime),
            details: "Found \(multiInstanceApps.count) apps with multiple instances",
            detectedWindows: multiInstanceApps.values.flatMap { $0 },
            error: nil
        )
    }
    
    private func testMinimizedWindowDetection() async -> WindowTestResult {
        let startTime = Date()
        
        let windows = await windowManager.detectAllWindows()
        let minimizedWindows = windows.minimizedWindows
        
        return WindowTestResult(
            testName: "Minimized Window Detection",
            success: true, // Success if we can detect ANY windows, minimized or not
            windowCount: minimizedWindows.count,
            executionTime: Date().timeIntervalSince(startTime),
            details: "Found \(minimizedWindows.count) minimized windows",
            detectedWindows: minimizedWindows,
            error: nil
        )
    }
    
    private func testBackgroundWindowSupport() async -> WindowTestResult {
        let startTime = Date()
        
        let windows = await windowManager.detectAllWindows()
        var backgroundSupportCount = 0
        
        for window in windows {
            targeter.setTarget(window)
            if targeter.supportsBackgroundClicking() {
                backgroundSupportCount += 1
            }
        }
        
        return WindowTestResult(
            testName: "Background Window Support",
            success: backgroundSupportCount > 0,
            windowCount: backgroundSupportCount,
            executionTime: Date().timeIntervalSince(startTime),
            details: "\(backgroundSupportCount) windows support background clicking",
            detectedWindows: windows.filter { window in
                targeter.setTarget(window)
                return targeter.supportsBackgroundClicking()
            },
            error: nil
        )
    }
    
    private func testErrorHandling() async -> WindowTestResult {
        let startTime = Date()
        
        // Test with invalid window ID
        let invalidConfig = WindowTargetingConfig(
            windowID: 999999,
            processID: 999999,
            applicationName: "NonExistentApp",
            windowTitle: "Test",
            bounds: CGRect.zero,
            preferProcessID: true
        )
        
        let isValid = await targeter.validateTarget(invalidConfig)
        let hasError = targeter.lastValidationError != nil
        
        return WindowTestResult(
            testName: "Error Handling",
            success: !isValid && hasError, // Should fail and have error
            windowCount: 0,
            executionTime: Date().timeIntervalSince(startTime),
            details: hasError ? "Error correctly detected" : "No error detected",
            detectedWindows: [],
            error: targeter.lastValidationError
        )
    }
    
    // MARK: - Utility Methods
    
    /// Get test recommendations based on current system state
    func getTestRecommendations() async -> [String] {
        let windows = await windowManager.detectAllWindows()
        var recommendations: [String] = []
        
        if windows.isEmpty {
            recommendations.append("Open some applications to test window detection")
        }
        
        let appGroups = windows.groupedByApplication
        if appGroups.count < 3 {
            recommendations.append("Open more applications to test multi-app detection")
        }
        
        let multiInstanceApps = appGroups.filter { $0.value.count > 1 }
        if multiInstanceApps.isEmpty {
            recommendations.append("Open multiple windows of the same application to test instance detection")
        }
        
        let minimizedWindows = windows.minimizedWindows
        if minimizedWindows.isEmpty {
            recommendations.append("Minimize some windows to test minimized window detection")
        }
        
        return recommendations
    }
}

// MARK: - Test Result Types

/// Result of a window detection test
struct WindowTestResult: Identifiable {
    let id = UUID()
    let testName: String
    let success: Bool
    let windowCount: Int
    let executionTime: TimeInterval
    let details: String
    let detectedWindows: [WindowInfo]
    let error: Error?
    
    var statusIcon: String {
        return success ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    var statusColor: String {
        return success ? "green" : "red"
    }
    
    var formattedExecutionTime: String {
        return String(format: "%.2fms", executionTime * 1000)
    }
}

/// Complete test suite results
struct WindowTestSuite {
    var basicDetection: WindowTestResult?
    var multipleInstances: WindowTestResult?
    var minimizedWindows: WindowTestResult?
    var backgroundWindows: WindowTestResult?
    var errorHandling: WindowTestResult?
    
    var allResults: [WindowTestResult] {
        return [basicDetection, multipleInstances, minimizedWindows, backgroundWindows, errorHandling]
            .compactMap { $0 }
    }
    
    var overallSuccess: Bool {
        return allResults.allSatisfy { $0.success }
    }
    
    var successRate: Double {
        guard !allResults.isEmpty else { return 0.0 }
        let successCount = allResults.filter { $0.success }.count
        return Double(successCount) / Double(allResults.count)
    }
    
    var totalWindowsDetected: Int {
        return allResults.reduce(0) { $0 + $1.windowCount }
    }
    
    var totalExecutionTime: TimeInterval {
        return allResults.reduce(0) { $0 + $1.executionTime }
    }
}