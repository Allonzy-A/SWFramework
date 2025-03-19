# SWFramework

Легковесный SwiftUI фреймворк для управления веб-контентом и уведомлениями в iOS приложениях.

## Особенности

- Полная интеграция с SwiftUI и современной архитектурой iOS приложений
- Обработка APNS токенов для push-уведомлений
- Получение и обработка Attribution токенов (iOS 14.3+)
- Отображение полноэкранного WebView с поддержкой запросов медиа-доступа
- Автоматическая генерация доменов на основе идентификатора приложения

## Требования

- iOS 15.0+
- Swift 5.5+
- Xcode 13.0+

## Установка

### Swift Package Manager

Добавьте SWFramework в качестве зависимости в ваш Package.swift файл:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/SWFramework.git", from: "1.0.0")
]
```

Или добавьте его через Xcode:
1. File > Add Packages
2. Введите URL репозитория
3. Выберите версию и целевой проект

## Использование

### Интеграция с SwiftUI

1. Создайте AppDelegate и используйте @UIApplicationDelegateAdaptor в вашем App:

```swift
@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SWWebView(contentView: AnyView(YourContentView()))
        }
    }
}
```

2. Настройте AppDelegate:

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        SWFramework.shared.initialize(application: application, launchOptions: launchOptions) {
            // Код, выполняемый после инициализации
        }
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        SWFramework.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}
```

3. Создайте основной контент приложения, который будет отображаться, если WebView не активирован:

```swift
struct YourContentView: View {
    var body: some View {
        VStack {
            Text("Основной контент приложения")
        }
    }
}
```

## Демонстрация

В проекте включен демонстрационный файл `SWFrameworkDemo.swift`, показывающий полную интеграцию фреймворка в SwiftUI приложение.

## Работа фреймворка

1. При инициализации фреймворк проверяет, запускается ли приложение в первый раз
2. Если это первый запуск, фреймворк получает APNS и Attribution токены
3. Данные отправляются на сервер, и в зависимости от ответа:
   - Отображается WebView с URL из ответа, или
   - Продолжается нормальный поток приложения

## Сборка

Для сборки проекта используйте Xcode или Swift Package Manager с настройками для iOS:

```bash
xcodebuild -scheme SWFramework -sdk iphoneos -configuration Release
```

## Лицензия

MIT 