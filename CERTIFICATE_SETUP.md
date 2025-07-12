# Self-Signed Certificate Setup for ClickIt

This guide walks you through creating a self-signed certificate to enable code signing for ClickIt without requiring an Apple Developer account. This will help maintain permission persistence across app rebuilds.

## Why Code Signing Helps

When your app is code-signed (even with a self-signed certificate), macOS can better track the app's identity across different builds. This means:
- Accessibility permissions persist between rebuilds
- Screen Recording permissions don't need to be re-granted as frequently
- The app appears more consistently in System Settings

## One-Time Certificate Setup

### Step 1: Create the Certificate

1. Open **Keychain Access** (Applications > Utilities > Keychain Access)
2. From the menu bar, choose **Keychain Access > Certificate Assistant > Create a Certificate**
3. Fill in the certificate details:
   - **Name**: `ClickIt Developer Certificate` (or any name you prefer)
   - **Identity Type**: Self Signed Root
   - **Certificate Type**: Code Signing
   - **Let me override defaults**: ✓ (check this box)
4. Click **Continue**
5. Set the following options:
   - **Serial Number**: Leave default
   - **Validity Period**: 3650 days (about 10 years)
   - Click **Continue**
6. Keep clicking **Continue** through the remaining screens with default settings
7. On the final screen, ensure **Keychain** is set to **login** 
8. Click **Create**

### Step 2: Verify Certificate Creation

1. In Keychain Access, select the **login** keychain on the left
2. Look for your certificate name (e.g., "ClickIt Developer Certificate") in the list
3. The certificate should show a key icon next to it, indicating it includes a private key

### Step 3: Find Your Certificate Identity

1. Open **Terminal**
2. Run this command to list available code signing identities:
   ```bash
   security find-identity -v -p codesigning
   ```
3. Look for your certificate in the output. You'll see something like:
   ```
   1) A1B2C3D4E5F6... "ClickIt Developer Certificate"
   ```
4. Copy the **certificate name** (the part in quotes) - you'll need this for the build script

## Using the Certificate

Once you've created the certificate, the build script (`build_app.sh`) will automatically detect and use it for code signing. 

### Manual Code Signing (Optional)

If you want to manually sign an existing app bundle:

```bash
codesign --deep --force --sign "ClickIt Developer Certificate" dist/ClickIt.app
```

Replace `"ClickIt Developer Certificate"` with your actual certificate name.

### Verify Code Signing

To check if an app is properly signed:

```bash
codesign --verify --verbose dist/ClickIt.app
spctl --assess --verbose dist/ClickIt.app
```

## Troubleshooting

### Certificate Not Found
If the build script can't find your certificate:
1. Make sure the certificate is in your **login** keychain (not System)
2. Verify the certificate name matches exactly
3. Check that the certificate has code signing capabilities

### Permission Denied
If you get permission errors:
1. Make sure you have admin rights on your Mac
2. Try unlocking your keychain: `security unlock-keychain ~/Library/Keychains/login.keychain`

### Gatekeeper Warnings
Self-signed certificates will still trigger Gatekeeper warnings for other users. To bypass:
1. Right-click the app and choose "Open" (instead of double-clicking)
2. Or go to System Settings > Privacy & Security and click "Open Anyway"

## Notes

- This certificate only works on your local machine
- Other users will still see Gatekeeper warnings
- For distribution to other users, you'd need an Apple Developer certificate
- The certificate is valid for 10 years, so this is a one-time setup
- This doesn't provide the same level of trust as Apple-issued certificates, but helps with permission persistence