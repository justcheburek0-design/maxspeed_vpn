# MaxSpeedVPN — Architecture Documentation

> **Version:** 3.2.1 · **Last Updated:** 2026-06-10
> **Stack:** Flutter 3.x / Dart 3.9+ · Kotlin · sing-box 1.13.0 · Android SDK 36

---

## Table of Contents

1. [Project Structure Tree](#1-project-structure-tree)
2. [Layered Architecture](#2-layered-architecture)
3. [Data Flow](#3-data-flow)
4. [State Management (ChangeNotifier)](#4-state-management)
5. [VPN Integration Pipeline](#5-vpn-integration-pipeline)
6. [Subscription Parsing](#6-subscription-parsing)
7. [MethodChannel Bridge](#7-methodchannel-bridge)
8. [sing-box Integration](#8-sing-box-integration)
9. [Navigation & Routing](#9-navigation--routing)
10. [Theming System](#10-theming-system)
11. [Error Handling](#11-error-handling)
12. [Build Configuration](#12-build-configuration)

---

## 1. Project Structure Tree

```
maxspeed_vpn/
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── assets/
│   │   │   │   └── sing-box              # Bundled sing-box binary (arm64-v8a)
│   │   │   ├── kotlin/
│   │   │   │   ├── com/maxspeed/vpn/     # Legacy namespace (migration artifact)
│   │   │   │   │   ├── VpnService.kt     # Alternate VPN service impl
│   │   │   │   │   └── MethodChannelHandler.kt
│   │   │   │   └── ru/maxspeed/maxspeed_vpn/  # Active namespace
│   │   │   │       ├── MainActivity.kt        # Flutter engine + MethodChannel
│   │   │   │       ├── MaxSpeedVpnService.kt   # VpnService + TUN + sing-box
│   │   │   │       ├── SingBoxProcess.kt      # External process wrapper
│   │   │   │       └── NetworkUtils.kt        # Network helper utilities
│   │   │   └── AndroidManifest.xml
│   │   └── build.gradle.kts
│   ├── build.gradle.kts
│   └── gradle/wrapper/
├── lib/
│   ├── main.dart                          # App entry: ProviderScope + MaterialApp
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart         # 540 lines: all constants, enums, keys
│   │   ├── extensions/
│   │   │   ├── context_extensions.dart    # BuildContext helpers (screenWidth, etc.)
│   │   │   ├── string_extensions.dart     # String parsing utilities
│   │   │   └── duration_extensions.dart   # Duration formatting
│   │   ├── router/
│   │   │   └── app_router.dart            # GoRouter configuration (5 routes)
│   │   ├── services/
│   │   │   ├── vpn_service.dart           # Dart-side VPN service abstraction
│   │   │   ├── singbox_manager.dart       # Dart-side sing-box lifecycle manager
│   │   │   └── subscription_parser.dart   # Multi-protocol link parser
│   │   ├── theme/
│   │   │   ├── app_colors.dart            # Material You color definitions
│   │   │   ├── app_theme.dart             # ThemeData factory (light/dark)
│   │   │   └── app_typography.dart        # Text theme definitions
│   │   └── utils/
│   │       ├── url_parser.dart            # URL parsing utilities
│   │       ├── encryption.dart            # Base64, hashing utilities
│   │       ├── validators.dart            # Input validation
│   │       └── debounce.dart              # Debounce/throttle helpers
│   ├── data/
│   │   ├── models/
│   │   │   ├── vpn_models.dart            # ServerModel, SubscriptionModel, etc.
│   │   │   └── settings_model.dart        # Settings data class
│   │   ├── repositories/
│   │   │   ├── server_repository.dart     # Server CRUD operations
│   │   │   └── subscription_repository.dart
│   │   └── datasources/
│   │       ├── local_storage.dart         # SharedPreferences wrapper
│   │       └── remote_api.dart            # HTTP client for subscriptions
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── connection_provider.dart   # VPN connection state (ChangeNotifier)
│   │   │   ├── servers_provider.dart      # Server list state (ChangeNotifier)
│   │   │   └── settings_provider.dart     # App settings state (ChangeNotifier)
│   │   ├── screens/
│   │   │   ├── home/
│   │   │   │   ├── home_screen.dart       # Main dashboard (desktop + mobile)
│   │   │   │   └── sidebar.dart           # Desktop sidebar navigation
│   │   │   ├── servers/
│   │   │   │   └── servers_screen.dart    # Server list with filters
│   │   │   ├── settings/
│   │   │   │   └── settings_screen.dart   # Settings pages
│   │   │   ├── logs/
│   │   │   │   └── logs_screen.dart       # VPN connection logs
│   │   │   ├── speed/
│   │   │   │   └── speed_test_screen.dart # Speed test tool
│   │   │   └── onboarding/
│   │   │       └── onboarding_screen.dart # First-run wizard
│   │   ├── theme/
│   │   │   └── app_colors.dart            # Semantic color tokens
│   │   └── widgets/
│   │       ├── common/
│   │       │   ├── app_card.dart          # Reusable card component
│   │       │   ├── app_button.dart        # Styled button variants
│   │       │   └── app_dialog.dart        # Dialog templates
│   │       └── vpn/
│   │           ├── connection_button.dart # Animated connect/disconnect button
│   │           ├── server_list_item.dart  # Server row with ping, flag, protocol
│   │           ├── traffic_chart.dart     # Real-time traffic graph
│   │           └── status_indicator.dart  # Connection state indicator
│   ├── services/
│   │   ├── subscription_service.dart      # Fetch + store subscriptions
│   │   ├── settings_service.dart          # Persist/load settings
│   │   ├── log_service.dart               # Log collection and retrieval
│   │   ├── analytics_service.dart         # Analytics event tracking
│   │   ├── notification_service.dart      # Push notification management
│   │   ├── permission_service.dart        # Runtime permission handling
│   │   └── update_service.dart            # App update checking
│   └── vpn/
│       ├── singbox_config_generator.dart  # Generate sing-box JSON from server
│       └── naive_parser.dart              # NaiveProxy link parser
├── test/
│   ├── core/
│   │   ├── services/
│   │   │   └── subscription_parser_test.dart  # Parser unit tests
│   │   └── utils/
│   │       └── url_parser_test.dart
│   ├── services/
│   │   └── subscription_service_test.dart
│   └── presentation/
│       └── widgets/
│           └── connection_button_test.dart
├── docs/
│   ├── ARCHITECTURE.md                    # This file
│   ├── CONTRIBUTING.md                    # Contribution guidelines
│   ├── SETUP.md                           # Build/install instructions
│   ├── PARSING.md                         # Protocol parsing documentation
│   ├── API.md                             # API reference
│   ├── UI_COMPONENTS.md                   # Widget catalog
│   └── DEVELOPMENT.md                     # Developer guide
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 2. Layered Architecture

MaxSpeedVPN uses a **three-layer architecture** with unidirectional data flow:

```
┌──────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                         │
│  Screens → Widgets → Providers (ChangeNotifier)              │
│  Reacts to state changes, dispatches user actions             │
├──────────────────────────────────────────────────────────────┤
│                       CORE LAYER                              │
│  Services → Parsers → Router → Constants → Theme             │
│  Business logic, protocol handling, platform abstraction      │
├──────────────────────────────────────────────────────────────┤
│                     PLATFORM LAYER                            │
│  VpnService (Kotlin) → MethodChannel → sing-box (binary)     │
│  Android system integration, TUN interface, VPN tunnel        │
└──────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**Presentation Layer** (`lib/presentation/`)
- Owns all UI: screens, widgets, animations
- Providers hold mutable state and notify listeners
- No direct platform calls — delegates to Core services
- Screens are stateless where possible; stateful only for local UI state

**Core Layer** (`lib/core/`, `lib/vpn/`, `lib/services/`)
- `VpnService` — Dart abstraction over MethodChannel VPN operations
- `SubscriptionParser` — Parses VLESS/VMess/Trojan/SS/Naive links
- `SingBoxConfigGenerator` — Builds sing-box JSON configuration
- `AppRouter` — GoRouter navigation graph
- Constants, themes, utilities

**Platform Layer** (`android/.../kotlin/`)
- `MainActivity` — Flutter engine host, MethodChannel server, BroadcastReceiver
- `MaxSpeedVpnService` — Android VpnService, manages TUN, launches sing-box
- `SingBoxProcess` — External process lifecycle (start, stop, log capture)

---

## 3. Data Flow

### Connection Flow (Happy Path)

```
User taps "Connect"
       │
       ▼
HomeScreen._toggleConnection()
       │
       ▼
ConnectionProvider.connect(server)
       │
       ├──→ SubscriptionParser.parse(server.link)
       │         └──→ Returns ParsedServer (protocol, address, port, uuid, etc.)
       │
       ├──→ SingBoxConfigGenerator.generate(parsedServer)
       │         └──→ Returns sing-box JSON config
       │              {
       │                "outbounds": [{ "type": "vless", ... }],
       │                "route": { "final": "proxy" }
       │              }
       │
       ├──→ VpnService.connect(jsonConfig)
       │         └──→ MethodChannel.invokeMethod('connect', {config, serverName})
       │
       ▼
MainActivity.handleMethod("connect")
       │
       ├──→ VpnService.prepare() check
       │         ├──→ If null: permission granted → launchVpnService()
       │         └──→ If non-null: show system dialog → onActivityResult()
       │
       ▼
MaxSpeedVpnService.startVpn(config, serverName)
       │
       ├──→ Extract sing-box binary from assets to filesDir
       ├──→ Write config JSON to filesDir/config.json
       ├──→ Start foreground notification (channel: "vpn_service", id: 10001)
       │
       ▼
SingBoxProcess.start()
       │
       └──→ ProcessBuilder([binary, "run", "-c", configPath, "-D", filesDir])
                 │
                 ▼
            sing-box subprocess
                 ├──→ Parses config, establishes proxy connection
                 ├──→ Opens TUN interface (172.19.0.1/30, MTU 1500)
                 ├──→ Routes all traffic (0.0.0.0/0) through tunnel
                 └──→ Sends status broadcasts
```

### Status Broadcast Flow (Reverse)

```
sing-box process running
       │
       ▼
MaxSpeedVpnService broadcasts Intent(ACTION_STATUS_UPDATE)
       ├── extra: status = "connected" | "disconnected" | "error"
       ├── extra: serverName = "ServerName"
       ├── extra: traffic = "↓1.2MB ↑340KB"
       └── extra: errorMessage = null | "connection refused"
       │
       ▼
MainActivity.statusReceiver.onReceive()
       │
       ├──→ Packages into HashMap {status, serverName, traffic, uptime, error}
       ├──→ mainHandler.post { channel.invokeMethod("onStatusChanged", state) }
       │
       ▼
VpnService._statusController.add(state)
       │
       ▼
ConnectionProvider listens → updates _state, _stats, _currentServer
       │
       ▼
notifyListeners() → UI rebuilds with new connection state
```

---

## 4. State Management

The app uses **ChangeNotifier** pattern (not Riverpod StateNotifier despite the pubspec dependency). Each domain has a dedicated provider:

### ConnectionProvider

```dart
class ConnectionProvider extends ChangeNotifier {
  VpnConnectionState _state = VpnConnectionState.disconnected;
  Map<String, dynamic> _stats = {};
  String _currentServer = '';
  DateTime? _connectedAt;
  Timer? _durationTimer;

  // Getters
  VpnConnectionState get state => _state;
  bool get isConnected => _state == VpnConnectionState.connected;
  bool get isConnecting => _state.isConnecting;
  String get currentServer => _currentServer;
  Duration get connectedDuration { ... }

  // Actions
  Future<void> connect(ParsedServer server) async { ... }
  Future<void> disconnect() async { ... }
  void updateStats(Map<String, dynamic> stats) { ... }
  void resetStats() { ... }
}
```

**State machine:**
```
disconnected ──connect()──→ connecting ──success──→ connected
     ↑                          │                      │
     │                          │ error                │ disconnect()
     │                          ▼                      ▼
     └───────────────────── error ←──────────── disconnecting
```

### ServersProvider

```dart
class ServersProvider extends ChangeNotifier {
  List<ParsedServer> _servers = [];
  List<ParsedServer> _filteredServers = [];
  String _searchQuery = '';
  String _filterCountry = 'all';
  String _filterProtocol = 'all';
  String _sortBy = 'name';  // name, ping, load

  // Actions
  void addServer(ParsedServer server) { ... }
  void removeServer(String id) { ... }
  void setSelectedServer(String id) { ... }
  void updatePing(String id, int ping) { ... }
  void applyFilters() { ... }
  void sortServers(String criteria) { ... }
}
```

### SettingsProvider

```dart
class SettingsProvider extends ChangeNotifier {
  SettingsState _state = const SettingsState();

  // Theme
  void setThemeMode(AppThemeMode mode) { ... }
  // Language
  void setLanguage(AppLanguage lang) { ... }
  // VPN behavior
  void toggleAutoConnect() { ... }
  void toggleKillSwitch() { ... }
  void setDns({String? primary, String? secondary}) { ... }
  void toggleIpv6() { ... }
  void toggleMux() { ... }
  // Import/Export
  void importFromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> exportToJson() => _state.toJson();
}
```

### Persistence

All settings are stored in **SharedPreferences** with keys prefixed `maxspeed_`:

| Key | Type | Description |
|---|---|---|
| `maxspeed_servers` | JSON string | Serialized server list |
| `maxspeed_subscriptions` | JSON string | Subscription metadata |
| `maxspeed_settings` | JSON string | App settings |
| `maxspeed_selected_server_id` | String | Currently selected server |
| `maxspeed_connection_state` | String | Last known connection state |
| `maxspeed_total_download_bytes` | int | Lifetime download counter |
| `maxspeed_total_upload_bytes` | int | Lifetime upload counter |

---

## 5. VPN Integration Pipeline

The VPN integration spans three layers connected by MethodChannel:

```
┌─────────────────────────────────────────────────────────┐
│  DART SIDE (lib/core/services/vpn_service.dart)         │
│                                                         │
│  class VpnServiceImpl implements VpnService {           │
│    final _channel = MethodChannel('maxspeed.vpn');      │
│    final _statusController = StreamController<Map>();   │
│                                                         │
│    Future<bool> connect(String config) async {          │
│      final result = await _channel.invokeMethod(        │
│        'connect', {'config': config}                    │
│      );                                                 │
│      return result['success'] as bool;                  │
│    }                                                    │
│                                                         │
│    Future<bool> disconnect() async { ... }              │
│    Future<String> getStatus() async { ... }             │
│    Future<List<String>> getLogs() async { ... }         │
│    Stream<Map> get statusStream =>                      │
│      _statusController.stream;                          │
│  }                                                      │
└──────────────────────┬──────────────────────────────────┘
                       │ MethodChannel('maxspeed.vpn')
                       │ BinaryMessenger codec
                       ▼
┌─────────────────────────────────────────────────────────┐
│  KOTLIN SIDE (MainActivity.kt)                          │
│                                                         │
│  class MainActivity : FlutterActivity() {               │
│    private val channel = MethodChannel(                 │
│      flutterEngine.dartExecutor.binaryMessenger,        │
│      "maxspeed.vpn"                                     │
│    );                                                   │
│                                                         │
│    // Method handler                                    │
│    channel.setMethodCallHandler { call, result ->       │
│      when (call.method) {                               │
│        "connect" -> startVpn(config, serverName, result)│
│        "disconnect" -> stopVpn(result)                  │
│        "getStatus" -> result.success(statusMap())       │
│        "getLogs" -> getLogs(result)                     │
│      }                                                  │
│    }                                                    │
│                                                         │
│    // Status receiver                                   │
│    private val statusReceiver = object : BroadcastReceiver() {  │
│      override fun onReceive(context, intent) {          │
│        channel.invokeMethod("onStatusChanged", state)   │
│      }                                                  │
│    }                                                    │
│  }                                                      │
└──────────────────────┬──────────────────────────────────┘
                       │ Intent(ACTION_STATUS_UPDATE)
                       ▼
┌─────────────────────────────────────────────────────────┐
│  VPN SERVICE (MaxSpeedVpnService.kt)                    │
│                                                         │
│  class MaxSpeedVpnService : VpnService() {              │
│    // Foreground service with notification              │
│    // Manages TUN interface                             │
│    // Launches sing-box subprocess                      │
│    // Broadcasts status updates                         │
│                                                         │
│    fun startVpn(config: String, name: String) {         │
│      // 1. Extract sing-box binary from assets          │
│      // 2. Write config to filesDir                     │
│      // 3. Start foreground notification                │
│      // 4. Call establish() for TUN interface           │
│      // 5. Start SingBoxProcess                         │
│      // 6. Broadcast status                             │
│    }                                                    │
│                                                         │
│    fun stopVpn() {                                      │
│      // 1. Stop SingBoxProcess (3s graceful timeout)    │
│      // 2. Close TUN interface                          │
│      // 3. Stop foreground service                      │
│      // 4. Broadcast disconnected status                │
│    }                                                    │
│  }                                                      │
└─────────────────────────────────────────────────────────┘
```

### MethodChannel Methods

| Direction | Method | Arguments | Returns | Description |
|---|---|---|---|---|
| Dart → Kotlin | `connect` | `{config, serverName}` | `{success, status}` | Start VPN with sing-box config |
| Dart → Kotlin | `disconnect` | — | `{success}` | Stop VPN |
| Dart → Kotlin | `getStatus` | — | `{status, serverName, traffic}` | Query current state |
| Dart → Kotlin | `getLogs` | — | `[String]` | Retrieve sing-box logs |
| Kotlin → Dart | `onStatusChanged` | `{status, serverName, traffic, uptime, error}` | — | Status broadcast |

---

## 6. Subscription Parsing

The subscription parser handles multiple input formats and protocol types:

### Input Formats

1. **Single link** — one `vless://`, `vmess://`, `trojan://`, `ss://`, or `naive+https://` URL
2. **Plain text list** — newline-separated links (common export format)
3. **Base64 encoded** — single Base64 string that decodes to a plain text list (standard subscription format)

### Parsing Pipeline

```
Input string
     │
     ├──→ Try Base64 decode ──→ Success? Use decoded content
     │                              └──→ Fail? Use raw input
     │
     ├──→ Split by newlines → trim each line
     │
     ├──→ Filter: skip empty lines, comments (#), non-URL lines
     │
     ├──→ For each line, detect protocol by prefix:
     │         ├── "vless://"     → VLESSParser.parse(line)
     │         ├── "vmess://"     → VMessParser.parse(line)
     │         ├── "trojan://"    → TrojanParser.parse(line)
     │         ├── "ss://"        → ShadowsocksParser.parse(line)
     │         └── "naive+https://" → NaiveParser.parse(line)
     │
     └──→ Return List<ParsedServer>
```

### ParsedServer Model

```dart
class ParsedServer {
  final String id;           // UUID v4 generated
  final String name;         // From fragment (#name) or auto-generated
  final String address;      // Hostname or IP
  final int port;            // Port number
  final String protocol;     // "VLESS", "VMess", "Trojan", "Shadowsocks", "Naive"
  final String? uuid;        // VLESS/VMess UUID
  final String? password;    // Trojan/SS password
  final String? security;    // "reality", "tls", "none"
  final String? sni;         // Server Name Indication
  final String? fingerprint; // uTLS fingerprint (chrome, firefox, safari)
  final String? publicKey;   // XTLS REALITY public key
  final String? shortId;     // XTLS REALITY short ID
  final String? network;     // Transport: "tcp", "ws", "grpc", "h2"
  final String? path;        // WebSocket/HTTP path
  final String? host;        // WebSocket host header
  final Map<String, dynamic>? extra; // Protocol-specific fields
}
```

### sing-box Config Generation

Each `ParsedServer` is converted to a sing-box JSON configuration:

```json
{
  "log": { "level": "warn" },
  "dns": {
    "servers": [
      { "tag": "dns-direct", "address": "local" },
      { "tag": "dns-proxy", "address": "tls://8.8.8.8" }
    ]
  },
  "inbounds": [
    {
      "type": "tun",
      "inet4_address": "172.19.0.1/30",
      "mtu": 1500,
      "auto_route": true,
      "stack": "system"
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "example.com",
      "server_port": 443,
      "uuid": "uuid-here",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "example.com",
        "reality": { "enabled": true, "public_key": "...", "short_id": "..." },
        "utls": { "enabled": true, "fingerprint": "chrome" }
      },
      "transport": { "type": "ws", "path": "/ws", "headers": { "Host": "example.com" } }
    },
    { "type": "direct", "tag": "direct" },
    { "type": "dns", "tag": "dns" }
  ],
  "route": {
    "rules": [{ "protocol": "dns", "outbound": "dns" }],
    "final": "proxy"
  }
}
```

---

## 7. MethodChannel Bridge

The bridge between Flutter (Dart) and Android (Kotlin) uses Flutter's **StandardMethodChannel**:

### Channel Configuration

```dart
// Dart side
const channel = MethodChannel('maxspeed.vpn');
```

```kotlin
// Kotlin side
val channel = MethodChannel(
    flutterEngine.dartExecutor.binaryMessenger,
    "maxspeed.vpn"
)
```

### Communication Pattern

**Dart → Kotlin (Method Calls):**
- Uses `StandardMethodCodec` for serialization
- Arguments are `Map<String, dynamic>` on Dart side → `HashMap<String, Any?>` on Kotlin side
- Results are returned via `MethodChannel.Result` (success/error/notImplemented)

**Kotlin → Dart (Callbacks):**
- Uses `channel.invokeMethod("onStatusChanged", stateMap)` from Kotlin
- Received in Dart via `channel.setMethodCallHandler`
- Forwarded to `StreamController` for reactive consumption

### BroadcastReceiver Integration

```kotlin
// MainActivity registers a BroadcastReceiver for VPN status updates
val filter = IntentFilter(MaxSpeedVpnService.ACTION_STATUS_UPDATE)
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    registerReceiver(statusReceiver, filter, RECEIVER_NOT_EXPORTED)
} else {
    registerReceiver(statusReceiver, filter)
}

// Receiver forwards to Flutter via MethodChannel on main thread
private val statusReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        // Extract extras from intent
        mainHandler.post {
            channel.invokeMethod("onStatusChanged", stateMap)
        }
    }
}
```

---

## 8. sing-box Integration

### Binary Management

sing-box is bundled as an Android asset and extracted at runtime:

```
android/app/src/main/assets/sing-box  →  /data/data/ru.maxspeed.maxspeed_vpn/files/sing-box
```

**MaxSpeedVpnService.kt** handles extraction:
```kotlin
// Extract binary from assets on first run
val binaryFile = File(filesDir, "sing-box")
if (!binaryFile.exists() || !binaryFile.canExecute()) {
    assets.open("sing-box").use { input ->
        binaryFile.outputStream().use { output ->
            input.copyTo(output)
        }
    }
    binaryFile.setExecutable(true)
}
```

### Process Management (SingBoxProcess.kt)

```kotlin
class SingBoxProcess(private val context: Context) {
    private var process: Process? = null
    private val logBuffer = ArrayDeque<String>(500)  // Last 500 lines

    fun start(configPath: String): Boolean {
        val binary = File(context.filesDir, "sing-box")
        if (!binary.exists() || !binary.canExecute()) return false

        val command = listOf(
            binary.absolutePath, "run",
            "-c", configPath,
            "-D", context.filesDir.absolutePath
        )

        process = ProcessBuilder(command)
            .redirectErrorStream(true)
            .start()

        // Capture stdout/stderr in coroutine
        captureOutput(process!!.inputStream)
        return true
    }

    fun stop() {
        process?.destroy()
        // Graceful shutdown with 3s timeout
        thread {
            Thread.sleep(3000)
            process?.destroyForcibly()
        }
    }
}
```

### TUN Configuration

```
Address:    172.19.0.1/30
MTU:        1500
DNS:        8.8.8.8, 1.1.1.1
Route:      0.0.0.0/0 (all traffic)
Stack:      system
```

### sing-box Version

- **Version:** 1.13.0
- **Architecture:** android-arm64-v8a
- **Download:** `https://github.com/SagerNet/sing-box/releases`

---

## 9. Navigation & Routing

The app uses **GoRouter** for declarative navigation:

```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),
      GoRoute(path: '/home',       builder: (_, __) => HomeScreen()),
      GoRoute(path: '/servers',    builder: (_, __) => ServersScreen()),
      GoRoute(path: '/settings',   builder: (_, __) => SettingsScreen()),
      GoRoute(path: '/logs',       builder: (_, __) => LogsScreen()),
    ],
  );
}
```

### Route Constants

All route names are defined in `RouteNames` class (`app_constants.dart`):
- `/` — Splash/redirect
- `/onboarding` — First-run wizard
- `/home` — Main dashboard
- `/servers` — Server list
- `/settings` — Settings
- `/logs` — Connection logs
- `/speed-test` — Speed test tool

### Adaptive Layout

The `HomeScreen` adapts between mobile and desktop layouts:

```dart
Widget build(BuildContext context) {
  final isDesktop = context.screenWidth > 600;
  return Scaffold(
    body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
  );
}
```

- **Mobile (< 600px):** Bottom navigation bar with 4 tabs
- **Desktop (≥ 600px):** Sidebar navigation with vertical divider

---

## 10. Theming System

### Material You Integration

The app supports **Material You** dynamic color on Android 12+:

```dart
// In main.dart
MaterialApp(
  theme: AppTheme.lightTheme,   // Dynamic or fallback
  darkTheme: AppTheme.darkTheme,
  themeMode: settingsProvider.themeModeValue,
)
```

### Color Tokens

Defined in `AppColors` and `app_constants.dart`:

| Token | Light | Dark | Usage |
|---|---|---|---|
| `connected` | Green 600 | Green 400 | Connected state |
| `disconnected` | Red 600 | Red 400 | Disconnected state |
| `connecting` | Amber 600 | Amber 400 | Transition state |
| `download` | Blue 600 | Blue 400 | Download speed |
| `upload` | Purple 600 | Purple 400 | Upload speed |
| `card` | Surface variant | Surface variant | Card backgrounds |

### Theme Modes

- `AppThemeMode.system` — Follow system dark mode setting
- `AppThemeMode.light` — Force light theme
- `AppThemeMode.dark` — Force dark theme (OLED pure black optional)

---

## 11. Error Handling

### Error Code Taxonomy

Defined in `ErrorCodes` class (~100 codes):

| Category | Codes | Description |
|---|---|---|
| Network | `NETWORK_ERROR`, `TIMEOUT_ERROR`, `DNS_RESOLUTION_FAILED` | Connectivity issues |
| VPN | `VPN_NOT_PREPARED`, `VPN_SERVICE_ERROR`, `SING_BOX_ERROR` | VPN lifecycle errors |
| Config | `INVALID_CONFIG`, `CONFIG_GENERATION_ERROR` | Configuration problems |
| Subscription | `INVALID_SUBSCRIPTION`, `SUBSCRIPTION_PARSE_FAILED`, `SUBSCRIPTION_EMPTY` | Subscription errors |
| Auth | `AUTHENTICATION_FAILED`, `PERMISSION_DENIED` | Access/permission errors |
| Storage | `STORAGE_ERROR`, `CACHE_ERROR`, `FILE_ERROR` | Data persistence errors |
| Protocol | `TLS_ERROR`, `CERTIFICATE_ERROR`, `PROTOCOL_ERROR` | Protocol-level errors |

### Error Propagation

```
Platform exception (Kotlin)
     │
     ▼
MethodChannel error result
     │
     ▼
VpnService catches → emits to error stream
     │
     ▼
ConnectionProvider catches → sets state = error
     │
     ▼
UI shows error message with retry option
```

---

## 12. Build Configuration

### SDK Versions

| Component | Version |
|---|---|
| Flutter SDK | ≥ 3.3.0 |
| Dart SDK | ≥ 3.9.2 |
| Android compileSdk | 36 |
| Android targetSdk | 36 |
| Android minSdk | 24 |
| Android NDK | 28.2.13676358 |
| Gradle | 8.7+ |
| Java | 17+ |
| Kotlin | 1.9.x |
| sing-box | 1.13.0 |

### Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.4.9 | State management (declared, ChangeNotifier used) |
| `go_router` | ^14.2.0 | Declarative navigation |
| `shared_preferences` | ^2.2.2 | Local key-value storage |
| `freezed_annotation` | ^2.4.1 | Immutable data classes |
| `json_annotation` | ^4.8.1 | JSON serialization |
| `flutter_svg` | ^2.0.9 | SVG rendering (flags, icons) |
| `uuid` | ^4.2.1 | UUID generation for server IDs |
| `url_launcher` | ^6.2.1 | Open external URLs |
| `path_provider` | ^2.1.1 | Filesystem paths |
| `intl` | ^0.19.0 | Internationalization |
| `shimmer` | ^3.0.0 | Loading placeholder animations |

### ProGuard Rules (Release)

```proguard
# Keep data models for JSON serialization
-keep class ru.maxspeed.maxspeed_vpn.data.models.** { *; }

# Keep sing-box related classes
-keep class ru.maxspeed.maxspeed_vpn.VpnService { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
```

---

*This document is maintained alongside the codebase. For questions or updates, open an issue on [GitHub](https://github.com/JustCheburek/maxspeed-vpn/issues).*
