import SwiftUI
import CoreGraphics

struct ConfigurationPanel: View {
    @EnvironmentObject private var clickCoordinator: ClickCoordinator
    @StateObject private var clickSettings = ClickSettings()

    let selectedClickPoint: CGPoint?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                Text("Automation Configuration")
                    .font(.headline)
                Spacer()

                // Status indicator
                if clickCoordinator.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Running")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Click Settings Section
                    configurationSection(title: "Click Settings", icon: "cursorarrow.click") {
                        VStack(spacing: 12) {
                            // Click interval
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Click Interval")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(formatInterval(clickSettings.clickIntervalMs / 1000.0))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                Slider(value: $clickSettings.clickIntervalMs, in: 10...10000, step: 10) {
                                    Text("Click Interval")
                                } minimumValueLabel: {
                                    Text("10ms")
                                        .font(.caption2)
                                } maximumValueLabel: {
                                    Text("10s")
                                        .font(.caption2)
                                }
                            }

                            // Click type selector
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Click Type")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Picker("Click Type", selection: $clickSettings.clickType) {
                                    ForEach(ClickType.allCases, id: \.self) { type in
                                        HStack {
                                            Image(systemName: type == .left ?
                                                  "cursorarrow.click" : "cursorarrow.click.2")
                                            Text(type.rawValue.capitalized)
                                        }
                                        .tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }

                    // Duration Control Section
                    configurationSection(title: "Duration Control", icon: "timer") {
                        VStack(spacing: 12) {
                            // Duration mode picker
                            Picker("Duration Mode", selection: $clickSettings.durationMode) {
                                ForEach(DurationMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            // Duration controls based on mode
                            switch clickSettings.durationMode {
                            case .unlimited:
                                Text("Automation will run until manually stopped")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()

                            case .timeLimit:
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Duration")
                                        Spacer()
                                        Text(formatDuration(clickSettings.durationSeconds))
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }

                                    Slider(value: $clickSettings.durationSeconds, in: 1...3600, step: 1) {
                                        Text("Duration")
                                    } minimumValueLabel: {
                                        Text("1s")
                                            .font(.caption2)
                                    } maximumValueLabel: {
                                        Text("1h")
                                            .font(.caption2)
                                    }
                                }

                            case .clickCount:
                                HStack {
                                    Text("Max Clicks:")
                                        .font(.subheadline)
                                    Spacer()
                                    TextField("Count", value: $clickSettings.maxClicks, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                    }

                    // Target Application Section
                    configurationSection(title: "Target Application", icon: "app.badge") {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Bundle Identifier:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }

                            TextField("com.example.app (optional)", text: Binding(
                                get: { clickSettings.targetApplication ?? "" },
                                set: { clickSettings.targetApplication = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))

                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("Leave empty to click on current active application")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }

                    // Advanced Settings Section
                    configurationSection(title: "Advanced Settings", icon: "gearshape.2") {
                        VStack(spacing: 12) {
                            // Location randomization
                            Toggle("Randomize Click Location", isOn: $clickSettings.randomizeLocation)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if clickSettings.randomizeLocation {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Variance (pixels)")
                                        Spacer()
                                        Text("\(Int(clickSettings.locationVariance))px")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }

                                    Slider(value: $clickSettings.locationVariance, in: 0...50, step: 1) {
                                        Text("Variance")
                                    } minimumValueLabel: {
                                        Text("0")
                                            .font(.caption2)
                                    } maximumValueLabel: {
                                        Text("50")
                                            .font(.caption2)
                                    }
                                }
                            }

                            // Error handling
                            Toggle("Stop on Error", isOn: $clickSettings.stopOnError)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            // Feedback options
                            Toggle("Show Visual Feedback", isOn: $clickSettings.showVisualFeedback)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Toggle("Play Sound Feedback", isOn: $clickSettings.playSoundFeedback)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    // Current Status Section
                    if let point = selectedClickPoint {
                        configurationSection(title: "Current Configuration", icon: "checkmark.circle") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Click Point:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("X: \(Int(point.x)), Y: \(Int(point.y))")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                if let targetApp = clickSettings.targetApplication, !targetApp.isEmpty {
                                    HStack {
                                        Text("Target App:")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text(targetApp)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                }

                                HStack {
                                    Text("Estimated CPS:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(String(format: "%.2f", 1000.0 / clickSettings.clickIntervalMs))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Control Buttons
                    VStack(spacing: 8) {
                        if !clickCoordinator.isActive {
                            Button(action: startAutomation) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start Automation")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(!clickSettings.isValid || selectedClickPoint == nil)
                        } else {
                            Button(action: stopAutomation) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("Stop Automation")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .foregroundColor(.red)
                        }

                        // Reset button
                        Button(action: {
                            clickSettings.resetToDefaults()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset to Defaults")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)

                        // Statistics display
                        if clickCoordinator.isActive || clickCoordinator.clickCount > 0 {
                            StatisticsView()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .onChange(of: selectedClickPoint) { _, newPoint in
            if let point = newPoint {
                clickSettings.clickLocation = point
            }
        }
        .onAppear {
            // Sync the click location if available
            if let point = selectedClickPoint {
                clickSettings.clickLocation = point
            }
        }
    }

    @ViewBuilder
    private func configurationSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            content()
        }
        .padding(12)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
    }

    private func startAutomation() {
        guard let point = selectedClickPoint else { return }

        // Update the click location in settings
        clickSettings.clickLocation = point

        // Create configuration from settings
        let config = clickSettings.createAutomationConfiguration()

        // Start automation
        clickCoordinator.startAutomation(with: config)
    }

    private func stopAutomation() {
        clickCoordinator.stopAutomation()
    }

    private func formatInterval(_ interval: Double) -> String {
        if interval < 1.0 {
            return "\(Int(interval * 1000))ms"
        } else {
            return String(format: "%.2fs", interval)
        }
    }

    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    ConfigurationPanel(selectedClickPoint: CGPoint(x: 100, y: 100))
        .environmentObject(ClickCoordinator.shared)
        .frame(width: 400, height: 600)
}
