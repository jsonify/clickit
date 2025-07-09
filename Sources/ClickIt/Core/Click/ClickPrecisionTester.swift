import Foundation
import CoreGraphics
import ApplicationServices

/// Utilities for testing click precision and timing accuracy
class ClickPrecisionTester: @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Shared instance of the precision tester
    static let shared = ClickPrecisionTester()
    
    /// Maximum allowed timing deviation (from AppConstants)
    private let maxTimingDeviation: TimeInterval = AppConstants.maxClickTimingDeviation
    
    /// Maximum allowed position deviation (from AppConstants)
    private let maxPositionDeviation: CGFloat = AppConstants.maxClickPositionDeviation
    
    /// Test results storage
    private var testResults: [PrecisionTestResult] = []
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Runs a comprehensive precision test suite
    /// - Parameters:
    ///   - iterations: Number of test iterations
    ///   - testLocations: Array of test locations
    /// - Returns: Overall test results
    func runPrecisionTestSuite(iterations: Int = 100, testLocations: [CGPoint]? = nil) async -> PrecisionTestSuite {
        let locations = testLocations ?? generateTestLocations()
        var suiteResults: [PrecisionTestResult] = []
        
        for location in locations {
            let result = await testClickPrecision(at: location, iterations: iterations)
            suiteResults.append(result)
        }
        
        return PrecisionTestSuite(
            totalTests: suiteResults.count * iterations,
            results: suiteResults,
            overallAccuracy: calculateOverallAccuracy(results: suiteResults),
            overallTiming: calculateOverallTiming(results: suiteResults)
        )
    }
    
    /// Tests click precision at a specific location
    /// - Parameters:
    ///   - location: Location to test
    ///   - iterations: Number of test iterations
    /// - Returns: Test results for the location
    func testClickPrecision(at location: CGPoint, iterations: Int = 50) async -> PrecisionTestResult {
        var timingResults: [TimeInterval] = []
        var positionResults: [CGPoint] = []
        var successCount = 0
        
        for _ in 0..<iterations {
            let startTime = mach_absolute_time()
            
            let config = ClickConfiguration(type: .left, location: location)
            let result = await ClickEngine.shared.performClick(configuration: config)
            
            let endTime = mach_absolute_time()
            let timing = machTimeToSeconds(endTime - startTime)
            
            timingResults.append(timing)
            positionResults.append(result.actualLocation)
            
            if result.success {
                successCount += 1
            }
        }
        
        return PrecisionTestResult(
            testLocation: location,
            iterations: iterations,
            successRate: Double(successCount) / Double(iterations),
            timingResults: TimingTestResult(
                measurements: timingResults,
                average: timingResults.reduce(0, +) / Double(timingResults.count),
                minimum: timingResults.min() ?? 0,
                maximum: timingResults.max() ?? 0,
                standardDeviation: calculateStandardDeviation(timingResults),
                withinTolerance: timingResults.allSatisfy { $0 <= maxTimingDeviation }
            ),
            positionResults: PositionTestResult(
                measurements: positionResults,
                averageDeviation: calculateAveragePositionDeviation(expected: location, actual: positionResults),
                maximumDeviation: calculateMaximumPositionDeviation(expected: location, actual: positionResults),
                withinTolerance: positionResults.allSatisfy { distance(from: location, to: $0) <= maxPositionDeviation }
            )
        )
    }
    
    /// Tests background clicking precision
    /// - Parameters:
    ///   - bundleIdentifier: Target application bundle identifier
    ///   - location: Location to test
    ///   - iterations: Number of test iterations
    /// - Returns: Test results for background clicking
    func testBackgroundClickPrecision(
        bundleIdentifier: String,
        at location: CGPoint,
        iterations: Int = 30
    ) async -> PrecisionTestResult {
        var timingResults: [TimeInterval] = []
        var positionResults: [CGPoint] = []
        var successCount = 0
        
        for _ in 0..<iterations {
            let startTime = mach_absolute_time()
            
            let result = await BackgroundClicker.shared.clickOnApplication(
                bundleIdentifier: bundleIdentifier,
                location: location,
                clickType: .left
            )
            
            let endTime = mach_absolute_time()
            let timing = machTimeToSeconds(endTime - startTime)
            
            timingResults.append(timing)
            positionResults.append(result.actualLocation)
            
            if result.success {
                successCount += 1
            }
        }
        
        return PrecisionTestResult(
            testLocation: location,
            iterations: iterations,
            successRate: Double(successCount) / Double(iterations),
            timingResults: TimingTestResult(
                measurements: timingResults,
                average: timingResults.reduce(0, +) / Double(timingResults.count),
                minimum: timingResults.min() ?? 0,
                maximum: timingResults.max() ?? 0,
                standardDeviation: calculateStandardDeviation(timingResults),
                withinTolerance: timingResults.allSatisfy { $0 <= maxTimingDeviation }
            ),
            positionResults: PositionTestResult(
                measurements: positionResults,
                averageDeviation: calculateAveragePositionDeviation(expected: location, actual: positionResults),
                maximumDeviation: calculateMaximumPositionDeviation(expected: location, actual: positionResults),
                withinTolerance: positionResults.allSatisfy { distance(from: location, to: $0) <= maxPositionDeviation }
            )
        )
    }
    
    /// Benchmarks click performance
    /// - Parameters:
    ///   - duration: Duration of the benchmark in seconds
    ///   - location: Location to click
    /// - Returns: Performance benchmark results
    func benchmarkClickPerformance(duration: TimeInterval = 10.0, at location: CGPoint) async -> PerformanceBenchmark {
        let startTime = CFAbsoluteTimeGetCurrent()
        var clickCount = 0
        var totalTiming: TimeInterval = 0
        
        while CFAbsoluteTimeGetCurrent() - startTime < duration {
            let clickStartTime = mach_absolute_time()
            
            let config = ClickConfiguration(type: .left, location: location)
            let result = await ClickEngine.shared.performClick(configuration: config)
            
            let clickEndTime = mach_absolute_time()
            let clickTiming = machTimeToSeconds(clickEndTime - clickStartTime)
            
            if result.success {
                clickCount += 1
                totalTiming += clickTiming
            }
        }
        
        let actualDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        return PerformanceBenchmark(
            duration: actualDuration,
            totalClicks: clickCount,
            clicksPerSecond: Double(clickCount) / actualDuration,
            averageClickTime: totalTiming / Double(clickCount),
            efficiency: Double(clickCount) / (actualDuration * 1000) // clicks per millisecond
        )
    }
    
    /// Validates system requirements for precision clicking
    /// - Returns: System validation results
    func validateSystemRequirements() -> SystemValidationResult {
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Check permissions
        let accessibilityEnabled = AXIsProcessTrusted()
        if !accessibilityEnabled {
            issues.append("Accessibility permissions not granted")
            recommendations.append("Grant accessibility permissions in System Preferences")
        }
        
        // Check display configuration
        let displayCount = CGGetActiveDisplayList(0, nil, nil)
        if displayCount != CGError.success {
            issues.append("Unable to detect display configuration")
        }
        
        // Check system performance
        let systemInfo = ProcessInfo.processInfo
        let memoryGB = Double(systemInfo.physicalMemory) / 1_073_741_824 // Convert to GB
        
        if memoryGB < AppConstants.minimumMemoryRequirementGB {
            recommendations.append("Consider upgrading to at least \(Int(AppConstants.minimumMemoryRequirementGB))GB RAM for optimal performance")
        }
        
        return SystemValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            recommendations: recommendations,
            systemInfo: SystemInfo(
                osVersion: systemInfo.operatingSystemVersionString,
                availableMemory: memoryGB,
                processorCount: systemInfo.processorCount,
                accessibilityEnabled: accessibilityEnabled
            )
        )
    }
    
    // MARK: - Private Methods
    
    /// Generates test locations across the screen
    /// - Returns: Array of test locations
    private func generateTestLocations() -> [CGPoint] {
        let screenBounds = CGDisplayBounds(CGMainDisplayID())
        let margin: CGFloat = 50
        
        return [
            CGPoint(x: screenBounds.minX + margin, y: screenBounds.minY + margin), // Top-left
            CGPoint(x: screenBounds.midX, y: screenBounds.minY + margin), // Top-center
            CGPoint(x: screenBounds.maxX - margin, y: screenBounds.minY + margin), // Top-right
            CGPoint(x: screenBounds.minX + margin, y: screenBounds.midY), // Middle-left
            CGPoint(x: screenBounds.midX, y: screenBounds.midY), // Center
            CGPoint(x: screenBounds.maxX - margin, y: screenBounds.midY), // Middle-right
            CGPoint(x: screenBounds.minX + margin, y: screenBounds.maxY - margin), // Bottom-left
            CGPoint(x: screenBounds.midX, y: screenBounds.maxY - margin), // Bottom-center
            CGPoint(x: screenBounds.maxX - margin, y: screenBounds.maxY - margin) // Bottom-right
        ]
    }
    
    /// Converts mach time to seconds
    /// - Parameter machTime: Mach time value
    /// - Returns: Time in seconds
    private func machTimeToSeconds(_ machTime: UInt64) -> TimeInterval {
        var timebase = mach_timebase_info()
        mach_timebase_info(&timebase)
        return Double(machTime) * Double(timebase.numer) / Double(timebase.denom) / 1_000_000_000
    }
    
    /// Calculates standard deviation for timing measurements
    /// - Parameter values: Array of timing values
    /// - Returns: Standard deviation
    private func calculateStandardDeviation(_ values: [TimeInterval]) -> TimeInterval {
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    /// Calculates average position deviation
    /// - Parameters:
    ///   - expected: Expected position
    ///   - actual: Array of actual positions
    /// - Returns: Average deviation in pixels
    private func calculateAveragePositionDeviation(expected: CGPoint, actual: [CGPoint]) -> CGFloat {
        let totalDeviation = actual.reduce(0.0) { sum, point in
            sum + distance(from: expected, to: point)
        }
        return totalDeviation / CGFloat(actual.count)
    }
    
    /// Calculates maximum position deviation
    /// - Parameters:
    ///   - expected: Expected position
    ///   - actual: Array of actual positions
    /// - Returns: Maximum deviation in pixels
    private func calculateMaximumPositionDeviation(expected: CGPoint, actual: [CGPoint]) -> CGFloat {
        return actual.map { distance(from: expected, to: $0) }.max() ?? 0
    }
    
    /// Calculates distance between two points
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: Distance in pixels
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Calculates overall accuracy from test results
    /// - Parameter results: Array of test results
    /// - Returns: Overall accuracy percentage
    private func calculateOverallAccuracy(results: [PrecisionTestResult]) -> Double {
        let totalAccuracy = results.reduce(0.0) { sum, result in
            sum + result.successRate
        }
        return totalAccuracy / Double(results.count)
    }
    
    /// Calculates overall timing from test results
    /// - Parameter results: Array of test results
    /// - Returns: Overall timing statistics
    private func calculateOverallTiming(results: [PrecisionTestResult]) -> TimingTestResult {
        let allMeasurements = results.flatMap { $0.timingResults.measurements }
        
        return TimingTestResult(
            measurements: allMeasurements,
            average: allMeasurements.reduce(0, +) / Double(allMeasurements.count),
            minimum: allMeasurements.min() ?? 0,
            maximum: allMeasurements.max() ?? 0,
            standardDeviation: calculateStandardDeviation(allMeasurements),
            withinTolerance: allMeasurements.allSatisfy { $0 <= maxTimingDeviation }
        )
    }
}

// MARK: - Test Result Types

/// Result of a precision test at a specific location
struct PrecisionTestResult {
    let testLocation: CGPoint
    let iterations: Int
    let successRate: Double
    let timingResults: TimingTestResult
    let positionResults: PositionTestResult
}

/// Results of timing precision tests
struct TimingTestResult {
    let measurements: [TimeInterval]
    let average: TimeInterval
    let minimum: TimeInterval
    let maximum: TimeInterval
    let standardDeviation: TimeInterval
    let withinTolerance: Bool
}

/// Results of position precision tests
struct PositionTestResult {
    let measurements: [CGPoint]
    let averageDeviation: CGFloat
    let maximumDeviation: CGFloat
    let withinTolerance: Bool
}

/// Comprehensive test suite results
struct PrecisionTestSuite {
    let totalTests: Int
    let results: [PrecisionTestResult]
    let overallAccuracy: Double
    let overallTiming: TimingTestResult
}

/// Performance benchmark results
struct PerformanceBenchmark {
    let duration: TimeInterval
    let totalClicks: Int
    let clicksPerSecond: Double
    let averageClickTime: TimeInterval
    let efficiency: Double
}

/// System validation results
struct SystemValidationResult {
    let isValid: Bool
    let issues: [String]
    let recommendations: [String]
    let systemInfo: SystemInfo
}

/// System information for validation
struct SystemInfo {
    let osVersion: String
    let availableMemory: Double
    let processorCount: Int
    let accessibilityEnabled: Bool
}