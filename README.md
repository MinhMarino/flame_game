# Ant Smasher (Flame Game)

Flutter + Flame ant smashing game. Play on the web or build for iOS.

**Play online:** https://minhmarino.github.io/flame_game/

## Requirements

- Flutter stable
- Xcode (for local iOS builds)
- CocoaPods
- Apple Developer account (for signed IPA builds)

## Getting started

```bash
cd flame_game
flutter pub get
flutter run -d chrome
```

## Project structure

- `lib/main.dart` — App entry point with `GameWidget`
- `lib/game/ant_smasher_game.dart` — Ant smasher game logic
- `lib/game/components/` — Crawler, floating score text
- `.github/workflows/deploy-web.yml` — Deploy web build to GitHub Pages
- `.github/workflows/ios-build.yml` — CI workflow for iOS builds
- `scripts/prepare-ios-secrets.sh` — Helper to encode signing files for GitHub Secrets

## GitHub Pages (Web)

Every push to `main` builds and deploys the web version automatically.

Live URL: https://minhmarino.github.io/flame_game/

## GitHub Actions (iOS)

The workflow has two jobs:

1. **Validate** — format, analyze, test, and compile iOS without codesigning
2. **Build signed IPA** — runs on `main` push and manual dispatch, exports an installable `.ipa`

Artifacts:

- `flame-game-ios-<run_number>` — signed `.ipa`
- `flame-game-dsym-<run_number>` — dSYM files for crash symbolication

### Required GitHub Secrets

Add these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
| --- | --- |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64 of your `.p12` distribution certificate |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password for the `.p12` file |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64 of your `.mobileprovision` file |
| `IOS_PROVISIONING_PROFILE_NAME` | Exact profile name from Apple Developer |
| `IOS_DEVELOPMENT_TEAM` | Apple Team ID (10 characters) |
| `KEYCHAIN_PASSWORD` | Any random string used for the temporary CI keychain |

### Optional repository variable

| Variable | Default | Values |
| --- | --- | --- |
| `IOS_EXPORT_METHOD` | `ad-hoc` | `ad-hoc`, `app-store`, `development`, `enterprise` |

Use `ad-hoc` to install on registered devices. Use `app-store` for TestFlight/App Store uploads.

### Prepare secrets locally

```bash
chmod +x scripts/prepare-ios-secrets.sh
./scripts/prepare-ios-secrets.sh certificate ~/Downloads/distribution.p12
./scripts/prepare-ios-secrets.sh profile ~/Downloads/FlameGame.mobileprovision
```

Copy the printed base64 values into GitHub Secrets.

### Apple Developer setup

1. Create an **Apple Distribution** certificate in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources)
2. Create an App ID for `com.nguyenminh.flameGame`
3. Create a provisioning profile:
   - **Ad Hoc** for direct device install
   - **App Store** for TestFlight
4. Export the certificate as `.p12`
5. Download the `.mobileprovision` file

## Bundle identifier

`com.nguyenminh.flameGame`
