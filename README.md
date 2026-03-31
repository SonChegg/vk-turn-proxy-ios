# VK TURN Proxy iOS

Отдельная iOS-версия для проекта `vk-turn-proxy-android`, собранная с учетом ограничений iOS.

Ключевое отличие от Android:
- Android-приложение запускает встроенный ELF-бинарник как отдельный процесс.
- На iOS такой подход не подходит, поэтому здесь подготовлен встроенный Go bridge, который должен собираться в `XCFramework` и вызываться прямо из SwiftUI-приложения.

## Что внутри

- `bridge/` — Go mobile bridge с API `start/stop/isRunning/drainLogs`
- `ios/` — SwiftUI-клиент, повторяющий основной сценарий Android-версии
- `expo-app/` — Expo development build с React Native UI и кастомным iOS Expo module
- `ios/scripts/prepare-macos-build.sh` — подготовка Mac-сборки в одну команду
- `ios/scripts/archive-ios-app.sh` — `archive` и опциональный экспорт `ipa`
- `ios/scripts/build-unsigned-ipa.sh` — сборка `unsigned ipa` для AltStore
- `.github/workflows/build-ios-unsigned-ipa.yml` — облачная сборка на GitHub Actions
- `.cirrus.yml` — запасная облачная сборка на Cirrus CI для public-репозитория

## Что уже реализовано

- отдельная папка проекта
- SwiftUI-интерфейс с guided-режимом и raw-режимом
- Expo development build с тем же сценарием запуска и локальным native bridge
- сохранение настроек в `UserDefaults`
- лог-экран и старт/стоп proxy runtime
- Go bridge под `gomobile`
- скрипт сборки `VkTurnCore.xcframework`
- `project.yml` для генерации Xcode-проекта через `xcodegen`
- автоматические скрипты подготовки и архивирования под macOS
- workflow для сборки `unsigned ipa` без своего Mac

## Ограничения

- В этой среде нет `swift`, `go`, `xcodebuild` и Xcode, поэтому локально собрать и проверить iOS-приложение здесь нельзя.
- По этой же причине проект подготовлен как исходники + скрипты сборки под macOS.
- На iOS нет прямого аналога Android-исключения приложения из WireGuard. Поэтому самый безопасный стартовый сценарий для этой версии — split-tunnel конфиг WireGuard с endpoint `127.0.0.1:9000` и `MTU = 1280`.
- `Expo Go` не подходит для этого кейса, потому что реальный proxy runtime живет в кастомном native iOS module. Для Expo-версии нужен именно development build.

## Техническая реальность

Этот проект делает не "магическую генерацию TURN-пароля из ссылки", а более приземленный сценарий:

- TURN-учетные данные для VK и Telemost не вычисляются локально, а запрашиваются через их API по invite-link.
- Трафик по умолчанию действительно оборачивается в DTLS 1.2 перед отправкой через TURN, но в текущей реализации используется self-signed certificate и `InsecureSkipVerify`.
- Для VK по умолчанию поднимается несколько параллельных соединений, обычно `16`, а для Yandex по умолчанию одно.
- Текущая iOS-версия не является полноценным `PacketTunnelProvider`/`NetworkExtension`. Это обычное приложение с локальным runtime, которое лучше рассматривать как foreground-клиент и экспериментальную iPhone-реализацию.

Из этого следует важный практический вывод:

- как transport-идея для Android/desktop и серверной стороны схема выглядит рабочей;
- как надежный системный iPhone tunnel проект пока нельзя считать завершенным продуктом;
- работоспособность зависит от того, не изменились ли upstream API VK Calls и Yandex Telemost.

## Expo Development Build

В репозиторий добавлен новый путь `expo-app/`, который переносит интерфейс на React Native / Expo, но сохраняет локальный Go runtime через custom Expo module.

Что внутри Expo-версии:
- React Native UI вместо SwiftUI
- локальное хранение настроек через AsyncStorage
- тот же guided/raw режим конфигурации
- Expo module `vk-turn-core`, который вызывает `VkTurnCore.xcframework` на iOS

Быстрый запуск на macOS:

```bash
cd expo-app
npm install
npm run prepare:ios
npx expo run:ios --device
```

Что делает `npm run prepare:ios`:
- собирает `VkTurnCore.xcframework` через `bridge/scripts/build-ios-framework.sh`
- копирует framework в локальный Expo module
- запускает `expo prebuild` для iOS
- ставит CocoaPods

Важно:
- Это development build, а не обычный `Expo Go`.
- Для установки на iPhone все равно нужен Mac с Xcode.
- Если хочешь `.ipa`, собирай уже сгенерированный Expo iOS project через Xcode Organizer или `eas build`.

## Без своего Мака

Если своего macOS нет, самый практичный вариант:

1. Залить этот проект в GitHub.
2. Запустить workflow `.github/workflows/build-ios-unsigned-ipa.yml`.
3. Скачать артефакт `VkTurnProxyIOS-unsigned-ipa`.
4. Установить его через AltStore / AltServer на Windows.
5. Обновлять подпись раз в 7 дней через AltServer.

Что делает workflow:
- использует `macos-latest` раннер GitHub Actions
- собирает `VkTurnCore.xcframework`
- генерирует `VkTurnProxyIOS.xcodeproj`
- собирает `unsigned .ipa` без Apple signing

Для этого пути не нужен ваш собственный Mac, но macOS всё равно используется внутри GitHub Actions.

## Бесплатный fallback для public-репозитория

Если GitHub Actions недоступен из-за account billing lock, в проект добавлен `.cirrus.yml` для Cirrus CI.

Что нужно сделать:

1. Оставить репозиторий public.
2. Подключить репозиторий к Cirrus CI через GitHub.
3. Дождаться task `build_unsigned_ipa_task`.
4. Скачать артефакт `ios/build/unsigned/VkTurnProxyIOS-unsigned.ipa`.

Этот путь тоже использует macOS в облаке, но уже не через GitHub-hosted runners.

## Сборка на macOS

Самый короткий путь:

```bash
cd ios
./scripts/prepare-macos-build.sh
```

Этот скрипт:
- проверит, что вы на macOS и что установлен Xcode
- скачает `xcodegen` локально в `.tools/`
- установит `gomobile`, если он ещё не установлен
- соберёт `ios/Frameworks/VkTurnCore.xcframework`
- сгенерирует `VkTurnProxyIOS.xcodeproj`

После подготовки можно собрать archive:

```bash
cd ios
DEVELOPMENT_TEAM=ABCDE12345 ./scripts/archive-ios-app.sh
```

Если нужен экспорт `ipa`:

```bash
cd ios
DEVELOPMENT_TEAM=ABCDE12345 \
EXPORT_OPTIONS_PLIST="$PWD/ExportOptions.example.plist" \
./scripts/archive-ios-app.sh
```

### Ручной путь

1. Установить Go, Xcode и Command Line Tools.
2. Установить `gomobile`:

```bash
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
```

3. Собрать bridge:

```bash
cd bridge
./scripts/build-ios-framework.sh
```

4. Подготовить Xcode-проект:

```bash
cd ../ios
./scripts/prepare-macos-build.sh
```

5. Открыть `VkTurnProxyIOS.xcodeproj` в Xcode.
6. Выставить Team / Bundle ID при необходимости.
7. Собрать на реальное устройство.

## Как использовать

1. В приложении WireGuard на iPhone указать endpoint сервера как `127.0.0.1:9000`.
2. Поставить `MTU = 1280`.
3. В этом приложении указать:
   - `Peer` — ваш VPS и порт серверной части (`x.x.x.x:56000`)
   - `Link` — `https://vk.com/call/join/...`
   - `Streams` — обычно `8`
   - `Use UDP` — включено
4. Нажать `Запустить`.

## Структура

```text
vk-turn-proxy-ios/
├── README.md
├── bridge/
│   ├── go.mod
│   ├── proxycore/
│   └── scripts/
├── expo-app/
│   ├── App.tsx
│   ├── src/
│   ├── modules/
│   └── scripts/
└── ios/
    ├── scripts/
    ├── Frameworks/
    ├── project.yml
    └── App/
```
