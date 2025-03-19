import SwiftUI
import UIKit

// MARK: - Sample App Entry Point
@main
struct SWFrameworkDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            SWWebView(contentView: AnyView(ContentView(state: appState)))
        }
    }
}

// MARK: - Sample Content View
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

// MARK: - App Delegate
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