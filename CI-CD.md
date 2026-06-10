# CI/CD Pipeline Documentation

MaxSpeed VPN uses GitHub Actions for continuous integration and continuous
deployment. This document describes the complete build, test, and deploy
pipeline.

---

## Pipeline Overview

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Lint &  │───▶│  Build   │───▶│  Test    │───▶│  Deploy  │
│  Format  │    │  (Multi) │    │  (Multi) │    │  (Multi) │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

---

## Workflows

### 1. Main CI Workflow (`ci.yml`)

Triggered on: `push` to `main`, `develop`, and `pull_request` to `main`.

**Jobs:**

#### Job: lint
- Runs Dart/Flutter analyzer (`flutter analyze`)
- Runs `dart format --set-exit-if-changed`
- Checks for trailing whitespace and line length violations
- Enforces `analysis_options.yaml` strict mode rules
- Duration: ~2 minutes

#### Job: test
- Unit test suite: `flutter test --coverage`
- Widget test suite: `flutter test test/widget/`
- Integration test suite: `flutter test integration_test/`
- Uploads coverage report to Codecov
- Minimum coverage threshold: 80%
- Duration: ~8 minutes

#### Job: build-android
- Builds debug APK: `flutter build apk --debug`
- Builds release APK: `flutter build apk --release`
- Builds App Bundle: `flutter build appbundle`
- Signs release artifacts with CI keystore
- Uploads artifacts to GitHub Actions storage
- Matrix strategy: latest stable Flutter SDK
- Duration: ~12 minutes

#### Job: security-scan
- Runs `dart pub audit` for dependency vulnerability scanning
- Scans Android manifest for common misconfigurations
- Checks for hardcoded secrets using `gitleaks`
- Runs SAST scan on native code layers
- Reports findings as PR annotations
- Duration: ~5 minutes

---

### 2. Release Workflow (`release.yml`)

Triggered on: GitHub release creation or tag push (`v*`).

**Jobs:**

#### Job: build-release
- Builds signed release APK and App Bundle
- Uses release keystore from GitHub Secrets
- Generates changelog from conventional commits
- Matrix builds for Android (arm64, x86_64)
- Duration: ~15 minutes

#### Job: deploy-play-store
- Uploads App Bundle to Google Play Internal Track
- Uses Google Play Publishing API via GitHub Action
- Auto-promotes from internal to production on approval
- Requires `PLAY_STORE_SERVICE_ACCOUNT` secret
- Duration: ~3 minutes (plus Play Store review time)

#### Job: deploy-github
- Attaches APK and App Bundle to GitHub Release
- Includes SHA-256 checksums for all artifacts
- Generates and attaches SBOM (Software Bill of Materials)
- Duration: ~2 minutes

#### Job: deploy-fdroid (conditional)
- Builds reproducible APK for F-Droid inclusion
- Triggered only on stable release tags
- Duration: ~10 minutes

---

### 3. PR Quality Gate (`pr-gate.yml`)

Triggered on: `pull_request` synchronize and review events.

- Runs all lint checks
- Runs all unit and widget tests
- Checks branch is up-to-date with base branch
- Enforces conventional commit PR titles
- Requires at least one reviewer approval
- All checks must pass before merge is allowed

---

## Required Secrets

Configure these in GitHub repository Settings > Secrets:

| Secret Name                  | Purpose                          |
|------------------------------|----------------------------------|
| `CI_KEYSTORE_BASE64`         | Base64-encoded debug keystore    |
| `CI_KEYSTORE_PASSWORD`       | Debug keystore password          |
| `RELEASE_KEYSTORE_BASE64`    | Base64-encoded release keystore  |
| `RELEASE_KEYSTORE_PASSWORD`  | Release keystore password        |
| `KEY_ALIAS`                  | Key alias for signing            |
| `KEY_PASSWORD`               | Key password for signing         |
| `PLAY_STORE_SERVICE_ACCOUNT` | Google Play service account JSON |
| `GITLEAKS_LICENSE`           | Gitleaks enterprise license key  |
| `CODECOV_TOKEN`              | Codecov upload token             |

---

## Branching Strategy

- `main` — production-ready, protected branch
- `develop` — integration branch for features
- `feature/*` — individual feature branches
- `hotfix/*` — urgent production fixes
- `release/*` — release preparation branches

---

## Local CI Simulation

Run the full CI pipeline locally before pushing:

```bash
# Lint
flutter analyze --fatal-infos
dart format --set-exit-if-changed lib/ test/

# Test
flutter test --coverage --coverage-path=coverage/lcov.info

# Build
flutter build apk --release
flutter build appbundle --release
```

---

## Monitoring & Notifications

- Build status badges displayed in README.md
- Slack/Discord notifications on `main` branch failures
- Email alerts to maintainers on security scan findings
- Weekly build health digest sent to team

---

## Troubleshooting

**Flutter SDK version mismatch**: The CI uses the version pinned in
`.github/FLUTTER_VERSION`. Ensure local Flutter matches.

**Keystore issues**: If signing fails, regenerate keystore and re-encode:
```bash
base64 -w0 < keystore.jks > keystore.base64
```

**Test flakiness**: Flaky tests are quarantined in `test/quarantine/`.
File an issue if a test is intermittently failing.
