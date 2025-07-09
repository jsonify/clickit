#!/bin/bash

# Build ClickIt as a proper macOS app bundle

echo "Building ClickIt app bundle..."

# Clean previous builds
rm -rf ClickIt.app

# Build the executable
swift build -c release

if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

# Create app bundle structure
mkdir -p ClickIt.app/Contents/MacOS
mkdir -p ClickIt.app/Contents/Resources

# Copy executable
cp .build/x86_64-apple-macosx/release/ClickIt ClickIt.app/Contents/MacOS/

# Create Info.plist
cat > ClickIt.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>ClickIt</string>
    <key>CFBundleExecutable</key>
    <string>ClickIt</string>
    <key>CFBundleIdentifier</key>
    <string>com.jsonify.clickit</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ClickIt</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
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
chmod +x ClickIt.app/Contents/MacOS/ClickIt

echo "✅ ClickIt.app created successfully!"
echo "📱 Launch with: open ClickIt.app"
echo "🔧 The app should now appear in System Settings > Accessibility"