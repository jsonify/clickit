import SwiftUI

struct PermissionRequestView: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    @ObservedObject private var statusChecker = PermissionStatusChecker.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDetailedInstructions = false
    @State private var selectedPermission: PermissionType?
    @State private var isRequestingPermissions = false
    @State private var showingRetryOptions = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text("Permissions Required")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("ClickIt needs the following permissions to function properly:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Permission List
            VStack(spacing: 16) {
                PermissionRow(
                    permission: .accessibility,
                    isGranted: permissionManager.accessibilityPermissionGranted,
                    onRequestPermission: { requestAccessibilityPermission() },
                    onShowInstructions: { showInstructions(for: .accessibility) }
                )

                PermissionRow(
                    permission: .screenRecording,
                    isGranted: permissionManager.screenRecordingPermissionGranted,
                    onRequestPermission: { requestScreenRecordingPermission() },
                    onShowInstructions: { showInstructions(for: .screenRecording) }
                )
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 12) {
                if permissionManager.allPermissionsGranted {
                    Button("Continue") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Reset & Request Permissions") {
                        requestAllPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isRequestingPermissions)

                    HStack(spacing: 12) {
                        Button("Open System Settings") {
                            permissionManager.openSystemSettings(for: .accessibility)
                        }
                        .buttonStyle(.bordered)

                        Button("Check Status") {
                            retryPermissionCheck()
                        }
                        .buttonStyle(.bordered)
                    }

                    if showingRetryOptions {
                        Button("Retry Permission Check") {
                            retryPermissionCheck()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }

                    Button("Need Help?") {
                        showingDetailedInstructions = true
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }

            // Status Footer
            if !permissionManager.allPermissionsGranted {
                VStack(spacing: 8) {
                    Text("Status: \(permissionStatusText)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Last checked: \(statusChecker.lastStatusUpdate.formatted(.dateTime.hour().minute().second()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: 500)
        .onAppear {
            statusChecker.startMonitoring()
            permissionManager.updatePermissionStatus()
        }
        .onDisappear {
            statusChecker.stopMonitoring()
        }
        .sheet(isPresented: $showingDetailedInstructions) {
            PermissionInstructionsView(permission: selectedPermission)
        }
        .overlay(
            Group {
                if isRequestingPermissions {
                    ProgressView("Requesting permissions...")
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
            }
        )
    }

    // MARK: - Helper Properties

    private var permissionStatusText: String {
        let granted = [
            permissionManager.accessibilityPermissionGranted,
            permissionManager.screenRecordingPermissionGranted
        ].filter { $0 }.count

        return "\(granted) of 2 permissions granted"
    }

    // MARK: - Actions

    private func requestAccessibilityPermission() {
        isRequestingPermissions = true
        Task {
            _ = await permissionManager.requestAccessibilityPermission()
            isRequestingPermissions = false

            if !permissionManager.accessibilityPermissionGranted {
                showingRetryOptions = true
            }
        }
    }

    private func requestScreenRecordingPermission() {
        isRequestingPermissions = true
        Task {
            _ = await permissionManager.requestScreenRecordingPermission()
            isRequestingPermissions = false

            if !permissionManager.screenRecordingPermissionGranted {
                showingRetryOptions = true
            }
        }
    }

    private func requestAllPermissions() {
        isRequestingPermissions = true
        Task {
            _ = await permissionManager.requestAllPermissions()
            isRequestingPermissions = false

            if !permissionManager.allPermissionsGranted {
                showingRetryOptions = true
            }
        }
    }

    private func retryPermissionCheck() {
        permissionManager.updatePermissionStatus()
        showingRetryOptions = false
    }

    private func showInstructions(for permission: PermissionType) {
        selectedPermission = permission
        showingDetailedInstructions = true
    }

}

// MARK: - Permission Row Component

struct PermissionRow: View {
    let permission: PermissionType
    let isGranted: Bool
    let onRequestPermission: () -> Void
    let onShowInstructions: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Permission Icon
            Image(systemName: permission.systemIcon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 24)

            // Permission Info
            VStack(alignment: .leading, spacing: 4) {
                Text(permission.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(permission.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status & Actions
            HStack(spacing: 8) {
                // Status Indicator
                Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(isGranted ? .green : .orange)

                // Action Button
                if !isGranted {
                    Button("Grant") {
                        onRequestPermission()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Help") {
                        onShowInstructions()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Permission Instructions View

struct PermissionInstructionsView: View {
    let permission: PermissionType?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let permission = permission {
                        // Specific Permission Instructions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(permission.rawValue) Permission")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text(PermissionManager.shared.getPermissionDescription(for: permission))
                                .font(.body)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("How to Grant Permission:")
                                    .font(.headline)

                                Text(PermissionManager.shared.getPermissionInstructions(for: permission))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }

                            Button("Open System Settings") {
                                PermissionManager.shared.openSystemSettings(for: permission)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        // General Instructions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Permission Setup Guide")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("ClickIt requires both Accessibility and Screen Recording permissions to function properly.")
                                .font(.body)
                                .foregroundColor(.secondary)

                            ForEach(PermissionType.allCases, id: \.self) { permissionType in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(permissionType.rawValue)
                                        .font(.headline)

                                    Text(PermissionManager.shared.getPermissionDescription(for: permissionType))
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }

                    // Troubleshooting Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Troubleshooting")
                            .font(.headline)

                        Text("• Make sure ClickIt is in the permission list")
                        Text("• Toggle the permission off and on again")
                        Text("• Restart ClickIt after granting permissions")
                        Text("• Contact support if issues persist")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Permission Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PermissionRequestView()
        .environmentObject(PermissionManager.shared)
}
