# MaxSpeed VPN — Руководство по настройке

## Требования

- **ОС**: Linux (Ubuntu 22.04+), macOS 13+, Windows 10+ с WSL2
- **RAM**: 8 ГБ минимум (16 ГБ рекомендуется)
- **Диск**: 15 ГБ свободно

## 1. Установка Flutter

### Linux
```bash
sudo apt update && sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

### macOS
```bash
brew install --cask flutter
```

### Проверка
```bash
flutter doctor && flutter --version
```

## 2. Android SDK

**Через Android Studio** (рекомендуется): скачайте с developer.android.com/studio, установите SDK Platform API 34, Build-Tools, NDK, CMake.

**Через CLI:**
```bash
mkdir -p $HOME/android-sdk/cmdline-tools && cd $HOME/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-latest.zip
unzip commandlinetools-linux-latest.zip && mv cmdline-tools latest
echo 'export ANDROID_HOME=$HOME/android-sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
sdkmanager "platforms;android-34" "build-tools;34.0.0" "ndk;25.2.9519653" "cmake;3.22.1"
```

```bash
flutter doctor --android-licenses
```

## 3. Дополнительные инструменты

```bash
# Linux
sudo apt install -y protobuf-compiler jq
# macOS
brew install protobuf jq
```

## 4. Клонирование

```bash
git clone https://github.com/maxspeedvpn/maxspeed-vpn.git && cd maxspeed-vpn
```

## 5. Конфигурация

```bash
cp .env.example .env
cp android/local.properties.example android/local.properties
# Отредактируйте local.properties с путями к SDK
```

## 6. Зависимости

```bash
flutter pub get
```

## 7. Генерация кода

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 8. Сборка

```bash
flutter build apk --debug    # Отладочная
flutter build apk --release  # Релизная
flutter build appbundle --release  # Для Play Store
```

## 9. Тесты

```bash
flutter test              # Все тесты
flutter test --coverage   # С покрытием
```

## Устранение неполадок

- **Android SDK не найден**: проверьте `ANDROID_HOME` и `PATH`
- **Ошибка NDK**: сверьте `ndkVersion` в `android/app/build.gradle`
- **Gradle daemon**: `./android/gradlew --stop` затем пересборка
- **Protoc не найден**: установите protobuf-compiler
