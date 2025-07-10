# Issue #30: Build Distribution Output Structure

**Link:** [GitHub Issue #30](https://github.com/jsonify/clickit/issues/30)

## Analysis

### Current State
- ✅ `.build/` directory already in `.gitignore`
- ✅ `build_app.sh` script exists for creating `.app` bundles
- ❌ Build script hardcoded to x86_64 architecture only
- ❌ No universal binary support
- ❌ Build artifacts mixed with development
- ❌ No structured `dist/` directory organization

### Key Issues Identified

1. **Architecture Limitation**: `build_app.sh` hardcodes x86_64 path:
   ```bash
   cp .build/x86_64-apple-macosx/release/ClickIt ClickIt.app/Contents/MacOS/
   ```

2. **No Universal Binary**: Missing Apple Silicon support

3. **Build Output Location**: App bundle created in project root instead of dedicated distribution directory

4. **No Development vs Distribution Separation**: Single build script for all purposes

## Implementation Plan

### Phase 1: Universal Binary Support
- Update `build_app.sh` to detect architecture automatically
- Add universal binary creation using `lipo` command
- Test on both Intel and Apple Silicon

### Phase 2: Distribution Structure
- Create `dist/` directory for distribution artifacts
- Separate development builds from distribution builds
- Implement clean build process

### Phase 3: Build Script Enhancement
- Create multiple build modes (dev, release, universal)
- Add proper error handling and validation
- Implement clean/rebuild functionality

### Phase 4: Documentation
- Update README with distribution build instructions
- Document universal binary process
- Add CI/CD preparation notes

## Technical Approach

### Universal Binary Strategy
```bash
# Build for both architectures
swift build -c release --arch x86_64
swift build -c release --arch arm64

# Create universal binary
lipo -create -output ClickIt \
  .build/x86_64-apple-macosx/release/ClickIt \
  .build/arm64-apple-macosx/release/ClickIt
```

### Distribution Structure
```
dist/
├── ClickIt.app/           # Final app bundle
├── ClickIt-universal      # Universal binary
├── ClickIt-x86_64         # Intel binary
├── ClickIt-arm64          # Apple Silicon binary
└── metadata/              # Build metadata
```

## Acceptance Criteria Verification
- [ ] Build artifacts no longer output to project root ✅ (already in .gitignore)
- [ ] Clear documentation for distributable builds
- [ ] Proper macOS app bundle structure ✅ (script exists, needs enhancement)
- [ ] Universal binary support (Intel x64 + Apple Silicon)
- [ ] Maintains existing development workflow

## Next Steps
1. Enhance build script for universal binary support
2. Create distribution directory structure
3. Add build mode selection
4. Test on both architectures
5. Update documentation