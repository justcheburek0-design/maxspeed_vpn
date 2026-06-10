# MaxSpeedVPN — Contributing Guide

## Как внести вклад

Мы приветствуем любой вклад в проект! Вот как вы можете помочь:

### Сообщить об ошибке

1. Проверьте, что ошибка ещё не зарегистрирована в Issues
2. Создайте новый Issue с описанием ошибки
3. Укажите шаги для воспроизведения
4. Приложите логи и скриншоты

### Предложить улучшение

1. Создайте Issue с описанием предложения
2. Обсудите с командой
3. Реализуйте после одобрения

### Pull Request

1. Форкните репозиторий
2. Создайте ветку: `git checkout -b feature/my-feature`
3. Внесите изменения
4. Напишите тесты
5. Убедитесь что все тесты проходят: `flutter test`
6. Создайте Pull Request

## Стиль кода

### Dart

- Используйте `dart format` для форматирования
- Следуйте Effective Dart guidelines
- Именуйте классы в PascalCase
- Именуйте переменные и методы в camelCase
- Именуйте константы в lowerCamelCase
- Используйте `final` где возможно
- Добавляйте документацию к public API

### Kotlin

- Используйте Kotlin coding conventions
- Именуйте классы в PascalCase
- Именуйте переменные и методы в camelCase
- Используйте `val` где возможно
- Добавляйте KDoc к public API

## Структура коммитов

```
type(scope): description

[optional body]

[optional footer]
```

**Типы:**
- `feat` — новая функциональность
- `fix` — исправление ошибки
- `docs` — документация
- `style` — форматирование
- `refactor` — рефакторинг
- `test` — тесты
- `chore` — обслуживание

**Примеры:**
```
feat(vpn): add VLESS REALITY support
fix(ui): connection button animation glitch
docs(readme): update installation guide
```

## Тестирование

- Все новые функции должны иметь тесты
- Используйте `flutter test` для запуска тестов
- Используйте `flutter test --coverage` для покрытия
- Минимальное покрытие: 80%

## Code Review

- Все PR проходят code review
- Минимум 1 апрув для мержа
- CI должен быть зелёным

## Лицензия

Внося вклад, вы соглашаетесь с лицензией GPL-3.0.
