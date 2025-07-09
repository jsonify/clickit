import SwiftUI

/// Test view for window detection functionality
struct WindowDetectionTestView: View {
    @StateObject private var windowManager = WindowManager.shared
    @StateObject private var targeter = WindowTargeter.shared
    @StateObject private var tester = WindowDetectionTester.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedWindow: WindowInfo?
    @State private var showingTestResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.3.offgrid")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    
                    Text("Window Detection Test")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                // Controls
                HStack(spacing: 16) {
                    Button("Detect Windows") {
                        Task {
                            await windowManager.refreshWindows()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(windowManager.isDetecting)
                    
                    Button("Run Tests") {
                        showingTestResults = true
                        Task {
                            await tester.runComprehensiveTests()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(tester.isRunningTests)
                }
                
                // Status
                VStack(spacing: 8) {
                    if windowManager.isDetecting {
                        ProgressView("Detecting windows...")
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Found \(windowManager.availableWindows.count) windows")
                            .font(.headline)
                    }
                    
                    if let error = windowManager.lastError {
                        Text("Error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Window List
                if !windowManager.availableWindows.isEmpty {
                    List(windowManager.availableWindows) { window in
                        WindowRowView(window: window) {
                            selectedWindow = window
                            targeter.setTarget(window)
                        }
                    }
                    .listStyle(InsetListStyle())
                }
                
                Spacer()
                
                // Selected Window Info
                if let selected = selectedWindow {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Window:")
                            .font(.headline)
                        
                        Text(selected.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Valid: \(targeter.isTargetValid ? "✓" : "✗")")
                                .foregroundColor(targeter.isTargetValid ? .green : .red)
                            
                            Text("Background: \(targeter.supportsBackgroundClicking() ? "✓" : "✗")")
                                .foregroundColor(targeter.supportsBackgroundClicking() ? .green : .gray)
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Window Detection")
            .frame(minWidth: 600, minHeight: 500)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await windowManager.refreshWindows()
                }
            }
            .sheet(isPresented: $showingTestResults) {
                TestResultsView()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .frame(idealWidth: 800, idealHeight: 600)
    }
}

/// Row view for displaying window information
struct WindowRowView: View {
    let window: WindowInfo
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(window.shortDisplayName)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(window.statusDescription)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(statusColor)
            }
            
            HStack {
                Text("PID: \(window.processID)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(window.dimensionsString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private var statusColor: Color {
        if window.isMinimized {
            return .orange
        } else if window.isOnScreen {
            return .green
        } else {
            return .gray
        }
    }
}

/// Test results view
struct TestResultsView: View {
    @StateObject private var tester = WindowDetectionTester.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if tester.isRunningTests {
                    VStack(spacing: 16) {
                        ProgressView("Running tests...")
                            .progressViewStyle(CircularProgressViewStyle())
                        
                        ProgressView(value: tester.currentTestProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding()
                } else {
                    List(tester.testResults) { result in
                        TestResultRowView(result: result)
                    }
                    .listStyle(InsetListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Test Results")
            .frame(minWidth: 600, minHeight: 400)
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

/// Row view for displaying test results
struct TestResultRowView: View {
    let result: WindowTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.statusIcon)
                    .foregroundColor(result.success ? .green : .red)
                
                Text(result.testName)
                    .font(.headline)
                
                Spacer()
                
                Text(result.formattedExecutionTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.details)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if result.windowCount > 0 {
                Text("Windows: \(result.windowCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let error = result.error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WindowDetectionTestView()
}