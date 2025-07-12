#!/bin/bash

# Sign ClickIt app for stable permissions
# Usage: ./scripts/sign-app.sh

set -e

echo "🔐 Signing ClickIt app..."

# Copy to app bundle (if not already done by build script)
if [ ! -d "dist/ClickIt.app" ]; then
    echo "❌ App bundle not found at dist/ClickIt.app"
    echo "   Run the build script first to create the app bundle"
    exit 1
fi

# Sign with development certificate
if [ -z "$CODE_SIGN_IDENTITY" ]; then
    echo "❌ CODE_SIGN_IDENTITY environment variable not set"
    echo "   Set it with: export CODE_SIGN_IDENTITY=\"Apple Development: Your Name (TEAM_ID)\""
    echo "   Or run: CODE_SIGN_IDENTITY=\"Apple Development: Your Name (TEAM_ID)\" ./scripts/sign-app.sh"
    exit 1
fi

echo "🔐 Using certificate: $CODE_SIGN_IDENTITY"
codesign --force --sign "$CODE_SIGN_IDENTITY" --timestamp dist/ClickIt.app

# Verify signing
echo "✅ Verifying signature..."
codesign -dv dist/ClickIt.app

echo "🎉 App signed successfully!"
echo "   Identifier: $(codesign -dr - dist/ClickIt.app 2>&1 | grep 'Identifier=')"
echo "   Authority: $(codesign -dv dist/ClickIt.app 2>&1 | grep 'Authority=' | head -1)"