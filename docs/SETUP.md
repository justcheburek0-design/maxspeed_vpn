# MaxSpeed VPN — Developer Setup Guide

This guide walks through everything needed to set up the development
environment, configure the project, and build MaxSpeed VPN for the
first time.

---

## Prerequisites

- **Operating System**: Linux (Ubuntu 22.04+), macOS 13+, or Windows 10+
  with WSL2
- **RAM**: 8 GB minimum (16 GB recommended)
- **Disk**: At least 15 GB free for SDKs, tools, and build artifacts

---

## Step 1: Install Flutter SDK

### Linux

```bash
# Install dependencies
sudo apt update
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang \
  cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# Download Flutter (check pubspec.yaml for pinned version)
git clone https://github.com/flutter/flutter.git -b stable \
  --depth 1 $HOME/flutter

# Add to PATH
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### macOS

```bash
# Using Homebrew
brew install --cask flutter

# Or manual installation
git clone https://github.com/flutter/flutter.git -b stable \
  --depth 1 $HOME/flutter
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Verify

```bash
flutter doctor
flutter --version
```

Commit Flutter version is pinned in `.github/FLUTTER_VERSION` in the
repository. Match your local version for consistent builds.

---

## Step 2: Install Android SDK

### Option A: Android Studio (Recommended)

1. Download Android Studio from https://developer.android.com/studio
2. Install and launch — SDK is installed automatically
3. Android Studio Configure > SDK Manager:
   - Android SDK Platform (API 34)
   - Android SDK Build-Tools (latest)
   - NDK (check `android/app/build.gradle` for required version)
   - CMake 3.22+

### Option B: Command Line Tools Only

```bash
mkdir -p $HOME/android-sdk/cmdline-tools
cd $HOME/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-latest.zip
unzip commandlinetools-linux-latest.zip
mv cmdline-tools latest

# Set environment variables
echo 'export ANDROID_HOME=$HOME/android-sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc
source ~/.bashrc

# Install SDK components
sdkmanager "platforms;android-34" "build-tools;34.0.0" \
  "ndk;25.2.9519653" "cmake;3.22.1"
```

### Accept Licenses

```bash
flutter doctor --android-licenses
```

---

## Step 3: Install Additional Tools

```bash
# Protocol Buffers compiler (gRPC integration)
# Linux
sudo apt install -y protobuf-compiler
# macOS
brew install protobuf

# JSON processing (useful for config scripts)
sudo apt install -y jq  # Linux
brew install jq         # macOS
```

---

## Step 4: Clone the Repository

```bash
git clone https://github.com/maxspeedvpn/maxspeed-vpn.git
cd maxspeed-vpn
```

---

## Step 5: Configure Environment

```bash
# Copy template environment files
cp .env.example .env
cp android/local.properties.example android/local.properties

# Edit local.properties with your SDK paths
# For Linux:
sdk.dir=/home/<username>/android-sdk
# For macOS:
sdk.dir=/Users/<username>/Library/Android/sdk
```

### Set Up Signing Keys

For release builds, create or place your keystore:

```bash
# Place keystore
cp /path/to/your/keystore.jks android/app/keystore.jts

# Create key.properties
cat > android/key.properties << EOF
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=keystore.jts
EOF
```

---

## Step 6: Fetch Dependencies

```bash
flutter pub get
```

This installs all Dart/Flutter packages defined in `pubspec.yaml`,
including VPN protocol libraries, state management, and UI components.

---

## Step 7: Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates JSON serializers, gRPC stubs, and Riverpod providers.

---

## Step 8: First Build

### Debug Build

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Run on Device/Emulator

```bash
# Connect a device or start an emulator first
flutter devices
flutter run --debug
```

### Release Build

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## Step 9: Run Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Integration tests
cd integration_test
flutter test
```

---

## Troubleshooting

**Flutter doctor shows Android SDK not found**: Ensure `ANDROID_HOME`
is set and Android SDK tools are in your PATH.

**Build fails with NDK error**: Check `ndkVersion` in
`android/app/build.gradle` matches your installed NDK version.

**Gradle daemon issues**: Run `./android/gradlew --stop` then rebuild.

**Protoc not found**: Verify protobuf-compiler is installed and `protoc`
is in your PATH.
