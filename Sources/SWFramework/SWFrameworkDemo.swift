#if FRAMEWORK_DEMO_ENABLED
// Этот файл компилируется только при определении специального флага FRAMEWORK_DEMO_ENABLED
// и не будет конфликтовать с основной точкой входа в приложение

import SwiftUI
import UIKit

// MARK: - Sample App Entry Point (Упрощенный способ)
@main
struct SWFrameworkSimpleDemo: App {
    var body: some Scene {
        WindowGroup {
            SWWebView(contentView: AnyView(SimpleContentView()))
                .initSWFramework() // Простая инициализация в одну строку!
        }
    }
}

// MARK: - Simple Content View
struct SimpleContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            
            Text("Упрощенная версия")
                .font(.largeTitle)
                .bold()
            
            Text("Фреймворк инициализируется автоматически с помощью модификатора .initSWFramework()")
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

// MARK: - Альтернативные способы инициализации фреймворка

/*
// MARK: - Вариант 1: Использование UIApplicationDelegateAdaptor
@main
struct SWFrameworkDemoApp1: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            SWWebView(contentView: AnyView(ContentView(state: appState)))
        }
    }
}

// MARK: - Вариант 2: Использование SWAppDelegate
@main
struct SWFrameworkDemoApp2: App {
    @UIApplicationDelegateAdaptor(SWAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SWWebView(contentView: AnyView(SimpleContentView()))
        }
    }
}
*/

// MARK: - Sample Content View (для полного примера)
struct ContentView: View {
    @ObservedObject var state: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            
            Text("SWFramework Demo")
                .font(.largeTitle)
                .bold()
            
            Text("This is the fallback content that will be shown if the WebView is not displayed")
                .multilineTextAlignment(.center)
                .padding()
            
            if state.isLoading {
                ProgressView()
                    .padding()
                Text("Initializing framework...")
            } else {
                Text("Framework initialized successfully")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isLoading = true
    
    func finishLoading() {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}

// MARK: - App Delegate (полный вариант инициализации)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize the framework
        let appState = AppState()
        
        SWFramework.shared.initialize(application: application, launchOptions: launchOptions) {
            // Called when either the WebView is shown or normal app flow should continue
            appState.finishLoading()
        }
        
        return true
    }
    
    // Handle remote notifications registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass the token to the framework
        SWFramework.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Handle error
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}
#endif 