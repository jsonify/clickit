import Foundation
import ApplicationServices
import SwiftUI

@MainActor
class PermissionStatusChecker: ObservableObject {
    static let shared = PermissionStatusChecker()
    
    @Published var isMonitoring: Bool = false
    @Published var lastStatusUpdate: Date = Date()
    
    private var monitoringTimer: Timer?
    private weak var permissionManager: PermissionManager?
    
    private init() {
        self.permissionManager = PermissionManager.shared
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Check permissions immediately
        checkPermissionStatus()
        
        // Set up periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermissionStatus()
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - Status Checking
    
    private func checkPermissionStatus() {
        permissionManager?.updatePermissionStatus()
        lastStatusUpdate = Date()
    }
    
    // MARK: - Detailed Status Information
    
    func getDetailedAccessibilityStatus() -> PermissionStatus {
        let granted = permissionManager?.checkAccessibilityPermission() ?? false
        
        return PermissionStatus(
            type: .accessibility,
            granted: granted,
            lastChecked: Date(),
            canRequest: !granted,
            systemSettingsRequired: !granted
        )
    }
    
    func getDetailedScreenRecordingStatus() -> PermissionStatus {
        let granted = permissionManager?.checkScreenRecordingPermission() ?? false
        
        return PermissionStatus(
            type: .screenRecording,
            granted: granted,
            lastChecked: Date(),
            canRequest: !granted,
            systemSettingsRequired: !granted
        )
    }
    
    func getAllPermissionStatuses() -> [PermissionStatus] {
        return [
            getDetailedAccessibilityStatus(),
            getDetailedScreenRecordingStatus()
        ]
    }
    
    // MARK: - Permission Health Check
    
    func performHealthCheck() -> PermissionHealthReport {
        let statuses = getAllPermissionStatuses()
        let grantedCount = statuses.filter { $0.granted }.count
        let totalCount = statuses.count
        
        let healthStatus: PermissionHealthStatus
        if grantedCount == totalCount {
            healthStatus = .healthy
        } else if grantedCount > 0 {
            healthStatus = .partial
        } else {
            healthStatus = .unhealthy
        }
        
        return PermissionHealthReport(
            status: healthStatus,
            grantedPermissions: grantedCount,
            totalPermissions: totalCount,
            permissionStatuses: statuses,
            lastChecked: Date(),
            recommendations: generateRecommendations(for: statuses)
        )
    }
    
    private func generateRecommendations(for statuses: [PermissionStatus]) -> [String] {
        var recommendations: [String] = []
        
        let missingPermissions = statuses.filter { !$0.granted }
        
        if missingPermissions.isEmpty {
            recommendations.append("All permissions are properly configured!")
        } else {
            recommendations.append("Missing permissions detected:")
            for permission in missingPermissions {
                recommendations.append("• Grant \(permission.type.rawValue) permission in System Settings")
            }
            recommendations.append("Use the 'Open System Settings' button to configure permissions")
        }
        
        return recommendations
    }
    
    // MARK: - Cleanup
    // Note: Timer will be invalidated automatically when the object is deallocated
}

// MARK: - Data Models

struct PermissionStatus {
    let type: PermissionType
    let granted: Bool
    let lastChecked: Date
    let canRequest: Bool
    let systemSettingsRequired: Bool
    
    var statusText: String {
        granted ? "Granted" : "Not Granted"
    }
    
    var statusColor: Color {
        granted ? .green : .red
    }
    
    var statusIcon: String {
        granted ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
}

struct PermissionHealthReport {
    let status: PermissionHealthStatus
    let grantedPermissions: Int
    let totalPermissions: Int
    let permissionStatuses: [PermissionStatus]
    let lastChecked: Date
    let recommendations: [String]
    
    var healthPercentage: Double {
        guard totalPermissions > 0 else { return 0.0 }
        return Double(grantedPermissions) / Double(totalPermissions) * 100.0
    }
    
    var statusText: String {
        switch status {
        case .healthy:
            return "All permissions granted"
        case .partial:
            return "Some permissions missing"
        case .unhealthy:
            return "Permissions required"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .healthy:
            return .green
        case .partial:
            return .orange
        case .unhealthy:
            return .red
        }
    }
}

enum PermissionHealthStatus {
    case healthy
    case partial
    case unhealthy
}