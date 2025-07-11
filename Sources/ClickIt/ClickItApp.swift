import SwiftUI

@main
struct ClickItApp: App {
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var clickCoordinator = ClickCoordinator.shared
    @StateObject private var windowManager = WindowManager.shared
    @State private var permissionCheckTimer: Timer?
    
    init() {
        // Set app activation policy without forcing foreground
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            // Removed: NSApp.activate(ignoringOtherApps: true) - causes conflicts with system dialogs
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(permissionManager)
                .environmentObject(clickCoordinator)
                .environmentObject(windowManager)
                .onAppear {
                    // Gentle window activation that doesn't interfere with system dialogs
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                        // Removed: window.orderFrontRegardless() - causes conflicts with system dialogs
                    }
                    
                    // Start AutoCliq-style permission monitoring
                    startPermissionMonitoring()
                }
                .onDisappear {
                    stopPermissionMonitoring()
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 450, height: 700)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Permission Setup Guide") {
                    // Open permission setup guide
                    if let url = URL(string: "https://github.com/jsonify/clickit/wiki/Permission-Setup") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    // MARK: - AutoCliq-style Permission Monitoring
    
    private func startPermissionMonitoring() {
        // Check permissions every 2 seconds when app is visible (AutoCliq's approach)
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                permissionManager.updatePermissionStatus()
            }
        }
    }
    
    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
}
