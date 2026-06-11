# Руководство по разработке

## Настройка

- Flutter 3.24+
- Android Studio / VS Code
- Android SDK 21+
- Git

```bash
git clone https://github.com/JustCheburek/MaxSpeedVPN.git
cd MaxSpeedVPN
flutter pub get
```

## Структура проекта

```
lib/
├── core/                    # Ядро: сервисы, утилиты, константы
│   ├── services/            # VPN, парсер, sing-box
│   ├── extensions/          # Расширения Dart
│   ├── utils/               # Утилиты
│   └── constants/           # Константы
├── data/                    # Слой данных
│   ├── models/              # Модели
│   ├── repositories/        # Репозитории
│   └── datasources/         # Источники данных
├── domain/                  # Бизнес-логика
│   ├── entities/            # Сущности
│   ├── repositories/        # Интерфейсы репозиториев
│   └── usecases/            # Use cases
└── presentation/            # UI
    ├── screens/             # Экраны
    ├── widgets/             # Виджеты
    ├── providers/           # Управление состоянием
    └── theme/               # Тема
```

## Архитектура

Трёхслойная Clean Architecture:
1. **Domain** — бизнес-логика
2. **Data** — доступ к данным
3. **Presentation** — UI

## Управление состоянием

ChangeNotifier:
```dart
class ConnectionProvider extends ChangeNotifier {
  VpnState _state = VpnState.disconnected;
  VpnState get state => _state;
  void updateState(VpnState newState) {
    _state = newState;
    notifyListeners();
  }
}
```

## VPN Flow

1. Пользователь нажимает «Подключиться»
2. Приложение запрашивает разрешение VPN
3. Парсинг подписки
4. Генерация sing-box конфига
5. VpnService запускается с конфигом
6. Создаётся TUN-интерфейс
7. Трафик маршрутизируется через прокси

## Тестирование

```bash
flutter test                                    # Все тесты
flutter test test/services/parser_test.dart     # Конкретный файл
flutter test --coverage                         # С покрытием
```

## Сборка

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
flutter build apk --release --target-platform android-arm64
```

## Стиль кода

- Effective Dart guidelines
- `flutter analyze` перед коммитом
- Тесты для новых фич
- Документация публичного API

## Отладка

```bash
adb logcat -s MaxSpeedVPN          # Android логи
flutter run --debug                # DevTools: http://localhost:9100
```

## Частые проблемы

- **VPN разрешение не дано**: нужно `android.permission.BIND_VPN_SERVICE`
- **sing-box не найден**: бинарник должен быть в `android/app/src/main/assets/sing-box`
- **Сборка падает**: `flutter clean && flutter pub get`, проверьте версию Android SDK
