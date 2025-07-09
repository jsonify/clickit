import SwiftUI

@main
struct ClickItApp: App {
    @StateObject private var permissionManager = PermissionManager.shared
    
    init() {
        // Force app to appear in foreground when launched from command line
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(permissionManager)
                .onAppear {
                    // Additional window activation
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                        window.orderFrontRegardless()
                    }
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
}
