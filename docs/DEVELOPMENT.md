# Development Guide

## Setup

### Prerequisites

- Flutter 3.24+
- Android Studio / VS Code
- Android SDK 21+
- Git

### Installation

```bash
git clone https://github.com/JustCheburek/MaxSpeedVPN.git
cd MaxSpeedVPN
flutter pub get
```

## Project Structure

```
lib/
├── core/                    # Core services and utilities
│   ├── services/            # VPN, parser, sing-box
│   ├── extensions/          # Dart extensions
│   ├── utils/               # Utility functions
│   └── constants/           # App constants
├── data/                    # Data layer
│   ├── models/              # Data models
│   ├── repositories/        # Repository implementations
│   └── datasources/         # Data sources
├── domain/                  # Business logic
│   ├── entities/            # Business entities
│   ├── repositories/        # Repository interfaces
│   └── usecases/            # Use cases
└── presentation/            # UI layer
    ├── screens/             # App screens
    ├── widgets/             # Reusable widgets
    ├── providers/           # State management
    └── theme/               # App theme
```

## Architecture

### Clean Architecture

The project follows Clean Architecture principles:

1. **Domain Layer** -- Business logic, entities, use cases
2. **Data Layer** -- Data access, repositories, models
3. **Presentation Layer** -- UI, state management

### State Management

Uses ChangeNotifier pattern:

```dart
class ConnectionProvider extends ChangeNotifier {
  VpnState _state = VpnState.disconnected;

  VpnState get state => _state;

  void updateState(VpnState newState) {
    _state = newState;
    notifyListeners();
  }
}
```

### VPN Flow

1. User taps connect button
2. App requests VPN permission
3. Subscription is parsed
4. sing-box config is generated
5. VpnService starts with config
6. TUN interface is established
7. Traffic is routed through proxy

## Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/subscription_parser_test.dart

# Run with coverage
flutter test --coverage
```

## Building

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle
flutter build appbundle --release

# Specific architecture
flutter build apk --release --target-platform android-arm64
```

## Code Style

- Follow Effective Dart guidelines
- Use flutter analyze before committing
- Write tests for new features
- Document public API

## Debugging

### Android logs

```bash
adb logcat -s MaxSpeedVPN
```

### Flutter DevTools

```bash
flutter run --debug
# Open DevTools at http://localhost:9100
```

## Common Issues

### VPN permission not granted

The app requires android.permission.BIND_VPN_SERVICE. Ensure the user grants permission when prompted.

### sing-box not found

sing-box binary must be placed in android/app/src/main/assets/sing-box.

### Build fails

- Run flutter clean
- Run flutter pub get
- Check Android SDK version
