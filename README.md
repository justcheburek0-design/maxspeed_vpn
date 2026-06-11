# MaxSpeedVPN

[![Лицензия: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Платформа](https://img.shields.io/badge/platform-android-green.svg)](https://android.com)
[![sing-box](https://img.shields.io/badge/sing--box-1.13.0-1E90FF.svg)](https://sing-box.sagernet.org/)

**MaxSpeedVPN** — быстрый, современный VPN-клиент с открытым исходным кодом для Android, построенный на [Flutter](https://flutter.dev) и [sing-box](https://sing-box.sagernet.org/).

Поддерживает протоколы VLESS (+ XTLS REALITY), VMess, Trojan, Shadowsocks, NaiveProxy и WireGuard с интуитивным интерфейсом Material You.

| | Ссылки |
|---|---|
| **Пакет** | `ru.maxspeed.maxspeed_vpn` |
| **Исходный код** | [github.com/maxspeed-vpn/maxspeed_vpn](https://github.com/maxspeed-vpn/maxspeed_vpn) |
| **Telegram** | [t.me/maxspeed_vpn](https://t.me/maxspeed_vpn) |
| **Поддержка** | [email removed] |

---

## Возможности

### Основной VPN
- **Подключение в один тап** — автоматический выбор самого быстрого сервера или ручной выбор
- **Мультипротокольность** — VLESS (+ XTLS REALITY), VMess, Trojan, Shadowsocks, NaiveProxy, WireGuard
- **Управление подписками** — импорт серверов через URL или QR-код (форматы Base64 и plain text)
- **Мониторинг трафика в реальном времени** — статистика загрузки/отдачи с таймером длительности
- **Измерение пинга** — автоматическая проверка здоровья серверов с отображением задержки
- **Автоподключение** — настраиваемые повторные попытки с экспоненциальной задержкой
- **Kill switch** — блокировка всего трафика при неожиданном отключении
- **Маршрутизация по приложениям** — включение или исключение приложений из VPN-туннеля

### Безопасность и приватность
- **XTLS REALITY** — современный метод обхода цензуры с минимальным отпечатком
- **TLS 1.3** — современное шифрование для всех протоколов на основе TLS
- **uTLS fingerprinting** — имитация TLS-отпечатков Chrome / Firefox / Safari
- **DNS-over-HTTPS** — приватное DNS-разрешение для предотвращения утечек
- **Без локального логирования трафика** — метаданные подключений по умолчанию не сохраняются
- **Открытый исходный код** — полностью аудируемая кодовая база под лицензией GPL-3.0

### Пользовательский опыт
- **Дизайн Material You** — динамические цвета, плавные анимации, тактильная обратная связь
- **Онбординг** — мастер первого запуска с запросом разрешений
- **Поиск и фильтрация серверов** — по стране, протоколу или названию
- **Встроенный тест скорости** — измерение пропускной способности с анимированным датчиком
- **Диагностика подключения** — подробные логи и отчёты об ошибках
- **Локализация** — русский и английский языки
- **Адаптивные макеты** — нижняя навигация на телефонах, боковая панель на планшетах/десктопе

---

## Архитектура

MaxSpeedVPN использует **слоистую архитектуру** с чётким разделением ответственности.

```
┌─────────────────────────────────────────────────────────────────┐
│                    СЛОЙ ПРЕДСТАВЛЕНИЯ                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ Экраны   │ │ Виджеты  │ │ Провайдеры   │ │    Тема      │  │
│  │ (Страниц)│ │(Переисп.)│ │(ChangeNotif.)│ │ Material You │  │
│  └────┬─────┘ └────┬─────┘ └──────┬───────┘ └──────────────┘  │
├───────┼─────────────┼──────────────┼────────────────────────────┤
│  СЛОЯ ЯДРА          │              │                            │
│  ┌────┴─────────────┴──────────────┴──┐ ┌──────────────────┐  │
│  │            Сервисы                 │ │    Константы     │  │
│  │  VPN · Парсер · Логи · Настройки  │ │  Перечисления    │  │
│  ├────────────────────────────────────┤ ├──────────────────┤  │
│  │         Парсеры протоколов         │ │   Роутер         │  │
│  │  VLESS · VMess · Trojan · SS      │ │   (GoRouter)     │  │
│  ├────────────────────────────────────┤ └──────────────────┘  │
│  │   Генератор конфигурации sing-box  │                        │
│  └────────────────────────────────────┘                        │
├─────────────────────────────────────────────────────────────────┤
│              СЛОЙ ПЛАТФОРМЫ (Kotlin)                            │
│  ┌──────────────────┐ ┌────────────────┐ ┌──────────────────┐  │
│  │  MaxSpeedVpnServ.│ │  MethodChannel │ │  SingBoxProcess  │  │
│  │  VpnService+TUN  │ │  Flutter ↔     │ │  Менеджер        │  │
│  │  Уведомление     │ │  Android       │ │  процессов       │  │
│  └──────────────────┘ └────────────────┘ └──────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Поток данных подключения

```
Пользователь нажимает "Подключиться"
       │
       ▼
ConnectionProvider.connect(server)
       │
       ├──→ SubscriptionParser.parse(server.link)
       │         └──→ ParsedServer(адрес, порт, uuid, ...)
       │
       ├──→ SingBoxConfigGenerator.generate(parsedServer)
       │         └──→ JSON-конфигурация sing-box
       │
       ├──→ MethodChannel.invokeMethod('connect', {config})
       │
       ▼
MainActivity → MaxSpeedVpnService (foreground)
       │
       ├──→ Извлечение бинарника sing-box из assets
       ├──→ Запись конфигурации в filesDir
       ├──→ SingBoxProcess.start() → подпроцесс sing-box
       ├──→ VpnService.Builder.establish() → TUN-интерфейс
       └──→ startForeground(уведомление)
       │
       ▼
sing-box устанавливает прокси → TUN маршрутизирует весь трафик
       │
       ▼
BroadcastReceiver → MethodChannel "onStatusChanged"
       │
       ▼
ConnectionProvider обновляет состояние → UI реактивно перестраивается
```

### Управление состоянием

| Провайдер | Домен | Хранение |
|---|---|---|
| `ConnectionProvider` | Состояние VPN, статистика трафика, длительность | В памяти + SharedPreferences |
| `ServersProvider` | Список серверов, фильтры, сортировка, поиск | SharedPreferences (JSON) |
| `SettingsProvider` | Тема, язык, автоподключение, DNS, kill switch | SharedPreferences (JSON) |

Все провайдеры используют паттерн **ChangeNotifier** и доступны через `Provider.of<T>(context)` или `context.watch<T>()`.

---

## Поддержка протоколов

| Протокол | Статус | Транспорт | Безопасность | Примечания |
|---|---|---|---|---|
| **VLESS + XTLS REALITY** | ✅ | TCP, WebSocket, gRPC | REALITY, TLS | Рекомендуется — лучшая устойчивость к цензуре |
| **VLESS + TLS** | ✅ | TCP, WebSocket, gRPC | TLS 1.3 | Стандартный безопасный режим |
| **VMess** | ✅ | TCP, WebSocket, gRPC, H2 | TLS, auto | alterId=0, авто-безопасность |
| **Trojan** | ✅ | TCP, WebSocket | TLS 1.3 | Аутентификация по паролю |
| **Shadowsocks** | ✅ | TCP, UDP | AEAD-шифры | AES-256-GCM, ChaCha20-Poly1305 |
| **NaiveProxy** | ✅ | HTTPS | TLS 1.3 | `naive+https://user:pass@host` |
| **WireGuard** | 🔜 | UDP | Noise protocol | В разработке |
| **Hysteria2** | 🔜 | QUIC | TLS 1.3 | В разработке |
| **TUIC** | 🔜 | QUIC | TLS 1.3 | В разработке |

---

## Руководство по сборке

### Требования

| Требование | Версия |
|---|---|
| Flutter SDK | ≥ 3.3.0 (рекомендуется последняя стабильная) |
| Dart SDK | ≥ 3.9.2 |
| Android SDK | API 21+ (целевой: 36) |
| Android NDK | 28.2.13676358 |
| Gradle | 8.7+ |
| Java | 17+ |

### Настройка окружения

```bash
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH=$PATH:/opt/flutter/bin:$ANDROID_HOME/platform-tools

flutter doctor -v
```

### Клонирование и установка

```bash
git clone https://github.com/maxspeed-vpn/maxspeed_vpn.git
cd maxspeed_vpn
flutter pub get
flutter analyze
```

### Бинарник sing-box

Бинарный файл sing-box должен быть включён как Android-ассет:

```bash
# Скачать последний релиз (настроить версию/архитектуру)
wget https://github.com/SagerNet/sing-box/releases/download/v1.13.0/sing-box-1.13.0-android-arm64-v8a.tar.gz
tar xzf sing-box-1.13.0-android-arm64-v8a.tar.gz

mkdir -p android/app/src/main/assets
cp sing-box-1.13.0-android-arm64-v8a/sing-box android/app/src/main/assets/sing-box
chmod +x android/app/src/main/assets/sing-box
```

### Команды сборки

```bash
# Запуск в режиме отладки на устройстве
flutter run --debug

# Release APK (все архитектуры)
flutter build apk --release

# Release APK (только arm64)
flutter build apk --release --target-platform android-arm64

# App Bundle (Play Store)
flutter build appbundle --release

# Разделение по ABI
flutter build apk --release --split-per-abi
```

### Тестирование

```bash
flutter test
flutter test test/services/subscription_parser_test.dart
flutter test --coverage
```

---

## Структура проекта

```
maxspeed_vpn/
├── android/                          # Нативный код Android (Kotlin)
│   └── app/src/main/
│       ├── assets/sing-box           # Встроенный бинарник
│       ├── kotlin/.../maxspeed_vpn/
│       │   ├── MainActivity.kt       # Мост MethodChannel
│       │   ├── MaxSpeedVpnService.kt  # VpnService + TUN
│       │   └── SingBoxProcess.kt     # Жизненный цикл процесса
│       └── AndroidManifest.xml
├── lib/                              # Исходный код Dart/Flutter
│   ├── core/                         # Константы, роутер, тема, утилиты
│   ├── data/                         # Модели, репозитории, источники данных
│   ├── presentation/                 # Экраны, виджеты, провайдеры
│   ├── services/                     # Бизнес-сервисы
│   └── vpn/                          # Генератор конфигурации, парсеры
├── test/                             # Модульные и виджет-тесты
└── docs/                             # Документация
```

---

## Участие в разработке

Мы приветствуем сообщения об ошибках, предложения по улучшению, доработки кода и документации.

1. Форкните репозиторий
2. Создайте ветку: `git checkout -b feat/my-feature`
3. Запустите `flutter analyze && flutter test` перед коммитом
4. Отправьте Pull Request с понятным описанием

Подробности в [CONTRIBUTING.md](CONTRIBUTING.md).

## Лицензия

Этот проект лицензирован под **GNU General Public License v3.0 (GPL-3.0)**.

MaxSpeedVPN — Copyright (C) 2026 MaxSpeedVPN Contributors.  
Это свободное программное обеспечение под лицензией GPL-3.0. Подробности в [LICENSE](https://github.com/maxspeed-vpn/maxspeed_vpn/blob/main/LICENSE).
