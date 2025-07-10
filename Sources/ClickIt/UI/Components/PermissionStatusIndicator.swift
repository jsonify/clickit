import SwiftUI

struct PermissionStatusIndicator: View {
    @EnvironmentObject private var permissionManager: PermissionManager
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
            permissionManager.refreshPermissionStatus()
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
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: healthIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 12))
            
            Text(statusText)
                .font(.caption2)
                .foregroundColor(statusColor)
            
            Text("(\(healthPercentage)%)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var healthIcon: String {
        if permissionManager.allPermissionsGranted {
            return "checkmark.circle.fill"
        } else if permissionManager.accessibilityPermissionGranted || permissionManager.screenRecordingPermissionGranted {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if permissionManager.allPermissionsGranted {
            return .green
        } else if permissionManager.accessibilityPermissionGranted || permissionManager.screenRecordingPermissionGranted {
            return .orange
        } else {
            return .red
        }
    }
    
    private var statusText: String {
        if permissionManager.allPermissionsGranted {
            return "Healthy"
        } else if permissionManager.accessibilityPermissionGranted || permissionManager.screenRecordingPermissionGranted {
            return "Partial"
        } else {
            return "Unhealthy"
        }
    }
    
    private var healthPercentage: Int {
        let granted = [
            permissionManager.accessibilityPermissionGranted,
            permissionManager.screenRecordingPermissionGranted
        ].filter { $0 }.count
        
        return (granted * 100) / 2
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