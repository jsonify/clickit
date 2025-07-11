import SwiftUI

struct PermissionStatusIndicator: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    @ObservedObject private var statusChecker = PermissionStatusChecker.shared
    @State private var showingPermissionView = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Status Icon
            Image(systemName: permissionManager.allPermissionsGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .foregroundColor(permissionManager.allPermissionsGranted ? .green : .orange)
                .font(.system(size: 16))
            
            // Status Text
            Text(statusText)
                .font(.caption)
                .foregroundColor(permissionManager.allPermissionsGranted ? .green : .orange)
            
            // Action Button
            if !permissionManager.allPermissionsGranted {
                Button("Fix") {
                    showingPermissionView = true
                }
                .buttonStyle(.borderless)
                .controlSize(.mini)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(6)
        .onAppear {
            statusChecker.startMonitoring()
        }
        .onDisappear {
            statusChecker.stopMonitoring()
        }
        .sheet(isPresented: $showingPermissionView) {
            PermissionRequestView()
        }
    }
    
    private var statusText: String {
        if permissionManager.allPermissionsGranted {
            return "Permissions OK"
        } else {
            let granted = [
                permissionManager.accessibilityPermissionGranted,
                permissionManager.screenRecordingPermissionGranted
            ].filter { $0 }.count
            
            return "Permissions: \(granted)/2"
        }
    }
    
    private var backgroundColor: Color {
        if permissionManager.allPermissionsGranted {
            return Color.green.opacity(0.1)
        } else {
            return Color.orange.opacity(0.1)
        }
    }
}

// MARK: - Compact Permission Status

struct CompactPermissionStatus: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    let showText: Bool
    
    init(showText: Bool = true) {
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Individual permission indicators
            PermissionDot(
                isGranted: permissionManager.accessibilityPermissionGranted,
                tooltip: "Accessibility Permission"
            )
            
            PermissionDot(
                isGranted: permissionManager.screenRecordingPermissionGranted,
                tooltip: "Screen Recording Permission"
            )
            
            if showText {
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var statusText: String {
        if permissionManager.allPermissionsGranted {
            return "Ready"
        } else {
            return "Setup needed"
        }
    }
}

// MARK: - Permission Dot Indicator

struct PermissionDot: View {
    let isGranted: Bool
    let tooltip: String
    
    var body: some View {
        Circle()
            .fill(isGranted ? Color.green : Color.red)
            .frame(width: 8, height: 8)
            .help(tooltip)
    }
}

// MARK: - Permission Health Badge

struct PermissionHealthBadge: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    @ObservedObject private var statusChecker = PermissionStatusChecker.shared
    @State private var healthReport: PermissionHealthReport?
    
    var body: some View {
        Group {
            if let report = healthReport {
                HStack(spacing: 6) {
                    Image(systemName: healthIcon(for: report.status))
                        .foregroundColor(report.statusColor)
                        .font(.system(size: 12))
                    
                    Text(report.statusText)
                        .font(.caption2)
                        .foregroundColor(report.statusColor)
                    
                    Text("(\(Int(report.healthPercentage))%)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(report.statusColor.opacity(0.1))
                .cornerRadius(4)
            } else {
                Text("Checking...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            updateHealthReport()
        }
        .onReceive(statusChecker.$lastStatusUpdate) { _ in
            updateHealthReport()
        }
    }
    
    private func updateHealthReport() {
        healthReport = statusChecker.performHealthCheck()
    }
    
    private func healthIcon(for status: PermissionHealthStatus) -> String {
        switch status {
        case .healthy:
            return "checkmark.circle.fill"
        case .partial:
            return "exclamationmark.triangle.fill"
        case .unhealthy:
            return "xmark.circle.fill"
        }
    }
}

#Preview("Permission Status Indicator") {
    VStack(spacing: 16) {
        PermissionStatusIndicator()
        CompactPermissionStatus()
        PermissionHealthBadge()
    }
    .padding()
    .environmentObject(PermissionManager.shared)
}