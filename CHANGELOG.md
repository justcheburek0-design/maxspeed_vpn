# MaxSpeedVPN — Changelog

## [1.0.0] - 2026-06-09

### Added
- Поддержка протоколов VLESS, Trojan, Shadowsocks, VMess
- Парсинг подписок из URL и строк
- Генерация sing-box конфигов
- Подключение через sing-box engine
- Тёмная тема с акцентным цветом
- Экраны: Home, Servers, Settings, Onboarding, Logs, Speed Test, Diagnostics, About, Profile, Help
- Виджеты: ConnectionButton, TrafficStats, ProtocolBadge, ServerCard, SubscriptionCard
- Тест скорости с анимированным датчиком
- Пинг серверов
- Автоподключение
- Kill switch
- Уведомления
- Экспорт логов
- Локализация (RU, EN)
- Документация

### Security
- Шифрование паролей в SharedPreferences
- Изолированный процесс sing-box
- Нет логирования пользовательского трафика

### Technical
- Clean Architecture
- Riverpod state management
- MethodChannel для native bridge
- Kotlin VpnService
- sing-box v1.13.0
- Flutter 3.x
- Android SDK 36
- NDK 28.2.13676358
