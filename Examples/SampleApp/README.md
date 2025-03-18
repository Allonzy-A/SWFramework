# SWFramework Sample App

This is a sample application demonstrating how to integrate and use the SWFramework in an iOS application.

## Features

- Demonstrates initialization of the SWFramework
- Shows how to handle push notification registration
- Includes required Info.plist entries
- Uses automatic domain generation based on bundle ID

## Usage

1. Build the SWFramework
2. Include the framework in your application
3. Copy the integration code for your app type (UIKit or SwiftUI)
4. Add the required entries to your Info.plist

## Implementation Details

### UIKit Integration

The key integration points for UIKit apps:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Create a window and setup your root view controller
    self.window = UIWindow(frame: UIScreen.main.bounds)
    let rootViewController = UIViewController() // Use your actual view controller
    self.window?.rootViewController = rootViewController
    self.window?.makeKeyAndVisible()
    
    // Initialize the framework
    SWFramework.shared.initialize(
        applicationDidFinishLaunching: application,
        launchOptions: launchOptions,
        rootViewController: rootViewController, // Pass the root view controller directly
        completion: {
            // This will be called if the server returns an empty response
            // or if this is not the first launch and no WebView URL was saved
            print("Framework initialized and app is continuing normal flow")
        }
    )
    
    return true
}
```

### SwiftUI Integration

For SwiftUI apps, you can use the `.onAppear` modifier in your main view or set up a custom AppDelegate:

```swift
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
}

@main
struct MyApp: App {
    // Register app delegate for the application lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Get UIApplication instance
                    let application = UIApplication.shared
                    
                    // We need to get the root view controller
                    if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                        // Initialize the SWFramework
                        SWFramework.shared.initialize(
                            applicationDidFinishLaunching: application,
                            launchOptions: nil,
                            rootViewController: rootViewController,
                            completion: {
                                print("Framework initialized and app is continuing normal flow")
                            }
                        )
                    }
                }
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

### Push Notification Registration

For all apps, handle push notification registration:

```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    SWFramework.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
}
```

## Domain Generation

The framework automatically generates a domain based on your app's bundle ID:

- For this sample app with bundle ID "com.example.SampleApp", the domain will be "comexampleSampleApp.top"
- All dots are removed from the bundle ID and the top-level domain ".top" is added

## Required Permissions

Add these to your Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to the camera to provide full functionality in web content.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone to provide full functionality in web content.</string>
``` 