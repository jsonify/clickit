#!/bin/bash

echo "🔧 Configuring Xcode developer path for ClickIt builds..."

# Check current path
CURRENT_PATH=$(xcode-select -p)
echo "📍 Current developer path: $CURRENT_PATH"

# Check if Xcode.app exists
if [ -d "/Applications/Xcode.app" ]; then
    XCODE_PATH="/Applications/Xcode.app/Contents/Developer"
    echo "✅ Found Xcode at: /Applications/Xcode.app"
    
    if [ "$CURRENT_PATH" != "$XCODE_PATH" ]; then
        echo "🔄 Switching to Xcode developer path..."
        echo "💡 Run this command to use Xcode for builds:"
        echo "   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        echo ""
        echo "🔄 Or run it automatically (will require sudo password):"
        read -p "Switch to Xcode path now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
            echo "✅ Switched to Xcode developer path"
        else
            echo "⏭️  Skipping automatic switch"
        fi
    else
        echo "✅ Already using Xcode developer path"
    fi
    
    # Test xcodebuild
    echo "🧪 Testing xcodebuild availability..."
    if command -v xcodebuild > /dev/null 2>&1; then
        XCODE_VERSION=$(xcodebuild -version | head -1)
        echo "✅ $XCODE_VERSION is available"
        echo "🎉 Ready for Xcode builds!"
    else
        echo "❌ xcodebuild not available"
        echo "💡 Make sure Xcode is properly installed and try switching paths"
    fi
else
    echo "❌ Xcode.app not found at /Applications/Xcode.app"
    echo "💡 Install Xcode from the Mac App Store or https://developer.apple.com/xcode/"
fi

echo ""
echo "📚 Usage:"
echo "  • Use Command Line Tools: sudo xcode-select -s /Library/Developer/CommandLineTools"
echo "  • Use full Xcode: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
echo "  • Check current: xcode-select -p"