# Release Notes

> **v1.4.1+13** — Полная кроссплатформенность и CI/CD

## 🚀 Новые платформы

- **Windows** — нативная сборка в CI/CD (`windows-latest`), zip-архив с релизом
- **macOS** — нативная сборка в CI/CD (`macos-latest`), dmg-образ
- **iOS** — skeleton-сборка через platform channel (`maxspeed/vpn`), без подписи (для тестирования через AltStore/sideload)
- **Web** — полноценная сборка с UI для экспорта конфигов и ссылками на скачивание нативных клиентов
- **Web Extension** — Chrome/Firefox/Яндекс расширение (manifest v3), парсинг подписок (VLESS/VMess/Trojan/SS/Hysteria2/TUIC), копирование конфигов

## ⚡ Улучшения CI/CD

- Все 6 платформ собираются параллельно (Android, Linux, Windows, macOS, iOS, Web)
- Release создаётся автоматически после успешной сборки всех платформ
- Release notes берутся из `RELEASE.md` — человекочитаемые, на русском языке
- После публикации `RELEASE.md` автоматически очищается и коммитится обратно

## 🔧 Исправления

- Исправлено имя пакета `libsecret` для Ubuntu 24.04 (`libsecret-1-0` вместо `libsecret-1-0-0`)

## 📋 Что внутри каждого релиза

| Платформа | Формат | Описание |
|-----------|--------|----------|
| Android | `.apk` | flutter\_singbox\_vpn, автообновление |
| Linux | `.tar.gz` | Desktop-клиент с VPN через sing-box subprocess |
| Windows | `.zip` | Desktop-клиент с VPN через sing-box subprocess |
| macOS | `.dmg` | Desktop-клиент с VPN через sing-box subprocess |
| iOS | `.zip` | Skeleton (без подписи) через NetworkExtension channel |
| Web | `.tar.gz` | UI + экспорт конфигов + ссылки на скачивание |
