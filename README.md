# SWFramework

A Swift framework for iOS applications that collects device data, communicates with a server, and displays web content based on the server response.

## Features

- Pauses app processes on launch to collect device data
- Collects APNS token, ATT token, and bundle ID
- Communicates with a server to determine next actions
- Displays web content in a full-screen WebView if required
- Caches server response for future app launches
- Supports iOS 15.0+
- Automatically generates domain from bundle ID

## Requirements

- iOS 15.0+
- Swift 5.5+
- Xcode 13.0+

## Installation

### Swift Package Manager

Add it directly in Xcode by selecting File > Add Packages and entering the repository URL.

## Usage

Import SWFramework in your AppDelegate or SceneDelegate:

```swift
import SWFramework
```

Initialize the framework in your AppDelegate's `application(_:didFinishLaunchingWithOptions:)` method:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Initialize the framework
    SWFramework.shared.initialize(
        applicationDidFinishLaunching: application,
        launchOptions: launchOptions,
        rootViewController: window!.rootViewController!,
        completion: {
            // This will be called if the server returns an empty response
            // or if this is not the first launch and no WebView URL was saved
            // Continue with your normal app initialization here
        }
    )
    
    return true
}
```

Add the following method to your AppDelegate to handle APNS token registration:

```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    SWFramework.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
}
```

## Domain Generation

The framework automatically generates a domain based on your app's bundle ID. For example:

- If your bundle ID is "svs.tartnap", the generated domain will be "svstartnap.top"
- All dots are removed from the bundle ID, and the top-level domain ".top" is added

## Permissions

The framework will request the following permissions:

- Push notifications (for APNS token)
- Camera (if required by WebView content)

Make sure to add the following keys to your Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to the camera to provide full functionality in web content.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone to provide full functionality in web content.</string>
```

## License

This framework is licensed under the MIT License. 
