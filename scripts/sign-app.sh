#!/bin/bash

# Sign ClickIt app for stable permissions
# Usage: ./scripts/sign-app.sh

set -e

echo "🔐 Signing ClickIt app..."

# Build the app first
swift build

# Copy to app bundle (if not already done by build script)
if [ ! -d "dist/ClickIt.app" ]; then
    echo "❌ App bundle not found at dist/ClickIt.app"
    echo "   Run the build script first to create the app bundle"
    exit 1
fi

# Sign with development certificate
codesign --force --sign "Apple Development: Jason Rueckert (5K35266D72)" --timestamp dist/ClickIt.app

# Verify signing
echo "✅ Verifying signature..."
codesign -dv dist/ClickIt.app

echo "🎉 App signed successfully!"
echo "   Identifier: $(codesign -dr - dist/ClickIt.app 2>&1 | grep 'Identifier=')"
echo "   Authority: $(codesign -dv dist/ClickIt.app 2>&1 | grep 'Authority=' | head -1)"