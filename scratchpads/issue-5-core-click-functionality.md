# Issue #5: Core Click Functionality

**Issue Link**: https://github.com/jsonify/clickit/issues/5

## Analysis

This issue requires implementing the core mouse clicking functionality for the ClickIt autoclicker app. The requirements are:

### Tasks
- [ ] Implement `CGEventCreateMouseEvent` for left clicks
- [ ] Add right-click support  
- [ ] Create click point coordinate system
- [ ] Implement background clicking via `CGEventPostToPid`
- [ ] Add click timing precision testing and validation

### Acceptance Criteria
- Both left and right clicks work accurately
- ±1 pixel click precision
- Background clicking functions properly
- Timing precision within ±5ms

## Current State

The codebase has:
- ✅ Core frameworks imported (CoreGraphics, Carbon, ApplicationServices)
- ✅ Empty `Sources/ClickIt/Core/Click/` directory ready for implementation
- ✅ Permission system already implemented
- ✅ App constants defined including CoreGraphics configuration

## Implementation Plan

### 1. Core Click Engine (`ClickEngine.swift`)
- Create main click engine class
- Implement `CGEventCreateMouseEvent` for left clicks
- Add coordinate system handling
- Implement timing precision controls

### 2. Click Types (`ClickType.swift`)
- Define enum for left/right clicks
- Add click configuration options
- Support for future click types (double-click, etc.)

### 3. Background Clicking (`BackgroundClicker.swift`)
- Implement `CGEventPostToPid` for background clicks
- Handle window targeting and PID resolution
- Ensure clicks work on minimized/hidden windows

### 4. Precision Testing (`ClickPrecisionTester.swift`)
- Implement timing validation (±5ms requirement)
- Add coordinate accuracy testing (±1 pixel)
- Performance benchmarking utilities

### 5. Click Coordinator (`ClickCoordinator.swift`)
- High-level interface for UI integration
- Coordinate between different click components
- Handle click sequences and timing

## Technical Implementation Details

### Core Technologies
- `CGEventCreateMouseEvent`: For creating mouse events
- `CGEventPostToPid`: For targeting specific applications
- `CGEventPost`: For system-wide posting
- `mach_absolute_time`: For high-precision timing

### Key Considerations
- Must maintain ±1 pixel accuracy
- Timing precision within ±5ms
- Background operation support
- Memory efficiency for continuous clicking
- Thread safety for concurrent operations

## File Structure
```
Sources/ClickIt/Core/Click/
├── ClickEngine.swift          # Main click engine
├── ClickType.swift           # Click type definitions
├── BackgroundClicker.swift   # Background clicking
├── ClickPrecisionTester.swift # Testing utilities
└── ClickCoordinator.swift    # High-level coordinator
```

## Testing Strategy

1. **Unit Tests**: Individual component testing
2. **Integration Tests**: Component interaction testing
3. **Precision Tests**: Timing and accuracy validation
4. **Performance Tests**: Memory and CPU usage benchmarks

## Dependencies

- CoreGraphics (already imported)
- ApplicationServices (already imported)
- Foundation (standard library)
- No external dependencies required

## Success Metrics

- All acceptance criteria met
- Clean, maintainable code architecture
- Comprehensive test coverage
- Performance within specified limits
- Ready for UI integration