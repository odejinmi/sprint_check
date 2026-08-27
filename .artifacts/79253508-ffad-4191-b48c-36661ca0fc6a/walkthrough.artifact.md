# Walkthrough - iOS Deployment Target Bump

I have updated the iOS deployment target from 15.5 to 16.0 to resolve a CocoaPods version conflict with the `FaceCoreBasic` pod (part of the Regula Face SDK).

## Changes Made

### 1. Updated `sprint_check.podspec`
Bumped the minimum iOS platform version to 16.0 to match the requirements of the updated native dependencies.

[sprint_check.podspec](file:///Users/macbook/StudioProjects/sprint_check/ios/sprint_check.podspec)
```ruby
-  s.platform = :ios, '15.5'
+  s.platform = :ios, '16.0'
```

### 2. Updated Example App `Podfile`
Updated the platform and explicit deployment target setting in the example app's `Podfile`.

[Podfile](file:///Users/macbook/StudioProjects/sprint_check/example/ios/Podfile)
```ruby
-platform :ios, '15.5'
+platform :ios, '16.0'
...
-      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
+      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
```

### 3. Updated Xcode Project Configuration
Updated `IPHONEOS_DEPLOYMENT_TARGET` to 16.0 in the example app's `project.pbxproj` file to ensure all build configurations are consistent.

### 4. Refreshed Dependencies
Ran `pod update` in the `example/ios` directory, which successfully resolved the version conflicts and installed the latest compatible versions of `FaceCoreBasic` (8.3.2550) and `FaceSDK` (8.3.4727).

## Verification Results

### Pod Installation
`pod update` completed successfully without errors.

### Build Success
The example app was successfully built for iOS:
```bash
✓ Built build/ios/iphoneos/Runner.app (141.0MB)
```

> [!NOTE]
> The build was performed with `--no-codesign`. You may still need to configure code signing in Xcode to run on a physical device.
