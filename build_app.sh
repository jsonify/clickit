#!/bin/bash

set -e  # Exit on any error

# Build ClickIt as a proper macOS app bundle with universal binary support

BUILD_MODE="${1:-release}"  # Default to release, allow override
DIST_DIR="dist"
APP_NAME="ClickIt"
BUNDLE_ID="com.jsonify.clickit"
VERSION="1.0.0"
BUILD_NUMBER=$(date +%Y%m%d%H%M)

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
    <string>$BUILD_NUMBER</string>
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

# Code signing with self-signed certificate (if available)
echo "🔐 Attempting to code sign the app..."
CERT_NAME=""

# Try to find a suitable code signing certificate
echo "🔍 Looking for code signing certificates..."

# First, check if ClickIt Developer Certificate exists (even if not shown by find-identity)
if security find-certificate -c "ClickIt Developer Certificate" >/dev/null 2>&1; then
    CERT_NAME="ClickIt Developer Certificate"
    echo "✅ Found ClickIt Developer Certificate (self-signed)"
else
    # Fall back to other available certificates
    AVAILABLE_CERTS=$(security find-identity -v -p codesigning 2>/dev/null | grep -E '".*"' | head -5)
    
    if [ -n "$AVAILABLE_CERTS" ]; then
        echo "📜 Available certificates:"
        echo "$AVAILABLE_CERTS"
        
        # Look for ClickIt-specific certificate first in the list
        CLICKIT_CERT=$(echo "$AVAILABLE_CERTS" | grep -i "clickit" | head -1 | sed 's/.*"\(.*\)".*/\1/')
        if [ -n "$CLICKIT_CERT" ]; then
            CERT_NAME="$CLICKIT_CERT"
            echo "✅ Found ClickIt-specific certificate: $CERT_NAME"
        else
            # Fall back to first available certificate
            FIRST_CERT=$(echo "$AVAILABLE_CERTS" | head -1 | sed 's/.*"\(.*\)".*/\1/')
            if [ -n "$FIRST_CERT" ]; then
                CERT_NAME="$FIRST_CERT"
                echo "⚠️  Using first available certificate: $CERT_NAME"
            fi
        fi
    fi
fi

if [ -n "$CERT_NAME" ]; then
    echo "🔐 Code signing with certificate: $CERT_NAME"
    if codesign --deep --force --sign "$CERT_NAME" "$APP_BUNDLE" 2>/dev/null; then
        echo "✅ Code signing successful!"
        
        # Verify the signature
        if codesign --verify --verbose "$APP_BUNDLE" 2>/dev/null; then
            echo "✅ Code signature verification passed"
        else
            echo "⚠️  Code signature verification failed, but app was signed"
        fi
    else
        echo "⚠️  Code signing failed, but app will still work (permissions may not persist)"
    fi
else
    echo "⚠️  No code signing certificates found"
    echo "📋 To improve permission persistence, create a self-signed certificate:"
    echo "   See CERTIFICATE_SETUP.md for instructions"
fi

# Create build metadata
echo "📋 Creating build metadata..."
cat > "$DIST_DIR/build-info.txt" << EOF
Build Date: $(date)
Mode: $BUILD_MODE
Architectures: ${ARCH_LIST[*]}
Binary Type: $([ ${#BINARY_PATHS[@]} -gt 1 ] && echo "Universal" || echo "Single Architecture")
Version: $VERSION
Build Number: $BUILD_NUMBER
Bundle ID: $BUNDLE_ID
Code Signed: $([ -n "$CERT_NAME" ] && echo "Yes ($CERT_NAME)" || echo "No")
EOF

echo "✅ $APP_NAME.app created successfully!"
echo "📂 Location: $APP_BUNDLE"
echo "📱 Launch with: open \"$APP_BUNDLE\""
echo "🔧 The app should now appear in System Settings > Accessibility"
echo "📋 Build info: $DIST_DIR/build-info.txt"