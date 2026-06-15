# Naive Protocol Analysis — Karing vs MaxSpeedVPN
_Updated: 2026-06-15_

## Проблема
VPN не подключается ни на одном устройстве. Логи показывают:
```
sing-box: нет логов (sing-box не запустил ядро?)
VPN не перешёл в connected, состояние: VpnConnectionState.disconnected
```

## Корневая причина
Сервер `fi2.maxspeedvpn.site:443` работает на **Caddy + NaiveProxy** (не sing-box).
Приложение использует **sing-box ядро** через плагин `flutter_singbox_vpn`.

Sing-box поддерживает naive outbound, **НО** только при сборке с тегом `with_naive_outbound`.
Официальный `libbox:1.12.12` от `singbox-android` на JitPack **НЕ включает** этот тег.

## Что уже есть в коде maxspeed_vpn (ВСЁ ГОТОВО!)
1. ✅ `VpnProtocol.naive` — есть в enum
2. ✅ `_parseNaive()` — парсит `naive+https://user:pass@host:port#name`
3. ✅ `_buildNaiveOutbound()` — генерит правильный naive outbound с username/password/tls
4. ✅ `SubscriptionParser` — распознаёт naive ссылки
5. ✅ `SingboxConfigGenerator` — генерит JSON конфиг для naive

## Что НЕ работает
- `flutter_singbox_vpn` использует `com.github.singbox-android:libbox:1.12.12`
- Этот libbox собран **БЕЗ** `with_naive_outbound`
- Sing-box просто игнорирует/не может обработать naive outbound → ядро не стартует

## Решение: Вариант A — Миграция на flutter_singbox_client

**Плюсы:**
- Поддержка naive из коробки (sing-box 1.14.0-alpha.20)
- Активно развивается
- Чистый API

**Минусы:**
- Нужно переписать `vpn_service_android.dart` (другой API)
- Другие зависимости (path_provider и т.д.)

### Сравнение API:

| flutter_singbox_vpn | flutter_singbox_client |
|---|---|
| `FlutterSingbox()` | `SingboxClient()` |
| `saveConfig(json)` | `connect(SessionOptions(config: json))` |
| `startVPN()` | (встроено в connect) |
| `stopVPN()` | `disconnect()` |
| `getVPNStatus()` | `getServiceState()` |
| `onStatusChanged` | `serviceStateStream` |
| `onTrafficUpdate` | `trafficStatsStream` |
| `onLogMessage` | `coreLogStream` |

## Решение: Вариант B — Собрать libbox с naive

**Плюсы:**
- Минимум изменений в коде
- Тот же API

**Минусы:**
- Нужно собрать sing-box с `with_naive_outbound` + `with_cronet` для Android
- Сложная сборка (CGO, Android NDK, cronet-go)
- Нет VDS для сборки (слабый сервер)

## Рекомендация
**Вариант A** — миграция на `flutter_singbox_client`. Это чище и надёжнее.
Сборка libbox с naive на VDS невозможна (нет ресурсов).

## План миграции
1. Заменить `flutter_singbox_vpn` на `flutter_singbox_client` в pubspec.yaml
2. Переписать `vpn_service_android.dart` под новый API
3. Протестировать подключение к naive серверу
4. Запустить CI

## Ссылки
- https://pub.dev/packages/flutter_singbox_client
- https://github.com/amir-zr/flutter_singbox_client
- https://sing-box.sagernet.org/installation/build-from-source/ (build tags)
- https://sing-box.sagernet.org/configuration/outbound/naive/
