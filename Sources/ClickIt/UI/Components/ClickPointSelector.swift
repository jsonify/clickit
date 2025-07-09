import SwiftUI
import CoreGraphics

struct ClickPointSelector: View {
    @State private var selectedPoint: CGPoint?
    @State private var isSelecting = false
    @State private var manualX: String = ""
    @State private var manualY: String = ""
    @State private var showingManualInput = false
    @State private var validationError: String?
    
    let onPointSelected: (CGPoint) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("Click Point Selection")
                    .font(.headline)
                Spacer()
            }
            
            // Current selection display
            if let point = selectedPoint {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selected Point:")
                            .font(.subheadline)
                        Spacer()
                    }
                    
                    HStack {
                        Text("X: \(Int(point.x)), Y: \(Int(point.y))")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Selection methods
            VStack(spacing: 12) {
                // Click-to-set button
                Button {
                    if isSelecting {
                        cancelClickSelection()
                    } else {
                        startClickSelection()
                    }
                } label: {
                    HStack {
                        Image(systemName: isSelecting ? "stop.circle.fill" : "hand.tap.fill")
                        Text(isSelecting ? "Cancel Selection" : "Click to Set Point")
                    }
                    .foregroundColor(isSelecting ? .red : .blue)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                // Manual input toggle
                Button {
                    showingManualInput.toggle()
                } label: {
                    HStack {
                        Image(systemName: "keyboard")
                        Text(showingManualInput ? "Hide Manual Input" : "Manual Input")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            
            // Manual input section
            if showingManualInput {
                VStack(spacing: 12) {
                    Text("Manual Coordinate Input")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("X:")
                                .font(.caption)
                            TextField("X coordinate", text: $manualX)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Y:")
                                .font(.caption)
                            TextField("Y coordinate", text: $manualY)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    Button("Set Point") {
                        setManualPoint()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(manualX.isEmpty || manualY.isEmpty)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Validation error
            if let error = validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructions:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("• Click 'Click to Set Point' then click anywhere on screen")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("• Press ESC or click 'Cancel Selection' to cancel")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("• Or use manual input for precise coordinates")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func startClickSelection() {
        isSelecting = true
        clearValidationError()
        
        // Start global mouse click monitoring
        ClickCoordinateCapture.shared.startCapture { point in
            Task { @MainActor in
                isSelecting = false
                
                if let point = point {
                    if validateCoordinates(point) {
                        selectedPoint = point
                        onPointSelected(point)
                    }
                }
                // If point is nil, it means capture was cancelled (ESC key)
            }
        }
    }
    
    private func cancelClickSelection() {
        ClickCoordinateCapture.shared.stopCapture()
        isSelecting = false
        clearValidationError()
    }
    
    private func setManualPoint() {
        clearValidationError()
        
        guard let x = Double(manualX), let y = Double(manualY) else {
            validationError = "Invalid coordinates. Please enter valid numbers."
            return
        }
        
        let point = CGPoint(x: x, y: y)
        
        if validateCoordinates(point) {
            selectedPoint = point
            onPointSelected(point)
        }
    }
    
    private func validateCoordinates(_ point: CGPoint) -> Bool {
        // Get main screen bounds
        let screenFrame = NSScreen.main?.frame ?? CGRect.zero
        
        // Check if point is within screen bounds
        if !screenFrame.contains(point) {
            validationError = "Coordinates must be within screen bounds (0,0) to (\(Int(screenFrame.width)),\(Int(screenFrame.height)))"
            return false
        }
        
        return true
    }
    
    private func clearValidationError() {
        validationError = nil
    }
}

// MARK: - Click Coordinate Capture
@MainActor
class ClickCoordinateCapture: ObservableObject {
    private var mouseMonitor: Any?
    private var keyMonitor: Any?
    private var completion: ((CGPoint?) -> Void)?
    
    static let shared = ClickCoordinateCapture()
    
    private init() {}
    
    func startCapture(completion: @escaping @MainActor (CGPoint?) -> Void) {
        // Clean up any existing monitors
        stopCapture()
        
        self.completion = completion
        
        // Monitor for mouse clicks
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self = self else { return }
            
            let screenPoint = NSEvent.mouseLocation
            let convertedPoint = self.convertScreenCoordinates(screenPoint)
            
            // Clean up and call completion
            self.finishCapture(with: convertedPoint)
        }
        
        // Monitor for ESC key to cancel
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            // Check if ESC key was pressed (keyCode 53)
            if event.keyCode == 53 {
                self.finishCapture(with: nil)
            }
        }
    }
    
    func stopCapture() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        
        completion = nil
    }
    
    private func finishCapture(with point: CGPoint?) {
        let savedCompletion = completion
        stopCapture()
        
        Task { @MainActor in
            savedCompletion?(point)
        }
    }
    
    private func convertScreenCoordinates(_ screenPoint: CGPoint) -> CGPoint {
        guard let mainScreen = NSScreen.main else {
            return screenPoint
        }
        
        // Convert from macOS screen coordinates (origin at bottom-left) 
        // to standard coordinates (origin at top-left)
        return CGPoint(
            x: screenPoint.x,
            y: mainScreen.frame.height - screenPoint.y
        )
    }
}

#Preview {
    ClickPointSelector { point in
        print("Selected point: \(point)")
    }
    .frame(width: 400, height: 500)
}