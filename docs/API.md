# MaxSpeedVPN — API Documentation

## Core Services

### VpnService

Основной сервис для управления VPN-подключением.

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

**Методы:**
- `connect(config)` — подключиться к VPN с JSON-конфигом sing-box
- `disconnect()` — отключиться от VPN
- `getState()` — получить текущее состояние
- `getStats()` — получить статистику (bytes in/out, ping)
- `stateStream` — поток изменений состояния
- `statsStream` — поток обновлений статистики

**Состояния:**
- `disconnected` — отключено
- `connecting` — подключение
- `connected` — подключено
- `disconnecting` — отключение
- `error` — ошибка

### SubscriptionService

Сервис для управления подписками.

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

Сервис для управления настройками.

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

## Domain Use Cases

### ConnectVpnUseCase

```dart
class ConnectVpnUseCase {
  Future<bool> execute(String config);
}
```

Выполняет подключение к VPN. Принимает JSON-конфиг sing-box.
Бросает `ArgumentError` если конфиг пустой.
Бросает `FormatException` если конфиг невалидный JSON.

### DisconnectVpnUseCase

```dart
class DisconnectVpnUseCase {
  Future<bool> execute();
}
```

Выполняет отключение от VPN.

### RefreshSubscriptionUseCase

```dart
class RefreshSubscriptionUseCase {
  Future<Map<String, dynamic>> execute(String url);
}
```

Обновляет подписку по URL. Возвращает карту с ключом `servers`.

### PingServerUseCase

```dart
class PingServerUseCase {
  Future<int> execute(String host, int port);
  Future<int> measureJitter(String host, int port);
}
```

Пингует сервер. Возвращает пинг в мс или -1 при таймауте.

### ImportSubscriptionUseCase

```dart
class ImportSubscriptionUseCase {
  Future<Map<String, dynamic>> execute({String? url, String? content});
}
```

Импортирует подписку из URL или строки.

## Data Models

### ServerModel

```dart
class ServerModel {
  final String id;
  final String name;
  final String address;
  final int port;
  final String protocol;
  final String? uuid;
  final String? password;
  final String? security;
  final String? sni;
  final String? fingerprint;
  final String? publicKey;
  final String? shortId;
  final String? network;
  final Map<String, dynamic>? extra;
}
```

### SubscriptionModel

```dart
class SubscriptionModel {
  final String id;
  final String name;
  final String url;
  final DateTime lastUpdate;
  final int serversCount;
  final bool isActive;
}
```

### ConnectionStatsModel

```dart
class ConnectionStatsModel {
  final int bytesReceived;
  final int bytesSent;
  final int ping;
  final int jitter;
  final Duration duration;
  final DateTime connectedAt;
}
```

### SettingsModel

```dart
class SettingsModel {
  final bool isDarkMode;
  final String language;
  final bool autoConnect;
  final bool killSwitch;
  final String defaultProtocol;
  final bool notifications;
  final bool analytics;
}
```

## Presentation Providers

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

## VPN Protocol Parsers

### VLESS Parser

Парсит ссылки формата:
`vless://uuid@host:port?params#name`

Поддерживаемые параметры:
- `security` — tls, reality, none
- `fp` — fingerprint (chrome, firefox, safari)
- `pbk` — public key для REALITY
- `sid` — short ID для REALITY
- `sni` — Server Name Indication
- `alpn` — ALPN protocol
- `flow` — flow control

### Trojan Parser

Парсит ссылки формата:
`trojan://password@host:port?params#name`

Поддерживаемые параметры:
- `sni` — Server Name Indication
- `alpn` — ALPN protocol
- `allowInsecure` — разрешить небезопасные соединения

### Shadowsocks Parser

Парсит ссылки формата:
`ss://base64(method:password)@host:port#name`

Поддерживаемые методы шифрования:
- aes-256-gcm
- aes-128-gcm
- chacha20-ietf-poly1305
- xchacha20-ietf-poly1305

### VMess Parser

Парсит ссылки формата:
`vmess://base64(json-config)`

JSON-конфиг содержит:
- `v` — версия
- `ps` — название
- `add` — адрес
- `port` — порт
- `id` — UUID
- `aid` — alterId
- `scy` — метод шифрования
- `net` — сеть (ws, tcp, grpc)
- `type` — тип маскировки
- `host` — хост для WebSocket
- `path` — путь для WebSocket
- `tls` — TLS включён
- `sni` — SNI
