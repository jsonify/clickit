import SwiftUI
import CoreGraphics

struct ConfigurationPanel: View {
    @EnvironmentObject private var clickCoordinator: ClickCoordinator
    @State private var clickInterval: Double = 1.0
    @State private var selectedClickType: ClickType = .left
    @State private var durationEnabled: Bool = false
    @State private var duration: Double = 60.0
    @State private var maxClicksEnabled: Bool = false
    @State private var maxClicks: Int = 100
    @State private var targetApplication: String = ""
    @State private var locationVariance: Double = 0.0
    @State private var randomizeLocation: Bool = false
    @State private var stopOnError: Bool = false

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
                                    Text("\(formatInterval(clickInterval))")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }

                                Slider(value: $clickInterval, in: 0.01...10.0, step: 0.01) {
                                    Text("Click Interval")
                                } minimumValueLabel: {
                                    Text("0.01s")
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

                                Picker("Click Type", selection: $selectedClickType) {
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
                            // Duration limit toggle
                            Toggle("Limit Duration", isOn: $durationEnabled)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if durationEnabled {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Duration")
                                        Spacer()
                                        Text(formatDuration(duration))
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }

                                    Slider(value: $duration, in: 1...3600, step: 1) {
                                        Text("Duration")
                                    } minimumValueLabel: {
                                        Text("1s")
                                            .font(.caption2)
                                    } maximumValueLabel: {
                                        Text("1h")
                                            .font(.caption2)
                                    }
                                }
                            }

                            // Max clicks toggle
                            Toggle("Limit Click Count", isOn: $maxClicksEnabled)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if maxClicksEnabled {
                                HStack {
                                    Text("Max Clicks:")
                                        .font(.subheadline)
                                    Spacer()
                                    TextField("Count", value: $maxClicks, format: .number)
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

                            TextField("com.example.app (optional)", text: $targetApplication)
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
                            Toggle("Randomize Click Location", isOn: $randomizeLocation)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if randomizeLocation {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Variance (pixels)")
                                        Spacer()
                                        Text("\(Int(locationVariance))px")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }

                                    Slider(value: $locationVariance, in: 0...50, step: 1) {
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
                            Toggle("Stop on Error", isOn: $stopOnError)
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

                                if !targetApplication.isEmpty {
                                    HStack {
                                        Text("Target App:")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text(targetApplication)
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
                                    Text("\(String(format: "%.2f", 1.0 / clickInterval))")
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
                            .disabled(selectedClickPoint == nil)
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

        let config = AutomationConfiguration(
            location: point,
            clickType: selectedClickType,
            clickInterval: clickInterval,
            targetApplication: targetApplication.isEmpty ? nil : targetApplication,
            maxClicks: maxClicksEnabled ? maxClicks : nil,
            stopOnError: stopOnError,
            randomizeLocation: randomizeLocation,
            locationVariance: CGFloat(locationVariance)
        )

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
