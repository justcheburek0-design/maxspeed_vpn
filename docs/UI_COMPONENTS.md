# MaxSpeedVPN — UI Components

## Обзор

Все UI-компоненты MaxSpeedVPN следуют единому дизайн-системе с тёмной темой, акцентным цветом `#38BDF8` (sky blue), и скруглениями от 6px до 16px.

## Цветовая палитра

| Токен | Значение | Использование |
|-------|----------|---------------|
| primary | #38BDF8 | Акцентные элементы, кнопки |
| bgPrimary | #0B0D14 | Основной фон |
| bgSecondary | #11131A | Фон карточек |
| bgTertiary | #1A1D25 | Фон вложенных элементов |
| textPrimary | #FFFFFF | Основной текст |
| textSecondary | #9CA3AF | Вторичный текст |
| success | #10B981 | Успех, подключено |
| warning | #F59E0B | Предупреждение |
| error | #EF4444 | Ошибка |
| info | #60A5FA | Информация |

## Типографика

| Стиль | Размер | Вес | Использование |
|-------|--------|-----|---------------|
| displayLarge | 57px | Bold | Главный экран |
| displayMedium | 45px | Bold | Заголовки секций |
| headlineLarge | 32px | Bold | Заголовки экранов |
| headlineMedium | 28px | Bold | Подзаголовки |
| titleLarge | 22px | SemiBold | Заголовки карточек |
| titleMedium | 16px | Medium | Названия элементов |
| titleSmall | 14px | Medium | Лейблы |
| bodyLarge | 16px | Regular | Основной текст |
| bodyMedium | 14px | Regular | Вторичный текст |
| bodySmall | 12px | Regular | Мелкий текст |
| labelLarge | 14px | Medium | Кнопки |
| labelMedium | 12px | Medium | Бейджи |
| labelSmall | 11px | Medium | Метки |

## Компоненты

### ConnectionButton

Большая круглая кнопка подключения/отключения.

```dart
ConnectionButton(
  isConnected: true,
  onPressed: () => toggleConnection(),
  size: 120,
)
```

**Состояния:**
- Отключено: серая рамка, без свечения
- Подключение: анимация пульсации
- Подключено: зелёная рамка, свечение
- Ошибка: красная рамка

### TrafficStatsWidget

Отображение статистики трафика.

```dart
TrafficStatsWidget(
  bytesReceived: 1024000,
  bytesSent: 512000,
  duration: '00:15:30',
)
```

### ProtocolBadge

Бейдж протокола VPN.

```dart
ProtocolBadge(protocol: 'VLESS')
```

Поддерживаемые: VLESS, Trojan, Shadowsocks, VMess

### CountryBadge

Бейдж страны.

```dart
CountryBadge(countryCode: 'RU')
```

### ServerCard

Карточка сервера в списке.

```dart
ServerCard(
  server: serverModel,
  isSelected: true,
  onTap: () => selectServer(serverModel),
)
```

### SubscriptionCard

Карточка подписки.

```dart
SubscriptionCard(
  subscription: subModel,
  onRefresh: () => refreshSub(subModel.id),
  onEdit: () => editSub(subModel.id),
)
```

### AppButton

Кнопка с вариантами стилей.

```dart
AppButton(
  text: 'Подключиться',
  variant: ButtonVariant.primary,
  size: ButtonSize.large,
  onPressed: () => connect(),
)
```

**Варианты:** primary, secondary, outline, ghost
**Размеры:** small, medium, large

### AppTextField

Текстовое поле.

```dart
AppTextField(
  label: 'URL подписки',
  hint: 'Вставьте ссылку...',
  prefixIcon: Icons.link,
  onChanged: (v) => setUrl(v),
)
```

### AppSwitch

Переключатель.

```dart
AppSwitch(
  label: 'Автоподключение',
  value: autoConnect,
  onChanged: (v) => setAutoConnect(v),
)
```

### AppDialog

Диалоговое окно.

```dart
AppDialog(
  title: 'Подтверждение',
  content: 'Вы уверены?',
  actions: [
    DialogAction(text: 'Отмена', onPressed: () => Navigator.pop(context)),
    DialogAction(text: 'Да', onPressed: () => confirm()),
  ],
)
```

### AppToast

Всплывающее уведомление.

```dart
AppToast.show(context, 'Подключение установлено', type: ToastType.success)
```

**Типы:** success, error, warning, info

### AppBottomSheet

Нижняя панель.

```dart
AppBottomSheet.show(
  context: context,
  child: Column(children: [...]),
)
```

### AppSearchBar

Строка поиска.

```dart
AppSearchBar(
  hint: 'Поиск серверов...',
  onChanged: (v) => setSearchQuery(v),
)
```

### AppChip

Чип.

```dart
AppChip(
  label: 'VLESS',
  selected: true,
  onTap: () => selectProtocol('VLESS'),
)
```

### AppProgress

Индикатор прогресса.

```dart
AppProgress(value: 0.75, color: AppColors.primary)
```

### AppEmptyState

Пустое состояние.

```dart
AppEmptyState(
  icon: Icons.vpn_lock,
  title: 'Нет серверов',
  description: 'Добавьте подписку для начала работы',
  action: AppButton(text: 'Добавить', onPressed: () => addSub()),
)
```

### AppLoading

Индикатор загрузки.

```dart
AppLoading(size: LoadingSize.large, color: AppColors.primary)
```

### AppDivider

Разделитель.

```dart
AppDivider(text: 'или')
```

### AppTooltip

Подсказка.

```dart
AppTooltip(
  message: 'Нажмите для подключения',
  child: ConnectionButton(...),
)
```

### AppDropdown

Выпадающий список.

```dart
AppDropdown<String>(
  value: selectedProtocol,
  items: ['VLESS', 'Trojan', 'Shadowsocks'],
  onChanged: (v) => setProtocol(v),
)
```

### AppSlider

Слайдер.

```dart
AppSlider(
  value: timeout.toDouble(),
  min: 5,
  max: 60,
  onChanged: (v) => setTimeout(v.toInt()),
)
```

### AppAvatar

Аватар.

```dart
AppAvatar(
  name: 'MaxSpeedVPN',
  size: AvatarSize.medium,
)
```

### AppBadge

Бейдж с счётчиком.

```dart
AppBadge(
  count: 11,
  child: Icon(Icons.dns),
)
```

## Анимации

Все анимации используют `Curves.easeInOut` с длительностью 200-300ms.

**Исключения:**
- Пульсация кнопки подключения: 2000ms, `Curves.easeInOut`, бесконечная
- Тест скорости: 15000ms, `Curves.linear`
- Переходы экранов: 300ms, `Curves.easeInOut`

## Адаптивность

Приложение оптимизировано для мобильных устройств (360px - 428px ширина).

**Брейкпоинты:**
- Compact: < 600px
- Medium: 600px - 840px
- Expanded: > 840px
