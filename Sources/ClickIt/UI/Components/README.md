# UI Components

This directory contains reusable SwiftUI components for the ClickIt application.

## ConfigurationPanel.swift

The main configuration panel component that provides a comprehensive interface for setting up auto-clicking automation.

### Features

- **Click Interval Control**: Slider and text input for precise timing (1ms to 60 seconds)
- **Click Type Selector**: Segmented control for left/right click selection
- **Duration Control**: Multiple modes - unlimited, time limit, or click count
- **Target Application Display**: Shows selected target app and click coordinates
- **Advanced Options**: Location randomization, error handling, and feedback settings
- **Action Buttons**: Start/Stop automation, reset settings, and test click functionality
- **Real-time Validation**: Immediate feedback on configuration validity
- **Statistics Display**: Live session statistics during automation

### Usage

```swift
ConfigurationPanel(selectedClickPoint: CGPoint(x: 100, y: 100))
    .environmentObject(ClickCoordinator.shared)
    .environmentObject(WindowManager.shared)
```

### Components Structure

- `ConfigurationPanel`: Main container view
- `ClickIntervalControl`: Dual slider/text input for interval setting
- `ClickTypeSelector`: Segmented control for click type
- `DurationModeSelector`: Mode selection with dynamic controls
- `TargetApplicationDisplay`: Target app info and selection
- `AdvancedOptionsControl`: Collapsible advanced settings
- `TargetApplicationSelector`: Modal sheet for app selection

### Integration

The component integrates with:
- `ClickSettings`: ObservableObject for state management and persistence
- `ClickCoordinator`: For automation control and statistics
- `WindowManager`: For target application detection
- `ClickPointSelector`: Receives click coordinates from point selection

### Accessibility

All components include proper accessibility labels and support for VoiceOver navigation.