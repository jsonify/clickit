import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    @State private var showingPermissionSetup = false
    @State private var showingWindowDetectionTest = false
    @State private var selectedClickPoint: CGPoint?
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon Placeholder
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            // App Title
            Text("ClickIt")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Subtitle
            Text("Precision Auto-Clicker for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Permission Status
            VStack(spacing: 12) {
                if permissionManager.allPermissionsGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Ready to use")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.shield")
                                .foregroundColor(.orange)
                            Text("Permissions Required")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Button("Setup Permissions") {
                            showingPermissionSetup = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Compact permission status
                CompactPermissionStatus()
            }
            
            // Click Point Selection (only show when permissions are granted)
            if permissionManager.allPermissionsGranted {
                ClickPointSelector { point in
                    selectedClickPoint = point
                }
                
                // Development Tools
                VStack(spacing: 12) {
                    Text("Development Tools")
                        .font(.headline)
                    
                    Button("Test Window Detection") {
                        showingWindowDetectionTest = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    if let point = selectedClickPoint {
                        Button("Test Click at Selected Point") {
                            testClickAtPoint(point)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Version Info
            VStack(spacing: 4) {
                Text("Version \(AppConstants.appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Build \(AppConstants.buildNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // System Requirements
            Text("Requires \(AppConstants.minimumOSVersion) or later")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 450, height: 700)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionManager.updatePermissionStatus()
        }
        .sheet(isPresented: $showingPermissionSetup) {
            PermissionRequestView()
        }
        .sheet(isPresented: $showingWindowDetectionTest) {
            WindowDetectionTestView()
        }
    }
    
    private func testClickAtPoint(_ point: CGPoint) {
        Task {
            let configuration = ClickConfiguration(
                type: .left,
                location: point,
                targetPID: nil,
                delayBetweenDownUp: 0.01
            )
            
            let result = await ClickCoordinator.shared.performSingleClick(configuration: configuration)
            
            print("Click test result: \(result)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PermissionManager.shared)
}
