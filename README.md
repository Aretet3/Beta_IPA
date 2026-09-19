# Beta iOS

iOS-клиент мессенджера Beta. Полная синхронизация с PC и веб-приложением.

## Архитектура

Приложение использует **Flutter WebView** подход для загрузки веб-приложения Beta с сервера. Это обеспечивает:

- **100% синхронизация** — тот же сервер, те же данные, тот же UI
- **Весь функционал** — чаты, каналы, звонки, файлы, реакции, истории
- **Мгновенные обновления** — изменения сервера отображаются без обновления приложения

## Структура

```
iphone/
├── lib/
│   ├── main.dart                 # Точка входа
│   ├── config/
│   │   └── app_config.dart       # Конфигурация приложения
│   ├── screens/
│   │   ├── splash_screen.dart    # Заставка
│   │   ├── auth_screen.dart      # Авторизация/Регистрация
│   │   └── webview_screen.dart   # Основной WebView
│   └── services/
│       ├── api_service.dart      # REST API клиент
│       └── auth_service.dart     # Управление сессиями
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift     # Нативный iOS код
│   │   ├── Info.plist            # iOS конфигурация
│   │   └── ...
│   ├── Podfile                   # CocoaPods зависимости
│   └── Runner.xcodeproj/         # Xcode проект
├── assets/
│   └── inject_session.html       # Инъекция сессии в WebView
├── .github/workflows/
│   └── ios-build.yml             # GitHub Actions сборка
├── build_ios.bat                 # Локальная сборка
└── pubspec.yaml                  # Flutter зависимости
```

## Сборка

### Через GitHub Actions (IPA файл)

1. Запушьте код в репозиторий
2. Перейдите в Actions → iOS Build → Run workflow
3. Скачайте IPA из artifacts

### Локальная сборка

Требования:
- macOS с Xcode 15+
- Flutter SDK 3.2+
- CocoaPods

```bash
cd iphone
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release --no-codesign
```

### Создание IPA

```bash
cd build/ios/iphoneos
mkdir Payload
mv Runner.app Payload/
zip -r Beta.ipa Payload
```

## Установка

### Через AltStore/SideStore
1. Скачайте AltStore на компьютер
2. Подключите iPhone
3. Установите AltStore на iPhone
4. Перенесите Beta.ipa в AltStore

### Через Xcode
1. Подключите iPhone к Mac
2. Xcode → Window → Devices and Simulators
3. Перетащите Beta.ipa на устройство

## Синхронизация

Приложение полностью синхронизируется с PC и веб-версией:

- **Чаты** — все сообщения, медиа, файлы
- **Каналы** — посты, комментарии, подписки
- **Звонки** — WebRTC аудио/видео звонки
- **Профили** — аватары, статусы, настройки
- **Реакции** — эмодзи-реакции на сообщения
- **Истории** — stories с лайками и просмотром
- **Настройки** — все 14 категорий настроек

## Конфигурация сервера

URL сервера настраивается на экране авторизации или в `lib/config/app_config.dart`:

```dart
static String serverUrl = 'http://127.0.0.1:4173';
```

## iOS разрешения

Приложение запрашивает:
- Камера — для фото/видео и видеозвонков
- Микрофон — для голосовых сообщений и звонков
- Фото — для отправки медиа
- Уведомления — для push-уведомлений

## Firebase (Push-уведомления)

Для push-уведомлений добавьте:
1. Firebase конфигурацию в `ios/Runner/GoogleService-Info.plist`
2. `FirebaseAppDelegateProxyEnabled = NO` в Info.plist (уже настроено)

## Минимальная версия iOS

- iOS 15.0+
