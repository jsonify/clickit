import Foundation
import AppKit
import CoreGraphics
import SwiftUI

/// Visual feedback overlay system for showing click points and automation status
@MainActor
class VisualFeedbackOverlay: ObservableObject {
    
    // MARK: - Properties
    
    /// Shared instance of the visual feedback overlay
    static let shared = VisualFeedbackOverlay()
    
    /// Whether the overlay is currently visible
    @Published var isVisible: Bool = false
    
    /// Current click location being displayed
    @Published var clickLocation: CGPoint = .zero
    
    /// Whether automation is currently active (affects visual style)
    @Published var isAutomationActive: Bool = false
    
    /// Overlay window for displaying visual feedback
    private var overlayWindow: NSWindow?
    
    /// View controller for managing the overlay content
    private var overlayViewController: OverlayViewController?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Shows the visual feedback overlay at the specified location
    /// - Parameters:
    ///   - location: Screen coordinates where to show the overlay
    ///   - isActive: Whether automation is currently active
    func showOverlay(at location: CGPoint, isActive: Bool = false) {
        print("VisualFeedbackOverlay: showOverlay called at \(location), isActive: \(isActive)")
        
        // Ensure all UI operations happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard !self.isVisible else {
                print("VisualFeedbackOverlay: overlay already visible, updating...")
                self.updateOverlay(at: location, isActive: isActive)
                return
            }
            
            self.clickLocation = location
            self.isAutomationActive = isActive
            
            print("VisualFeedbackOverlay: creating overlay window on main thread")
            self.createOverlayWindow()
            self.positionOverlay(at: location)
            self.showOverlayWindow()
            
            self.isVisible = true
            print("VisualFeedbackOverlay: overlay created and shown successfully")
        }
    }
    
    /// Updates the overlay position and state
    /// - Parameters:
    ///   - location: New screen coordinates
    ///   - isActive: Whether automation is currently active
    func updateOverlay(at location: CGPoint, isActive: Bool) {
        guard isVisible, overlayWindow != nil else { return }
        
        clickLocation = location
        isAutomationActive = isActive
        
        positionOverlay(at: location)
        
        // Update the overlay view appearance
        overlayViewController?.updateAppearance(isActive: isActive)
    }
    
    /// Hides the visual feedback overlay
    func hideOverlay() {
        print("VisualFeedbackOverlay: hideOverlay() called, isVisible: \(isVisible)")
        
        // Ensure all UI operations happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard self.isVisible else { 
                print("VisualFeedbackOverlay: overlay not visible, returning early")
                return 
            }
            
            print("VisualFeedbackOverlay: closing overlay window on main thread")
            self.overlayWindow?.close()
            self.overlayWindow = nil
            self.overlayViewController = nil
            
            self.isVisible = false
            print("VisualFeedbackOverlay: overlay hidden successfully")
        }
    }
    
    /// Shows a brief pulse animation at the specified location
    /// - Parameter location: Screen coordinates for the pulse
    func showClickPulse(at location: CGPoint) {
        // Show overlay briefly for visual feedback
        showOverlay(at: location, isActive: isAutomationActive)
        
        // Hide after a short duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let self = self, !self.isAutomationActive {
                self.hideOverlay()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates the overlay window with proper configuration
    private func createOverlayWindow() {
        print("VisualFeedbackOverlay: Starting createOverlayWindow()")
        
        // Create window with transparent background
        print("VisualFeedbackOverlay: Creating NSWindow...")
        let windowRect = NSRect(x: 0, y: 0, width: 60, height: 60)
        print("VisualFeedbackOverlay: Window rect: \(windowRect)")
        overlayWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = overlayWindow else { 
            print("VisualFeedbackOverlay: ERROR - Failed to create NSWindow")
            return 
        }
        print("VisualFeedbackOverlay: NSWindow created successfully")
        
        // Configure window properties
        print("VisualFeedbackOverlay: Configuring window properties...")
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = NSWindow.Level.floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        print("VisualFeedbackOverlay: Window properties configured")
        
        // Create and set up the view controller
        print("VisualFeedbackOverlay: Creating OverlayViewController...")
        overlayViewController = OverlayViewController()
        print("VisualFeedbackOverlay: Setting contentViewController...")
        window.contentViewController = overlayViewController
        
        // Set the initial automation state
        print("VisualFeedbackOverlay: Setting initial automation state: \(isAutomationActive)")
        overlayViewController?.updateAppearance(isActive: isAutomationActive)
        
        // Ensure window maintains its size
        print("VisualFeedbackOverlay: Window frame after ViewController: \(window.frame)")
        if window.frame.size.width == 0 || window.frame.size.height == 0 {
            print("VisualFeedbackOverlay: FIXING window size from \(window.frame.size)")
            window.setContentSize(NSSize(width: 60, height: 60))
            print("VisualFeedbackOverlay: Window size fixed to: \(window.frame.size)")
        }
        
        print("VisualFeedbackOverlay: createOverlayWindow() completed successfully")
    }
    
    /// Positions the overlay window at the specified location
    /// - Parameter location: Screen coordinates (Core Graphics coordinate system)
    private func positionOverlay(at location: CGPoint) {
        guard let window = overlayWindow else { 
            print("VisualFeedbackOverlay: ERROR - no window to position")
            return 
        }
        
        print("VisualFeedbackOverlay: Positioning overlay at \(location)")
        
        // Get screen info
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let screenWidth = NSScreen.main?.frame.width ?? 0
        print("VisualFeedbackOverlay: Screen dimensions: \(screenWidth) x \(screenHeight)")
        
        // Get the screen that contains the click point
        let targetScreen = NSScreen.screens.first { screen in
            let frame = screen.frame
            return location.x >= frame.minX && location.x <= frame.maxX &&
                   location.y >= frame.minY && location.y <= frame.maxY
        } ?? NSScreen.main
        
        let screenFrame = targetScreen?.frame ?? NSScreen.main?.frame ?? NSRect.zero
        print("VisualFeedbackOverlay: Target screen frame: \(screenFrame)")
        
        // Click coordinates are now in AppKit coordinates (bottom-left origin)
        // from NSEvent.mouseLocation, so we can use them directly
        print("VisualFeedbackOverlay: Click coordinates are in AppKit format (bottom-left origin)")
        print("VisualFeedbackOverlay: Using coordinates directly: (\(location.x), \(location.y))")
        
        // Use coordinates directly since they're already in AppKit format
        let finalX = location.x
        let finalY = location.y
        print("VisualFeedbackOverlay: Final coordinates: (\(finalX), \(finalY))")
        
        // Center the overlay on the click point
        let windowSize = window.frame.size
        print("VisualFeedbackOverlay: Window size for centering: \(windowSize)")
        let centeredX = finalX - (windowSize.width / 2)
        let centeredY = finalY - (windowSize.height / 2)
        
        let finalPosition = NSPoint(x: centeredX, y: centeredY)
        print("VisualFeedbackOverlay: Final window position: \(finalPosition)")
        
        window.setFrameOrigin(finalPosition)
        print("VisualFeedbackOverlay: Window positioned successfully")
    }
    
    /// Shows the overlay window
    private func showOverlayWindow() {
        guard let window = overlayWindow else {
            print("VisualFeedbackOverlay: ERROR - no window to show")
            return
        }
        
        print("VisualFeedbackOverlay: Showing overlay window")
        print("VisualFeedbackOverlay: Window frame: \(window.frame)")
        print("VisualFeedbackOverlay: Window level: \(window.level.rawValue)")
        print("VisualFeedbackOverlay: Window isVisible before: \(window.isVisible)")
        
        window.orderFront(nil)
        window.makeKeyAndOrderFront(nil)
        
        print("VisualFeedbackOverlay: Window isVisible after: \(window.isVisible)")
        print("VisualFeedbackOverlay: showOverlayWindow completed")
    }
}

// MARK: - Overlay View Controller

/// View controller for managing the overlay visual content
private class OverlayViewController: NSViewController {
    
    /// Custom view for drawing the overlay graphics
    private var overlayView: OverlayDrawingView!
    
    override func loadView() {
        overlayView = OverlayDrawingView()
        view = overlayView
    }
    
    /// Updates the appearance based on automation state
    /// - Parameter isActive: Whether automation is currently active
    func updateAppearance(isActive: Bool) {
        overlayView.isAutomationActive = isActive
        overlayView.needsDisplay = true
    }
}

// MARK: - Overlay Drawing View

/// Custom NSView for drawing the visual feedback graphics
private class OverlayDrawingView: NSView {
    
    /// Whether automation is currently active (affects visual style)
    var isAutomationActive: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        print("OverlayDrawingView: draw() called with rect: \(dirtyRect)")
        print("OverlayDrawingView: bounds: \(bounds)")
        print("OverlayDrawingView: isAutomationActive: \(isAutomationActive)")
        
        guard let context = NSGraphicsContext.current?.cgContext else { 
            print("OverlayDrawingView: ERROR - No graphics context")
            return 
        }
        
        // Clear the background
        context.clear(bounds)
        print("OverlayDrawingView: Background cleared")
        
        // Draw the visual feedback circle
        drawFeedbackCircle(in: context, rect: bounds)
        print("OverlayDrawingView: Circle drawn")
    }
    
    /// Draws the feedback circle with appropriate styling
    /// - Parameters:
    ///   - context: Core Graphics context
    ///   - rect: Drawing rectangle
    private func drawFeedbackCircle(in context: CGContext, rect: CGRect) {
        let centerX = rect.width / 2
        let centerY = rect.height / 2
        let radius: CGFloat = 20
        
        print("OverlayDrawingView: Drawing circle at center (\(centerX), \(centerY)) with radius \(radius)")
        print("OverlayDrawingView: Drawing rect: \(rect)")
        
        // Configure circle appearance based on automation state
        let strokeColor: CGColor
        let fillColor: CGColor
        let lineWidth: CGFloat
        
        if isAutomationActive {
            // Active state: bright green with pulsing effect
            strokeColor = CGColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.9)
            fillColor = CGColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 0.2)
            lineWidth = 3.0
            print("OverlayDrawingView: Using ACTIVE green colors")
        } else {
            // Inactive state: subtle blue
            strokeColor = CGColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.8)
            fillColor = CGColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 0.1)
            lineWidth = 2.0
            print("OverlayDrawingView: Using INACTIVE blue colors")
        }
        
        let circleRect = CGRect(
            x: centerX - radius,
            y: centerY - radius,
            width: radius * 2,
            height: radius * 2
        )
        print("OverlayDrawingView: Circle rect: \(circleRect)")
        
        // Draw filled circle
        context.setFillColor(fillColor)
        context.addEllipse(in: circleRect)
        context.fillPath()
        print("OverlayDrawingView: Filled circle drawn")
        
        // Draw circle outline
        context.setStrokeColor(strokeColor)
        context.setLineWidth(lineWidth)
        context.addEllipse(in: circleRect)
        context.strokePath()
        print("OverlayDrawingView: Circle outline drawn")
        
        // Draw center dot
        let dotRadius: CGFloat = 3
        let dotRect = CGRect(
            x: centerX - dotRadius,
            y: centerY - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
        context.setFillColor(strokeColor)
        context.addEllipse(in: dotRect)
        context.fillPath()
        print("OverlayDrawingView: Center dot drawn at \(dotRect)")
    }
}