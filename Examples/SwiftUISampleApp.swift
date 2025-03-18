import SwiftUI
import UIKit
import SWFramework

// Define a class that conforms to UIApplicationDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
    
    // Handle push notification registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        SWFramework.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    // Handle push notification registration failure
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

@main
struct MySwiftUIApp: App {
    // Register app delegate for the application lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    initializeSWFramework()
                }
        }
    }
    
    func initializeSWFramework() {
        // Get UIApplication instance
        let application = UIApplication.shared
        
        // For iOS 15 and later - using UIApplication.shared.connectedScenes
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let rootViewController = windowScene?.windows.first?.rootViewController
        
        if let rootViewController = rootViewController {
            // Initialize the SWFramework
            SWFramework.shared.initialize(
                applicationDidFinishLaunching: application,
                launchOptions: nil,
                rootViewController: rootViewController,
                completion: {
                    print("Framework initialized and app is continuing normal flow")
                }
            )
        } else {
            print("Error: Could not find root view controller")
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, SWFramework!")
        }
        .padding()
    }
} 