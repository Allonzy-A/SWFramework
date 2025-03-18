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
3. Copy the integration code from the AppDelegate.swift file
4. Add the required entries to your Info.plist

## Implementation Details

The key integration points are:

1. Initialize the framework in `application(_:didFinishLaunchingWithOptions:)`:

```swift
SWFramework.shared.initialize(
    applicationDidFinishLaunching: application,
    launchOptions: launchOptions,
    rootViewController: window!.rootViewController!,
    completion: {
        // This will be called if the server returns an empty response
        // or if this is not the first launch and no WebView URL was saved
        print("Framework initialized and app is continuing normal flow")
    }
)
```

2. Handle push notification registration:

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