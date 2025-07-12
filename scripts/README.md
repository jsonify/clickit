# Build Scripts

## Code Signing

The `sign-app.sh` script requires a code signing identity to be specified via environment variable for security reasons.

### Setup

1. List available certificates:
```bash
security find-identity -v -p codesigning
```

2. Set the environment variable:
```bash
export CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)"
```

3. Run the signing script:
```bash
./scripts/sign-app.sh
```

### Alternative Usage

You can also provide the identity inline:
```bash
CODE_SIGN_IDENTITY="Apple Development: Your Name (TEAM_ID)" ./scripts/sign-app.sh
```

### Security Note

Never commit code signing identities to version control. The environment variable approach ensures sensitive certificate information stays local to your development environment.