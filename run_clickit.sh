#!/bin/bash

# Build and run ClickIt with proper window activation
echo "Building ClickIt..."
swift build

if [ $? -eq 0 ]; then
    echo "Launching ClickIt..."
    # Run in background and get PID
    ./.build/x86_64-apple-macosx/debug/ClickIt &
    APP_PID=$!
    
    # Wait a moment for app to initialize
    sleep 2
    
    # Force activation using osascript
    osascript -e 'tell application "System Events" to tell process "ClickIt" to set frontmost to true' 2>/dev/null
    
    # Also try activating by process name
    osascript -e 'tell application "ClickIt" to activate' 2>/dev/null
    
    echo "ClickIt launched with PID: $APP_PID"
    echo "If window doesn't appear, check Activity Monitor or Dock"
    echo "Press Ctrl+C to quit"
    
    # Wait for app to finish
    wait $APP_PID
else
    echo "Build failed"
    exit 1
fi