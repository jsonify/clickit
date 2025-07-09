import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    @State private var showingPermissionSetup = false
    
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
        .frame(width: 350, height: 500)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionManager.updatePermissionStatus()
        }
        .sheet(isPresented: $showingPermissionSetup) {
            PermissionRequestView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PermissionManager.shared)
}
