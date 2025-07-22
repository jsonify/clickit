#!/usr/bin/env swift

import Foundation
import ApplicationServices

print("🔍 Testing Accessibility Permission Request...")
print("📱 Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

// Test 1: Check current permission status
let currentStatus = AXIsProcessTrusted()
print("📊 Current permission status: \(currentStatus)")

// Test 2: Request permission with prompt
print("🚪 Requesting permission with dialog...")
let accessibilityDialogKey = "AXTrustedCheckOptionPrompt"
let options = [accessibilityDialogKey: true] as CFDictionary
let result = AXIsProcessTrustedWithOptions(options)

print("✅ Request result: \(result)")
print("📝 Note: If no dialog appeared, there may be an entitlements or code signing issue")

// Test 3: Check again after request
let statusAfter = AXIsProcessTrusted()
print("📊 Status after request: \(statusAfter)")

if !result {
    print("❌ Permission not granted - check System Settings > Privacy & Security > Accessibility")
} else {
    print("✅ Permission granted successfully!")
}