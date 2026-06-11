# MaxSpeedVPN — Справочник API

## Основные сервисы

### VpnService

```dart
abstract class VpnService {
  Future<bool> connect(String config);
  Future<bool> disconnect();
  Future<VpnState> getState();
  Future<Map<String, dynamic>> getStats();
  Stream<VpnState> get stateStream;
  Stream<Map<String, dynamic>> get statsStream;
}
```

- `connect(config)` — подключиться с JSON-конфигом sing-box
- `disconnect()` — отключиться
- `getState()` — текущее состояние
- `getStats()` — статистика (bytes in/out, ping)

**Состояния:** disconnected, connecting, connected, disconnecting, error

### SubscriptionService

```dart
class SubscriptionService {
  Future<List<ParsedServer>> parseSubscription(String url);
  Future<void> refreshSubscription(String url);
  Future<void> addSubscription(String url, String name);
  Future<void> removeSubscription(String id);
  List<Subscription> getSubscriptions();
}
```

### SettingsService

```dart
class SettingsService {
  Future<void> setTheme(bool isDark);
  Future<void> setLanguage(String lang);
  Future<void> setAutoConnect(bool enabled);
  Future<void> setKillSwitch(bool enabled);
  Future<void> setProtocol(String protocol);
  Settings getSettings();
}
```

## Use Cases

### ConnectVpnUseCase
```dart
class ConnectVpnUseCase {
  Future<bool> execute(String config);
}
```
Принимает JSON-конфиг. `ArgumentError` если пустой, `FormatException` если невалидный JSON.

### DisconnectVpnUseCase
```dart
class DisconnectVpnUseCase {
  Future<bool> execute();
}
```

### RefreshSubscriptionUseCase
```dart
class RefreshSubscriptionUseCase {
  Future<Map<String, dynamic>> execute(String url);
}
```

### PingServerUseCase
```dart
class PingServerUseCase {
  Future<int> execute(String host, int port);
  Future<int> measureJitter(String host, int port);
}
```
Возвращает пинг в мс или -1 при таймауте.

### ImportSubscriptionUseCase
```dart
class ImportSubscriptionUseCase {
  Future<Map<String, dynamic>> execute({String? url, String? content});
}
```

## Модели данных

### ServerModel
```dart
class ServerModel {
  final String id, name, address, protocol;
  final int port;
  final String? uuid, password, security, sni;
  final String? fingerprint, publicKey, shortId, network;
  final Map<String, dynamic>? extra;
}
```

### SubscriptionModel
```dart
class SubscriptionModel {
  final String id, name, url;
  final DateTime lastUpdate;
  final int serversCount;
  final bool isActive;
}
```

### ConnectionStatsModel
```dart
class ConnectionStatsModel {
  final int bytesReceived, bytesSent, ping, jitter;
  final Duration duration;
  final DateTime connectedAt;
}
```

### SettingsModel
```dart
class SettingsModel {
  final bool isDarkMode, autoConnect, killSwitch;
  final String language, defaultProtocol;
  final bool notifications, analytics;
}
```

## Providers

### ConnectionProvider
```dart
class ConnectionProvider extends StateNotifier<ConnectionState> {
  void setState(VpnState state);
  void updateStats(Map<String, dynamic> stats);
  void setCurrentServer(String server);
  void resetStats();
}
```

### ServersProvider
```dart
class ServersProvider extends StateNotifier<ServersState> {
  void addServer(ServerModel server);
  void removeServer(String id);
  void setSelectedServer(String id);
  void updatePing(String id, int ping);
}
```

### SettingsProvider
```dart
class SettingsProvider extends StateNotifier<SettingsState> {
  void toggleTheme();
  void setLanguage(String lang);
  void setAutoConnect(bool enabled);
  void setKillSwitch(bool enabled);
}
```

## Парсеры протоколов

### VLESS
`vless://uuid@host:port?params#name`

Параметры: security, fp, pbk, sid, sni, alpn, flow

### Trojan
`trojan://password@host:port?params#name`

Параметры: sni, alpn, allowInsecure

### Shadowsocks
`ss://base64(method:password)@host:port#name`

Методы: aes-256-gcm, aes-128-gcm, chacha20-ietf-poly1305, xchacha20-ietf-poly1305

### VMess
`vmess://base64(json-config)`

JSON: v, ps, add, port, id, aid, scy, net, type, host, path, tls, sni
