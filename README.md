# MaxSpeedVPN

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-android-green.svg)](https://android.com)
[![sing-box](https://img.shields.io/badge/sing--box-1.13.0-1E90FF.svg)](https://sing-box.sagernet.org/)

**MaxSpeedVPN** — a fast, modern, open-source VPN client for Android built with [Flutter](https://flutter.dev) and [sing-box](https://sing-box.sagernet.org/).

Supports VLESS (+ XTLS REALITY), VMess, Trojan, Shadowsocks, NaiveProxy, and WireGuard protocols with an intuitive Material You interface.

| | Quick Links |
|---|---|
| **Package** | `ru.maxspeed.maxspeed_vpn` |
| **Source** | [github.com/maxspeed-vpn/maxspeed_vpn](https://github.com/maxspeed-vpn/maxspeed_vpn) |
| **Telegram** | [t.me/maxspeed_vpn](https://t.me/maxspeed_vpn) |
| **Support** | support@maxspeed.vpn |

---

## Features

### Core VPN
- **One-tap connect** — fastest server auto-selection or manual picker
- **Multi-protocol** — VLESS (+ XTLS REALITY), VMess, Trojan, Shadowsocks, NaiveProxy, WireGuard
- **Subscription management** — import servers via URL or QR code (Base64 & plain text formats)
- **Real-time traffic monitoring** — live download/upload stats with duration timer
- **Ping measurement** — automatic server health check with latency display
- **Auto-reconnect** — configurable retry with exponential backoff
- **Kill switch** — block all traffic on unexpected disconnect
- **Per-app routing** — include or exclude apps from VPN tunnel

### Security & Privacy
- **XTLS REALITY** — state-of-the-art censorship circumvention with minimal fingerprint
- **TLS 1.3** — modern encryption for all TLS-based protocols
- **uTLS fingerprinting** — mimic Chrome / Firefox / Safari TLS fingerprints
- **DNS-over-HTTPS** — private DNS resolution to prevent leaks
- **No local traffic logging** — connection metadata is not persisted by default
- **Open source** — fully auditable codebase under GPL-3.0

### User Experience
- **Material You design** — dynamic colors, smooth animations, haptic feedback
- **Onboarding flow** — first-run wizard with permission requests
- **Server search & filter** — by country, protocol, or name
- **Built-in speed test** — throughput measurement with animated gauge
- **Connection diagnostics** — detailed logs and error reporting
- **Localization** — Russian and English
- **Adaptive layouts** — bottom nav on phones, sidebar on tablets/desktop

---

## Architecture

MaxSpeedVPN follows a **layered architecture** with clear separation of concerns.

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ Screens  │ │ Widgets  │ │  Providers   │ │    Theme     │  │
│  │ (Pages)  │ │(Reusable)│ │(ChangeNotif.)│ │ Material You │  │
│  └────┬─────┘ └────┬─────┘ └──────┬───────┘ └──────────────┘  │
├───────┼─────────────┼──────────────┼────────────────────────────┤
│  CORE LAYER         │              │                            │
│  ┌────┴─────────────┴──────────────┴──┐ ┌──────────────────┐  │
│  │           Services                 │ │    Constants     │  │
│  │  VPN · Parser · Logs · Settings   │ │  Enums · Keys    │  │
│  ├────────────────────────────────────┤ ├──────────────────┤  │
│  │        Protocol Parsers            │ │   App Router     │  │
│  │  VLESS · VMess · Trojan · SS · Naive│ │   (GoRouter)     │  │
│  ├────────────────────────────────────┤ └──────────────────┘  │
│  │   sing-box Config Generator        │                        │
│  └────────────────────────────────────┘                        │
├─────────────────────────────────────────────────────────────────┤
│                    PLATFORM LAYER (Kotlin)                      │
│  ┌──────────────────┐ ┌────────────────┐ ┌──────────────────┐  │
│  │  MaxSpeedVpnServ.│ │  MethodChannel │ │  SingBoxProcess  │  │
│  │  VpnService+TUN  │ │  Flutter ↔     │ │  Process manager │  │
│  │  Notification    │ │  Android       │ │  stdout/stderr   │  │
│  └──────────────────┘ └────────────────┘ └──────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Connection Data Flow

```
User taps "Connect"
       │
       ▼
ConnectionProvider.connect(server)
       │
       ├──→ SubscriptionParser.parse(server.link)
       │         └──→ ParsedServer(address, port, uuid, ...)
       │
       ├──→ SingBoxConfigGenerator.generate(parsedServer)
       │         └──→ sing-box JSON config
       │
       ├──→ MethodChannel.invokeMethod('connect', {config})
       │
       ▼
MainActivity → MaxSpeedVpnService (foreground)
       │
       ├──→ Extract sing-box binary from assets
       ├──→ Write config to filesDir
       ├──→ SingBoxProcess.start() → sing-box subprocess
       ├──→ VpnService.Builder.establish() → TUN interface
       └──→ startForeground(notification)
       │
       ▼
sing-box establishes proxy → TUN routes all traffic
       │
       ▼
BroadcastReceiver → MethodChannel "onStatusChanged"
       │
       ▼
ConnectionProvider updates state → UI rebuilds reactively
```

### State Management

| Provider | Domain | Storage |
|---|---|---|
| `ConnectionProvider` | VPN state, traffic stats, duration | In-memory + SharedPreferences |
| `ServersProvider` | Server list, filters, sort, search | SharedPreferences (JSON) |
| `SettingsProvider` | Theme, language, auto-connect, DNS, kill switch | SharedPreferences (JSON) |

All providers use the **ChangeNotifier** pattern and are accessed via `Provider.of<T>(context)` or `context.watch<T>()`.

---

## Protocol Support

| Protocol | Status | Transport | Security | Notes |
|---|---|---|---|---|
| **VLESS + XTLS REALITY** | ✅ | TCP, WebSocket, gRPC | REALITY, TLS | Recommended — best censorship resistance |
| **VLESS + TLS** | ✅ | TCP, WebSocket, gRPC | TLS 1.3 | Standard secure mode |
| **VMess** | ✅ | TCP, WebSocket, gRPC, H2 | TLS, auto | alterId=0, auto security |
| **Trojan** | ✅ | TCP, WebSocket | TLS 1.3 | Password-based auth |
| **Shadowsocks** | ✅ | TCP, UDP | AEAD ciphers | AES-256-GCM, ChaCha20-Poly1305 |
| **NaiveProxy** | ✅ | HTTPS | TLS 1.3 | `naive+https://user:pass@host` |
| **WireGuard** | 🔜 | UDP | Noise protocol | Planned |
| **Hysteria2** | 🔜 | QUIC | TLS 1.3 | Planned |
| **TUIC** | 🔜 | QUIC | TLS 1.3 | Planned |

---

## Build Guide

### Prerequisites

| Requirement | Version |
|---|---|
| Flutter SDK | ≥ 3.3.0 (latest stable recommended) |
| Dart SDK | ≥ 3.9.2 |
| Android SDK | API 21+ (target: 36) |
| Android NDK | 28.2.13676358 |
| Gradle | 8.7+ |
| Java | 17+ |

### Environment Setup

```bash
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH=$PATH:/opt/flutter/bin:$ANDROID_HOME/platform-tools

flutter doctor -v
```

### Clone & Install

```bash
git clone https://github.com/maxspeed-vpn/maxspeed_vpn.git
cd maxspeed_vpn
flutter pub get
flutter analyze
```

### sing-box Binary

The sing-box binary must be bundled as an Android asset:

```bash
# Download latest release (adjust version/arch)
wget https://github.com/SagerNet/sing-box/releases/download/v1.13.0/sing-box-1.13.0-android-arm64-v8a.tar.gz
tar xzf sing-box-1.13.0-android-arm64-v8a.tar.gz

mkdir -p android/app/src/main/assets
cp sing-box-1.13.0-android-arm64-v8a/sing-box android/app/src/main/assets/sing-box
chmod +x android/app/src/main/assets/sing-box
```

### Build Commands

```bash
# Debug run on device
flutter run --debug

# Release APK (all architectures)
flutter build apk --release

# Release APK (arm64 only)
flutter build apk --release --target-platform android-arm64

# App Bundle (Play Store)
flutter build appbundle --release

# Split per ABI
flutter build apk --release --split-per-abi
```

### Testing

```bash
flutter test
flutter test test/services/subscription_parser_test.dart
flutter test --coverage
```

---

## Project Structure

```
maxspeed_vpn/
├── android/                          # Android native (Kotlin)
│   └── app/src/main/
│       ├── assets/sing-box           # Bundled binary
│       ├── kotlin/.../maxspeed_vpn/
│       │   ├── MainActivity.kt       # MethodChannel bridge
│       │   ├── MaxSpeedVpnService.kt  # VpnService + TUN
│       │   └── SingBoxProcess.kt     # Process lifecycle
│       └── AndroidManifest.xml
├── lib/                              # Dart/Flutter source
│   ├── core/                         # Constants, router, theme, utils
│   ├── data/                         # Models, repositories, datasources
│   ├── presentation/                 # Screens, widgets, providers
│   ├── services/                     # Business services
│   └── vpn/                          # Config generator, parsers
├── test/                             # Unit & widget tests
└── docs/                             # Documentation
```

---

## Contributing

We welcome bug reports, feature suggestions, code improvements, and docs.

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Run `flutter analyze && flutter test` before committing
4. Submit a Pull Request with a clear description

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

MaxSpeedVPN — Copyright (C) 2026 MaxSpeedVPN Contributors.  
This program is free software licensed under GPL-3.0. See [LICENSE](https://github.com/maxspeed-vpn/maxspeed_vpn/blob/main/LICENSE) for details.
