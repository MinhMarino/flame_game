# Flame Game

Flutter game starter using [Flame](https://flame-engine.org/) with GitHub Actions for iOS CI builds.

## Requirements

- Flutter stable
- Xcode (for local iOS builds)
- CocoaPods

## Getting started

```bash
cd flame_game
flutter pub get
flutter run
```

## Project structure

- `lib/main.dart` — App entry point with `GameWidget`
- `lib/game/flame_starter_game.dart` — Base Flame game class
- `.github/workflows/ios-build.yml` — CI workflow for iOS builds

## GitHub Actions (iOS)

The workflow runs on `macos-latest` and:

1. Installs Flutter dependencies
2. Runs format check, analyzer, and tests
3. Builds iOS with `flutter build ios --release --no-codesign`
4. Uploads `Runner.app` as a workflow artifact

Push to `main` or open a pull request to trigger the workflow.

### Signed IPA builds

The current workflow validates the iOS build without Apple code signing. To produce installable `.ipa` files, add GitHub secrets for:

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`

Then extend the workflow with certificate import and `xcodebuild` archive/export steps.

## Bundle identifier

`com.nguyenminh.flame_game`
