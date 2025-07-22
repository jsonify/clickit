#!/bin/bash

set -e

PROJECT_NAME="ClickIt"
BUNDLE_ID="com.jsonify.clickit"

echo "🔨 Generating Xcode project for $PROJECT_NAME..."

# Method 1: Try using xcodegen if available
if command -v xcodegen > /dev/null 2>&1; then
    echo "📦 Using xcodegen to create project..."
    
    # Create project.yml for xcodegen
    cat > project.yml << EOF
name: ClickIt
options:
  bundleIdPrefix: com.jsonify
  deploymentTarget:
    macOS: "14.0"
  developmentLanguage: en

packages:
  Sparkle:
    url: https://github.com/sparkle-project/Sparkle
    from: 2.5.2

targets:
  ClickIt:
    type: application
    platform: macOS
    sources:
      - path: Sources/ClickIt
        excludes:
          - "**/*.md"
    resources:
      - Sources/ClickIt/Resources
    dependencies:
      - package: Sparkle
        product: Sparkle
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.jsonify.clickit
        INFOPLIST_FILE: Info.plist
        CODE_SIGN_ENTITLEMENTS: ClickIt.entitlements
        MACOSX_DEPLOYMENT_TARGET: "14.0"
        SWIFT_VERSION: "5.9"
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        COMBINE_HIDPI_IMAGES: true
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ENABLE_HARDENED_RUNTIME: true
        ENABLE_APP_SANDBOX: true
      debug:
        SWIFT_OPTIMIZATION_LEVEL: "-Onone"
      release:
        SWIFT_OPTIMIZATION_LEVEL: "-O"

schemes:
  ClickIt:
    build:
      targets:
        ClickIt: all
    run:
      config: Debug
    profile:
      config: Release
    analyze:
      config: Debug
    archive:
      config: Release
EOF

    xcodegen generate
    echo "✅ Xcode project generated using xcodegen"
    
else
    echo "⚠️  xcodegen not found, using alternative method..."
    echo "📦 Installing xcodegen via Homebrew..."
    
    if command -v brew > /dev/null 2>&1; then
        brew install xcodegen
        echo "✅ xcodegen installed successfully"
        
        # Retry with xcodegen
        exec "$0" "$@"
    else
        echo "❌ Homebrew not found. Please install xcodegen manually:"
        echo "   brew install xcodegen"
        echo "   or download from: https://github.com/yonaskolb/XcodeGen"
        exit 1
    fi
fi

# Post-generation cleanup and configuration
if [ -f "ClickIt.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project created successfully!"
    echo "📁 Project location: ClickIt.xcodeproj"
    echo ""
    echo "🔧 Next steps:"
    echo "   1. Open the project: open ClickIt.xcodeproj"
    echo "   2. Configure your development team in project settings"
    echo "   3. Build and run with ⌘+R"
    echo ""
    echo "💡 The project is now ready for better permissions handling!"
else
    echo "❌ Failed to create Xcode project"
    exit 1
fi

# Clean up temporary files
rm -f project.yml