#!/bin/bash

# Helper script to create a self-signed code signing certificate for ClickIt
# This helps with macOS permission persistence across app launches

set -e

echo "🔐 Creating self-signed code signing certificate for ClickIt..."

CERT_NAME="ClickIt Developer"
KEYCHAIN_PATH="$HOME/Library/Keychains/login.keychain-db"

# Check if certificate already exists
if security find-identity -v -p codesigning | grep -q "$CERT_NAME"; then
    echo "✅ Certificate '$CERT_NAME' already exists"
    echo "🔑 Available signing identities:"
    security find-identity -v -p codesigning | grep "$CERT_NAME" | head -5
    exit 0
fi

echo "📝 Creating new self-signed certificate..."
echo "   Name: $CERT_NAME"
echo "   Purpose: Code Signing"
echo "   Keychain: login"

# Create the certificate
security create-certificate \
    -a \
    -s "$CERT_NAME" \
    -S \
    -k "$KEYCHAIN_PATH" \
    -A \
    -t CodeSigning \
    -f

if [ $? -eq 0 ]; then
    echo "✅ Certificate created successfully!"
    echo ""
    echo "🔑 Your new signing identity:"
    security find-identity -v -p codesigning | grep "$CERT_NAME"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Run ./build_app.sh to build and sign your app"
    echo "   2. The app will now be code signed for better macOS integration"
    echo "   3. This should help maintain permissions across app launches"
    echo ""
    echo "🔧 Note: This is a self-signed certificate for local development."
    echo "         For distribution, you'll need an Apple Developer ID certificate."
else
    echo "❌ Failed to create certificate"
    echo "💡 You can also create one manually:"
    echo "   1. Open Keychain Access"
    echo "   2. Certificate Assistant > Create a Certificate"
    echo "   3. Name: '$CERT_NAME', Type: Code Signing"
    echo "   4. Let me override defaults > Continue > Continue"
    echo "   5. Certificate location: System, Continue, Done"
    exit 1
fi