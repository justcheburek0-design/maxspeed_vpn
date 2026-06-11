# MaxSpeedVPN — Архитектура

> **Стек:** Flutter 3.x / Dart 3.9+ · Kotlin · sing-box 1.13.0 · Android SDK 36

## Структура проекта

```
lib/
├── main.dart                    # Точка входа
├── core/                        # Ядро
│   ├── constants/               # Константы, ключи, enum'ы
│   ├── extensions/              # Расширения Dart
│   ├── router/                  # GoRouter (5 маршрутов)
│   ├── services/                # VpnService, SingBoxManager, SubscriptionParser
│   ├── theme/                   # Цвета, типографика, ThemeData
│   └── utils/                   # Парсеры, валидаторы, debounce
├── data/                        # Слой данных
│   ├── models/                  # ServerModel, SubscriptionModel, SettingsModel
│   ├── repositories/            # Реализации репозиториев
│   └── datasources/             # SharedPreferences, HTTP-клиент
├── presentation/                # UI
│   ├── providers/               # ConnectionProvider, ServersProvider, SettingsProvider
│   ├── screens/                 # Home, Servers, Settings, Logs, Speed, Onboarding
│   └── widgets/                 # ConnectionButton, ServerCard, TrafficChart
├── services/                    # Subscription, Settings, Log, Analytics, Update
└── vpn/                         # SingBoxConfigGenerator, NaiveParser
```

## Трёхслойная архитектура

```
┌─────────────────────────────────┐
│       PRESENTATION              │
│   Screens → Widgets → Providers │
│   (ChangeNotifier)              │
├─────────────────────────────────┤
│          CORE                   │
│   Services → Parsers → Router   │
│   Constants → Theme             │
├─────────────────────────────────┤
│        PLATFORM                 │
│   VpnService (Kotlin)           │
│   → MethodChannel → sing-box    │
└─────────────────────────────────┘
```

**Presentation** — UI, провайдеры с ChangeNotifier, нет прямых вызовов платформы.

**Core** — VpnService (абстракция над MethodChannel), SubscriptionParser (VLESS/VMess/Trojan/SS/Naive), SingBoxConfigGenerator (JSON для sing-box), роутер, константы, тема.

**Platform** — MainActivity (Flutter engine + MethodChannel), MaxSpeedVpnService (Android VpnService + TUN + sing-box), SingBoxProcess (внешний процесс).

## Поток подключения

```
Пользователь → «Подключиться»
  → ConnectionProvider.connect(server)
    → SubscriptionParser.parse(link) → ParsedServer
    → SingBoxConfigGenerator.generate(parsed) → JSON config
    → VpnService.connect(jsonConfig)
      → MethodChannel('connect', {config, serverName})
        → MainActivity.handleMethod("connect")
          → VpnService.prepare() → launchVpnService()
            → MaxSpeedVpnService.startVpn()
              → Извлечь sing-box из assets
              → Записать config.json
              → Foreground notification
              → SingBoxProcess.start()
                → sing-box: TUN 172.19.0.1/30, MTU 1500
                → Маршрутизация 0.0.0.0/0 через туннель
                → Broadcast статуса
```

## Поток статуса (обратный)

```
sing-box → Broadcast(ACTION_STATUS_UPDATE)
  → MainActivity.statusReceiver
    → MethodChannel.invokeMethod("onStatusChanged", state)
      → VpnService._statusController
        → ConnectionProvider → notifyListeners()
          → UI обновляется
```

## Управление состоянием

### ConnectionProvider
```dart
class ConnectionProvider extends ChangeNotifier {
  VpnConnectionState _state = VpnConnectionState.disconnected;
  Map<String, dynamic> _stats = {};
  String _currentServer = '';
  // connect(server), disconnect(), updateStats(), resetStats()
}
```

**State machine:** disconnected → connecting → connected → disconnecting → disconnected

### ServersProvider
```dart
class ServersProvider extends ChangeNotifier {
  List<ParsedServer> _servers, _filteredServers;
  String _searchQuery, _filterCountry, _filterProtocol, _sortBy;
  // addServer(), removeServer(), applyFilters(), sortServers()
}
```

### SettingsProvider
```dart
class SettingsProvider extends ChangeNotifier {
  // setThemeMode(), setLanguage(), toggleAutoConnect(), toggleKillSwitch()
  // setDns(), toggleIpv6(), toggleMux()
  // importFromJson(), exportToJson()
}
```

### Персистенция

SharedPreferences с префиксом `maxspeed_`:
- `maxspeed_servers` — список серверов (JSON)
- `maxspeed_subscriptions` — метаданные подписок
- `maxspeed_settings` — настройки приложения
- `maxspeed_selected_server_id` — выбранный сервер
- `maxspeed_connection_state` — последнее состояние

## VPN Pipeline (MethodChannel)

| Направление | Метод | Описание |
|-------------|-------|----------|
| Dart → Kotlin | `connect` | Запуск VPN с конфигом |
| Dart → Kotlin | `disconnect` | Остановка VPN |
| Dart → Kotlin | `getStatus` | Запрос состояния |
| Dart → Kotlin | `getLogs` | Получение логов |
| Kotlin → Dart | `onStatusChanged` | Broadcast статуса |

## Парсинг подписок

**Форматы входа:**
1. Одна ссылка: `vless://`, `vmess://`, `trojan://`, `ss://`, `naive+https://`
2. Список (plain text, разделённый строками)
3. Base64-encoded строка (стандартный формат подписок)

**Pipeline:**
```
Input → Base64 decode? → Split by newlines → Filter empty/comments
  → Detect protocol by prefix → Parse → List<ParsedServer>
```

## Навигация

GoRouter с маршрутами: `/`, `/servers`, `/settings`, `/logs`, `/speed`, `/onboarding`.

## Тёмная тема

Material You с акцентным цветом `#38BDF8`. Поддержка светлой и тёмной темы через `AppThemeMode`.

## Сборка

```bash
flutter build apk --release
```

Требования: Flutter 3.x, Android SDK 36, NDK 28.2.13676358, Gradle 8.7+.
