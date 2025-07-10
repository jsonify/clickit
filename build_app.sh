#!/bin/bash

set -e  # Exit on any error

# Build ClickIt as a proper macOS app bundle with universal binary support

BUILD_MODE="${1:-release}"  # Default to release, allow override
DIST_DIR="dist"
APP_NAME="ClickIt"
BUNDLE_ID="com.jsonify.clickit"
VERSION="1.0.0"

echo "🔨 Building $APP_NAME app bundle ($BUILD_MODE mode)..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$DIST_DIR/$APP_NAME.app"
rm -rf "$DIST_DIR/binaries"
mkdir -p "$DIST_DIR/binaries"

# Detect available architectures
echo "🔍 Detecting available architectures..."
ARCH_LIST=()
if swift build -c "$BUILD_MODE" --arch x86_64 --show-bin-path > /dev/null 2>&1; then
    ARCH_LIST+=("x86_64")
fi
if swift build -c "$BUILD_MODE" --arch arm64 --show-bin-path > /dev/null 2>&1; then
    ARCH_LIST+=("arm64")
fi

if [ ${#ARCH_LIST[@]} -eq 0 ]; then
    echo "❌ No supported architectures found"
    exit 1
fi

echo "📱 Building for architectures: ${ARCH_LIST[*]}"

# Build for each architecture
BINARY_PATHS=()
for arch in "${ARCH_LIST[@]}"; do
    echo "⚙️  Building for $arch..."
    if ! swift build -c "$BUILD_MODE" --arch "$arch"; then
        echo "❌ Build failed for $arch"
        exit 1
    fi
    
    # Get the actual build path
    BUILD_PATH=$(swift build -c "$BUILD_MODE" --arch "$arch" --show-bin-path)
    BINARY_PATH="$BUILD_PATH/$APP_NAME"
    
    if [ ! -f "$BINARY_PATH" ]; then
        echo "❌ Binary not found at $BINARY_PATH"
        exit 1
    fi
    
    # Copy binary to dist directory
    cp "$BINARY_PATH" "$DIST_DIR/binaries/$APP_NAME-$arch"
    BINARY_PATHS+=("$DIST_DIR/binaries/$APP_NAME-$arch")
done

# Create universal binary if multiple architectures
if [ ${#BINARY_PATHS[@]} -gt 1 ]; then
    echo "🔗 Creating universal binary..."
    lipo -create -output "$DIST_DIR/binaries/$APP_NAME-universal" "${BINARY_PATHS[@]}"
    FINAL_BINARY="$DIST_DIR/binaries/$APP_NAME-universal"
else
    echo "📦 Using single architecture binary..."
    FINAL_BINARY="${BINARY_PATHS[0]}"
fi

# Verify binary
echo "🔍 Verifying binary architectures..."
file "$FINAL_BINARY"
lipo -info "$FINAL_BINARY" 2>/dev/null || echo "Single architecture binary"

# Create app bundle structure
echo "📁 Creating app bundle structure..."
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$FINAL_BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Make executable
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Code signing for macOS recognition and permission persistence
echo "🔐 Starting code signing process..."

# Function to find available signing identities
find_signing_identity() {
    # Look for Developer ID Application certificates first (for distribution)
    local dev_id=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | cut -d '"' -f 2)
    if [ -n "$dev_id" ]; then
        echo "$dev_id"
        return 0
    fi
    
    # Fall back to any Mac Developer certificate
    local mac_dev=$(security find-identity -v -p codesigning 2>/dev/null | grep "Mac Developer" | head -1 | cut -d '"' -f 2)
    if [ -n "$mac_dev" ]; then
        echo "$mac_dev"
        return 0
    fi
    
    # Fall back to any Apple Development certificate
    local apple_dev=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development" | head -1 | cut -d '"' -f 2)
    if [ -n "$apple_dev" ]; then
        echo "$apple_dev"
        return 0
    fi
    
    # Fall back to any available signing identity
    local any_cert=$(security find-identity -v -p codesigning 2>/dev/null | grep -E "(Developer|Application)" | head -1 | cut -d '"' -f 2)
    if [ -n "$any_cert" ]; then
        echo "$any_cert"
        return 0
    fi
    
    return 1
}

# Attempt to find and use a signing identity
SIGNING_IDENTITY=$(find_signing_identity)

if [ -n "$SIGNING_IDENTITY" ]; then
    echo "🔑 Found signing identity: $SIGNING_IDENTITY"
    
    # Sign the executable first
    echo "  📝 Signing executable..."
    if codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime "$APP_BUNDLE/Contents/MacOS/$APP_NAME"; then
        echo "  ✅ Executable signed successfully"
    else
        echo "  ⚠️  Failed to sign executable, continuing without signature"
        SIGNING_IDENTITY=""
    fi
    
    # Sign the entire app bundle
    if [ -n "$SIGNING_IDENTITY" ]; then
        echo "  📝 Signing app bundle..."
        if codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime "$APP_BUNDLE"; then
            echo "  ✅ App bundle signed successfully"
            
            # Verify the signature
            echo "  🔍 Verifying signature..."
            if codesign --verify --verbose "$APP_BUNDLE" 2>/dev/null; then
                echo "  ✅ Signature verification passed"
                SIGNED_STATUS="✅ Signed"
            else
                echo "  ⚠️  Signature verification failed"
                SIGNED_STATUS="⚠️ Signed but verification failed"
            fi
        else
            echo "  ⚠️  Failed to sign app bundle"
            SIGNED_STATUS="⚠️ Signing failed"
        fi
    fi
else
    echo "🔓 No signing identity found - app will be unsigned"
    echo "  💡 To enable signing, you can:"
    echo "     • Quick setup: Run ./create_signing_cert.sh"
    echo "     • Manual setup: Create a certificate in Keychain Access"
    echo "     • Apple Developer: Use your Developer ID certificate"
    echo "  🔧 Code signing helps macOS maintain app permissions across launches"
    SIGNED_STATUS="🔓 Unsigned"
fi

# Install to Applications for consistency (optional but recommended)
APPLICATIONS_PATH="/Applications/$APP_NAME.app"
if [ -d "$APPLICATIONS_PATH" ]; then
    echo "🗑️  Removing existing app from Applications..."
    rm -rf "$APPLICATIONS_PATH"
fi

echo "📦 Installing to Applications folder..."
if cp -R "$APP_BUNDLE" "/Applications/"; then
    echo "✅ App installed to /Applications/$APP_NAME.app"
    echo "🎯 Using consistent location will help maintain permissions"
    INSTALL_STATUS="✅ Installed to /Applications"
else
    echo "⚠️  Failed to install to Applications (permission issue?)"
    echo "💡 You can manually drag the app to Applications folder"
    INSTALL_STATUS="⚠️ Manual installation required"
fi

# Create build metadata
echo "📋 Creating build metadata..."
cat > "$DIST_DIR/build-info.txt" << EOF
Build Date: $(date)
Mode: $BUILD_MODE
Architectures: ${ARCH_LIST[*]}
Binary Type: $([ ${#BINARY_PATHS[@]} -gt 1 ] && echo "Universal" || echo "Single Architecture")
Version: $VERSION
Bundle ID: $BUNDLE_ID
Signing Status: ${SIGNED_STATUS:-"Unknown"}
Installation: ${INSTALL_STATUS:-"Local only"}
Signing Identity: ${SIGNING_IDENTITY:-"None"}
EOF

echo "✅ $APP_NAME.app created successfully!"
echo "📂 Location: $APP_BUNDLE"
echo "🔐 Signing: ${SIGNED_STATUS:-"Unknown"}"
echo "📦 Installation: ${INSTALL_STATUS:-"Local only"}"
echo ""
echo "🚀 Launch options:"
if [ "$INSTALL_STATUS" = "✅ Installed to /Applications" ]; then
    echo "   • From Applications: open \"/Applications/$APP_NAME.app\""
    echo "   • From Spotlight: Press Cmd+Space, type '$APP_NAME'"
else
    echo "   • From build: open \"$APP_BUNDLE\""
fi
echo ""
echo "🔧 Permission Setup:"
echo "   • The app should appear in System Settings > Accessibility"
echo "   • Grant accessibility permissions to enable clicking functionality"
if [ -n "$SIGNING_IDENTITY" ]; then
    echo "   • Code signing should help maintain permissions across launches"
else
    echo "   • Consider adding code signing to maintain permissions across launches"
fi
echo ""
echo "📋 Build info: $DIST_DIR/build-info.txt"