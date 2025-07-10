import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    @EnvironmentObject private var clickCoordinator: ClickCoordinator
    @EnvironmentObject private var windowManager: WindowManager
    @State private var showingPermissionSetup = false
    @State private var showingWindowDetectionTest = false
    @State private var selectedClickPoint: CGPoint?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Icon Placeholder
                Image(systemName: "cursorarrow.click.2")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                // App Title
                Text("ClickIt")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Subtitle
                Text("Precision Auto-Clicker for macOS")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Permission Status
                VStack(spacing: 10) {
                    if permissionManager.allPermissionsGranted {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Ready to use")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(12)
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
                        .padding(12)
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
                    
                    // Configuration Panel
                    ConfigurationPanel(selectedClickPoint: selectedClickPoint)
                    
                    // Development Tools
                    VStack(spacing: 10) {
                        Text("Development Tools")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
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
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Version Info
                VStack(spacing: 4) {
                    Text("Version \(AppConstants.appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Build \(AppConstants.buildNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Requires \(AppConstants.minimumOSVersion) or later")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .frame(width: 450, height: 900)
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
            
            let result = await clickCoordinator.performSingleClick(configuration: configuration)
            
            print("Click test result: \(result)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PermissionManager.shared)
        .environmentObject(ClickCoordinator.shared)
        .environmentObject(WindowManager.shared)
}
