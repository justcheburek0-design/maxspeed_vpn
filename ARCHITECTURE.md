# MaxSpeedVPN — Архитектура

## Обзор

MaxSpeedVPN — это VPN-клиент для Android, построенный на Flutter с использованием sing-box в качестве движка VPN. Приложение поддерживает протоколы VLESS, Trojan, Shadowsocks и VMess через подписки в формате URI.

## Стек технологий

| Компонент | Технология |
|-----------|-----------|
| UI Framework | Flutter 3.x |
| State Management | Riverpod |
| VPN Engine | sing-box v1.13.0 |
| Native Bridge | Kotlin + MethodChannel |
| Архитектура | Clean Architecture |
| Язык | Dart (UI) + Kotlin (native) |

## Структура проекта

```
lib/
├── core/           # Ядро: константы, тема, утилиты
├── data/           # Слой данных: модели, репозитории, источники
├── domain/         # Бизнес-логика: entities, use cases
├── presentation/   # UI: screens, widgets, providers
├── services/       # Сервисы: VPN, subscription, settings
└── vpn/            # VPN-специфичный код: парсеры, генераторы
```

## Архитектурные слои

### Domain Layer
- **Entities**: ServerEntity, SubscriptionEntity, ConnectionEntity
- **Use Cases**: ConnectVpnUseCase, DisconnectVpnUseCase, RefreshSubscriptionUseCase, PingServerUseCase, ImportSubscriptionUseCase
- **Repositories**: интерфейсы репозиториев

### Data Layer
- **Models**: ServerModel, SubscriptionModel, SettingsModel, ConnectionStatsModel, LogModel
- **Repositories**: реализации репозиториев
- **Data Sources**: LocalDataSource (SharedPreferences)

### Presentation Layer
- **Screens**: Home, Servers, Settings, Onboarding, Logs, Speed Test, Diagnostics, About, Profile, Help
- **Widgets**: ConnectionButton, TrafficStats, ProtocolBadge, ServerCard, SubscriptionCard
- **Providers**: ConnectionProvider, ServersProvider, SettingsProvider

### Core Layer
- **Theme**: AppColors, AppTheme, AppRadii, AppSpacing
- **Constants**: AppConstants, ApiEndpoints, StorageKeys
- **Utils**: NetworkUtils, LogUtils, FileUtils, MathUtils, UrlParser, Validators, Formatters, EncryptionUtils, Debounce, PlatformUtils
- **Extensions**: ContextExtensions, StringExtensions, WidgetExtensions

## VPN Pipeline

```
Subscription URL → Parser → Server List → sing-box Config → MethodChannel → Native VPN Service
```

1. Пользователь добавляет подписку (URL или строка)
2. SubscriptionParser парсит ссылки (VLESS, Trojan, SS, VMess)
3. SingBoxConfigGenerator создаёт JSON-конфиг для sing-box
4. MethodChannel передаёт конфиг в native Kotlin-код
5. MaxSpeedVpnService запускает sing-box с конфигом
6. sing-box создаёт TUN-интерфейс и маршрутизирует трафик

## Протоколы

### VLESS + REALITY
- Наиболее рекомендуемый протокол
- Использует XTLS REALITY для маскировки
- Не требует TLS-сертификата на сервере

### Trojan
- Маскирует VPN-трафик под HTTPS
- Требует валидный TLS-сертификат
- Хорошо работает в странах с DPI

### Shadowsocks
- Лёгкий протокол с низким overhead
- Поддерживает AEAD-шифрование
- Быстрый, но менее скрытный

### VMess
- Протокол от V2Ray
- Поддерживает мультиплексирование
- Устаревает в пользу VLESS

## Безопасность

- Все пароли и ключи хранятся в encrypted SharedPreferences
- sing-box запускается в изолированном процессе
- Нет логирования пользовательского трафика
- Поддержка kill switch через Android VpnService

## Сборка

```bash
flutter build apk --release
```

Требования:
- Flutter 3.x
- Android SDK 36
- NDK 28.2.13676358
- Gradle 8.7+
