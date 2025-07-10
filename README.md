# ClickIt

A lightweight, native macOS auto-clicker application with precision timing and advanced targeting capabilities. Designed for gamers, automation enthusiasts, and productivity users who need reliable, accurate clicking automation.

## Features

- **Native macOS Application**: Built with SwiftUI for optimal performance
- **Universal Binary**: Supports both Intel x64 and Apple Silicon
- **Advanced Window Targeting**: Works with any application, even when minimized
- **Precision Timing**: Sub-10ms click timing accuracy with customizable intervals
- **Visual Feedback**: Shows click points with overlay indicators
- **Preset System**: Save and load custom clicking configurations
- **Global Hotkeys**: System-wide controls for start/stop operations
- **Variable Timing**: Human-like randomization patterns
- **Background Operation**: Continues operation without requiring app focus

## Use Cases

- **Gaming**: Automated clicking for various games and applications
- **Testing**: UI testing and automation workflows
- **Productivity**: Repetitive task automation
- **Accessibility**: Assistance for users with mobility limitations

## Requirements

- macOS 15.0 or later
- Accessibility permissions (for mouse event simulation)
- Screen Recording permissions (for window detection and targeting)

## Installation

[Installation instructions will be added once the app is ready for distribution]

## Development

This project is organized into milestones tracking the development progress. Check the Issues tab for current development tasks and project roadmap.

### Building from Source

#### Prerequisites
- Xcode 15.0 or later
- Swift 5.9 or later
- macOS 15.0 or later

#### Quick Start
```bash
# Clone the repository
git clone https://github.com/jsonify/clickit.git
cd clickit

# Build and run for development
swift run

# Or build the app bundle
./build_app.sh
```

#### Build Commands

**Development Build:**
```bash
# Build for current architecture (debug)
swift build

# Run directly
swift run
```

**Distribution Build:**
```bash
# Create universal app bundle (Intel + Apple Silicon)
./build_app.sh

# Create debug app bundle
./build_app.sh debug

# Launch the built app
open dist/ClickIt.app
```

#### Build Output Structure
- `dist/ClickIt.app` - Final app bundle
- `dist/binaries/` - Individual architecture binaries
- `dist/build-info.txt` - Build metadata
- `.build/` - Swift Package Manager build cache

#### Universal Binary Support
The build system automatically detects available architectures and creates universal binaries when possible:
- **Intel x64**: `x86_64-apple-macosx`
- **Apple Silicon**: `arm64-apple-macosx`
- **Universal**: Combined binary supporting both architectures

#### Testing
```bash
# Run unit tests
swift test

# Build and test specific configuration
swift build -c release
swift test -c release
```

## Contributing

Contributions are welcome! Please read our contributing guidelines and check the Issues tab for open tasks.

## License

MIT License - see LICENSE file for details

## Disclaimer

This software is intended for legitimate automation purposes. Users are responsible for ensuring their use complies with the terms of service of any applications they target and applicable laws and regulations.
