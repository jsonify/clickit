import SwiftUI
import Combine

/// Main configuration panel for ClickIt auto-clicker settings
struct ConfigurationPanel: View {
    @StateObject private var clickSettings = ClickSettings()
    @EnvironmentObject private var clickCoordinator: ClickCoordinator
    @EnvironmentObject private var windowManager: WindowManager
    
    let selectedClickPoint: CGPoint?
    
    init(selectedClickPoint: CGPoint? = nil) {
        self.selectedClickPoint = selectedClickPoint
    }
    
    @State private var showingAdvancedOptions = false
    @State private var showingTargetSelector = false
    @State private var intervalText = ""
    @State private var durationText = ""
    @State private var maxClicksText = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                headerSection
                
                // Main Configuration Section
                mainConfigurationSection
                
                // Duration Control Section
                durationControlSection
                
                // Target Application Section
                targetApplicationSection
                
                // Advanced Options Section
                if showingAdvancedOptions {
                    advancedOptionsSection
                }
                
                // Action Buttons Section
                actionButtonsSection
                
                // Status and Feedback Section
                statusSection
            }
            .padding()
        }
        .frame(minWidth: 400, maxWidth: 600)
        .onAppear {
            initializeTextFields()
        }
        .onChange(of: selectedClickPoint) { _, newPoint in
            if let point = newPoint {
                clickSettings.clickLocation = point
            }
        }
        .alert("Configuration Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingTargetSelector) {
            TargetApplicationSelector(
                selectedApplication: $clickSettings.targetApplication,
                availableApplications: windowManager.availableWindows
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingAdvancedOptions.toggle()
                    }
                }) {
                    Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Toggle advanced options")
            }
            
            if let validationMessage = clickSettings.validationMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Main Configuration Section
    
    private var mainConfigurationSection: some View {
        VStack(spacing: 16) {
            // Click Interval Control
            ClickIntervalControl(
                intervalMs: $clickSettings.clickIntervalMs,
                intervalText: $intervalText
            )
            
            // Click Type Selector
            ClickTypeSelector(selectedType: $clickSettings.clickType)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    // MARK: - Duration Control Section
    
    private var durationControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration Control")
                .font(.headline)
                .foregroundColor(.primary)
            
            DurationModeSelector(
                selectedMode: $clickSettings.durationMode,
                durationSeconds: $clickSettings.durationSeconds,
                maxClicks: $clickSettings.maxClicks,
                durationText: $durationText,
                maxClicksText: $maxClicksText
            )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    // MARK: - Target Application Section
    
    private var targetApplicationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Application")
                .font(.headline)
                .foregroundColor(.primary)
            
            TargetApplicationDisplay(
                selectedApplication: clickSettings.targetApplication,
                clickLocation: clickSettings.clickLocation,
                onSelectTarget: {
                    showingTargetSelector = true
                },
                onClearTarget: {
                    clickSettings.targetApplication = nil
                }
            )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    // MARK: - Advanced Options Section
    
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Options")
                .font(.headline)
                .foregroundColor(.primary)
            
            AdvancedOptionsControl(
                randomizeLocation: $clickSettings.randomizeLocation,
                locationVariance: $clickSettings.locationVariance,
                stopOnError: $clickSettings.stopOnError,
                showVisualFeedback: $clickSettings.showVisualFeedback,
                playSoundFeedback: $clickSettings.playSoundFeedback
            )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Start/Stop Button
                Button(action: {
                    if clickCoordinator.isActive {
                        stopAutomation()
                    } else {
                        startAutomation()
                    }
                }) {
                    HStack {
                        Image(systemName: clickCoordinator.isActive ? "stop.fill" : "play.fill")
                        Text(clickCoordinator.isActive ? "Stop" : "Start")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!clickSettings.isValid)
                .accessibilityLabel(clickCoordinator.isActive ? "Stop automation" : "Start automation")
                
                // Reset Button
                Button(action: {
                    resetSettings()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(clickCoordinator.isActive)
                .accessibilityLabel("Reset settings to defaults")
            }
            
            // Test Click Button
            if clickSettings.clickLocation != .zero {
                Button(action: {
                    testClick()
                }) {
                    HStack {
                        Image(systemName: "target")
                        Text("Test Click")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(clickCoordinator.isActive)
                .accessibilityLabel("Test click at selected location")
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 8) {
            if clickCoordinator.isActive {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .controlSize(.small)
                    
                    Text("Automation Running")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(clickCoordinator.clickCount) clicks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            
            // Statistics Display
            if clickCoordinator.clickCount > 0 {
                let stats = clickCoordinator.getSessionStatistics()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Success Rate")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", stats.successRate * 100))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("Avg Time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1fms", stats.averageClickTime * 1000))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Duration")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatDuration(stats.duration))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeTextFields() {
        intervalText = String(format: "%.0f", clickSettings.clickIntervalMs)
        durationText = String(format: "%.0f", clickSettings.durationSeconds)
        maxClicksText = String(clickSettings.maxClicks)
    }
    
    private func startAutomation() {
        guard clickSettings.isValid else {
            showError("Invalid configuration. Please check your settings.")
            return
        }
        
        let config = clickSettings.createAutomationConfiguration()
        clickCoordinator.startAutomation(with: config)
    }
    
    private func stopAutomation() {
        clickCoordinator.stopAutomation()
    }
    
    private func resetSettings() {
        clickSettings.resetToDefaults()
        initializeTextFields()
    }
    
    private func testClick() {
        Task {
            let config = ClickConfiguration(
                type: clickSettings.clickType,
                location: clickSettings.clickLocation,
                targetPID: nil
            )
            
            let result = await clickCoordinator.performSingleClick(configuration: config)
            
            if !result.success {
                await MainActor.run {
                    showError("Test click failed: \(result.error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

// MARK: - Supporting Views

/// Click interval control with slider and text input
struct ClickIntervalControl: View {
    @Binding var intervalMs: Double
    @Binding var intervalText: String
    
    private let minInterval = AppConstants.minClickInterval * 1000
    private let maxInterval = AppConstants.maxClickInterval * 1000
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Click Interval")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 4) {
                    TextField("Interval", text: $intervalText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onSubmit {
                            updateIntervalFromText()
                        }
                        .onChange(of: intervalText) { _, _ in
                            updateIntervalFromText()
                        }
                    
                    Text("ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Slider(value: $intervalMs, in: minInterval...maxInterval, step: 1) {
                Text("Click Interval")
            }
            .onChange(of: intervalMs) { _, newValue in
                intervalText = String(format: "%.0f", newValue)
            }
            .accessibilityLabel("Click interval slider")
            .accessibilityValue("\(Int(intervalMs)) milliseconds")
            
            HStack {
                Text(String(format: "%.0f ms", minInterval))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.0f ms", maxInterval))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func updateIntervalFromText() {
        if let value = Double(intervalText) {
            intervalMs = max(minInterval, min(maxInterval, value))
        }
        intervalText = String(format: "%.0f", intervalMs)
    }
}

/// Click type selector with segmented control
struct ClickTypeSelector: View {
    @Binding var selectedType: ClickType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Click Type")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Click Type", selection: $selectedType) {
                ForEach(ClickType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type == .left ? "cursorarrow.click" : "cursorarrow.click.2")
                        Text(type.rawValue.capitalized)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Click type selector")
        }
    }
}

/// Duration mode selector and controls
struct DurationModeSelector: View {
    @Binding var selectedMode: DurationMode
    @Binding var durationSeconds: Double
    @Binding var maxClicks: Int
    @Binding var durationText: String
    @Binding var maxClicksText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Duration Mode", selection: $selectedMode) {
                ForEach(DurationMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Duration mode selector")
            
            Group {
                switch selectedMode {
                case .unlimited:
                    Text("Automation will run until manually stopped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                
                case .timeLimit:
                    HStack {
                        Text("Duration:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            TextField("Duration", text: $durationText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onSubmit {
                                    updateDurationFromText()
                                }
                                .onChange(of: durationText) { _, _ in
                                    updateDurationFromText()
                                }
                            
                            Text("seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                case .clickCount:
                    HStack {
                        Text("Max Clicks:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            TextField("Max Clicks", text: $maxClicksText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onSubmit {
                                    updateMaxClicksFromText()
                                }
                                .onChange(of: maxClicksText) { _, _ in
                                    updateMaxClicksFromText()
                                }
                            
                            Text("clicks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func updateDurationFromText() {
        if let value = Double(durationText) {
            durationSeconds = max(1.0, min(86400.0, value))
        }
        durationText = String(format: "%.0f", durationSeconds)
    }
    
    private func updateMaxClicksFromText() {
        if let value = Int(maxClicksText) {
            maxClicks = max(1, min(10000, value))
        }
        maxClicksText = String(maxClicks)
    }
}

/// Target application display and selector
struct TargetApplicationDisplay: View {
    let selectedApplication: String?
    let clickLocation: CGPoint
    let onSelectTarget: () -> Void
    let onClearTarget: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let app = selectedApplication {
                        HStack {
                            Image(systemName: "app.fill")
                                .foregroundColor(.accentColor)
                            Text(app)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        if clickLocation != .zero {
                            Text("Click at: (\(Int(clickLocation.x)), \(Int(clickLocation.y)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "app.dashed")
                                .foregroundColor(.secondary)
                            Text("No target selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Select", action: onSelectTarget)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    
                    if selectedApplication != nil {
                        Button("Clear", action: onClearTarget)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
            
            if clickLocation == .zero {
                Text("Please select a click location using the point selector")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .italic()
            }
        }
    }
}

/// Advanced options control section
struct AdvancedOptionsControl: View {
    @Binding var randomizeLocation: Bool
    @Binding var locationVariance: Double
    @Binding var stopOnError: Bool
    @Binding var showVisualFeedback: Bool
    @Binding var playSoundFeedback: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location Randomization
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Randomize Click Location", isOn: $randomizeLocation)
                    .accessibilityLabel("Toggle location randomization")
                
                if randomizeLocation {
                    HStack {
                        Text("Variance:")
                            .font(.caption)
                        
                        Slider(value: $locationVariance, in: 0...100, step: 1) {
                            Text("Location Variance")
                        }
                        .accessibilityLabel("Location variance slider")
                        .accessibilityValue("\(Int(locationVariance)) pixels")
                        
                        Text("\(Int(locationVariance))px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Error Handling
            Toggle("Stop on Error", isOn: $stopOnError)
                .accessibilityLabel("Toggle stop on error")
            
            // Feedback Options
            Toggle("Show Visual Feedback", isOn: $showVisualFeedback)
                .accessibilityLabel("Toggle visual feedback")
            
            Toggle("Play Sound Feedback", isOn: $playSoundFeedback)
                .accessibilityLabel("Toggle sound feedback")
        }
    }
}

/// Target application selector sheet
struct TargetApplicationSelector: View {
    @Binding var selectedApplication: String?
    let availableApplications: [WindowInfo]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if availableApplications.isEmpty {
                    ContentUnavailableView(
                        "No Applications Found",
                        systemImage: "app.dashed",
                        description: Text("No suitable applications are currently running")
                    )
                } else {
                    List(availableApplications, id: \.windowID) { window in
                        Button(action: {
                            selectedApplication = window.applicationName
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "app.fill")
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(window.applicationName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    if !window.windowTitle.isEmpty {
                                        Text(window.windowTitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedApplication == window.applicationName {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Select Target Application")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

#Preview {
    ConfigurationPanel(selectedClickPoint: CGPoint(x: 100, y: 100))
        .environmentObject(ClickCoordinator.shared)
        .environmentObject(WindowManager.shared)
}