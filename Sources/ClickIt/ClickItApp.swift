import SwiftUI

@main
struct ClickItApp: App {
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(permissionManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 350, height: 500)
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
