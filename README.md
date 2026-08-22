# Sprint Check

[![pub package](https://img.shields.io/pub/v/sprint_check.svg)](https://pub.dev/packages/sprint_check)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20linux%20%7C%20macos%20%7C%20windows-blue.svg)](https://pub.dev/packages/sprint_check)

Flutter plugin for BVN and NIN Verification with Picture. Fully supports Android, iOS, Web, Linux, macOS, and Windows platforms.

## Features

- **BVN Verification**: Complete Bank Verification Number verification with photo capture
- **NIN Verification**: National Identification Number verification with document scanning
- **Face Detection**: Advanced face detection and liveness checking
- **ID Card Scanning**: Support for various ID card types (Driver's License, Voter's Card, etc.)
- **Multi-platform Support**: Android, iOS, Web, Linux, macOS, Windows
- **Secure Encryption**: Built-in encryption for sensitive data
- **Real-time Validation**: Instant feedback during verification process


## Installation

Add `sprint_check` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  sprint_check: ^0.1.9
```

Then run:

```bash
flutter pub get
```

Import the package in your Dart code:

```dart
import 'package:sprint_check/sprint_check.dart';
```

Initialize the plugin preferably in the `initState` of your widget:

```dart
class _ExampleVerificationPageState extends State<ExampleVerificationPage> {
  final String apiKey = 'Add your SprintCheck API Key Here';
  final String encryptionKey = 'Add your SprintCheck Secret Key Here';
  final SprintCheck plugin = SprintCheck();

  @override
  void initState() {
    super.initState();
    plugin.initialize(
      apiKey: apiKey,
      encryptionKey: encryptionKey,
    );
  }
}
```

## Usage

The plugin provides two main verification methods:

1. **BVN Verification**: Complete verification workflow for Bank Verification Numbers
2. **NIN Verification**: Complete verification workflow for National Identification Numbers

Both methods include photo capture, face detection, and liveness verification.

### BVN Verification

```dart
try {
  CheckoutResponse response = await plugin.checkout(
    context, // BuildContext
    CheckoutMethod.bvn,
    "user@example.com", // Identifier for who performed the verification
    bvn: "1234567890", // Optional: Direct BVN input (skips UI input)
  );
  
  if (response.status && response.verify) {
    print("Verification successful: ${response.message}");
  } else {
    print("Verification failed: ${response.message}");
  }
} catch (e) {
  print("Error during verification: $e");
}
```

`plugin.checkout()` returns the state and details of the
verification in an instance of `CheckoutResponse` .



### NIN Verification

```dart
try {
  CheckoutResponse response = await plugin.checkout(
    context, // BuildContext
    CheckoutMethod.nin,
    "user@example.com", // Identifier for who performed the verification
    nin: "1234567890", // Optional: Direct NIN input (skips UI input)
  );
  
  if (response.status && response.verify) {
    print("Verification successful: ${response.message}");
  } else {
    print("Verification failed: ${response.message}");
  }
} catch (e) {
  print("Error during verification: $e");
}
```

## Response Format

The `CheckoutResponse` object contains the following fields:

```dart
class CheckoutResponse {
  final String message;        // Verification status message
  final String reference;      // Unique reference ID
  final bool status;           // Overall success status
  final CheckoutMethod method; // Verification method used
  final String? name;          // Verified name (masked)
  final bool verify;           // Verification success
  final String? bvn;           // BVN number (masked)
  final String? nin;           // NIN number (masked)
  final int score;             // Verification confidence score
}
```

### Example Response

```dart
CheckoutResponse{
  message: Verification Completed,
  reference: 99ed1c4d-362f-4a98-ac32-2f471e12aefb,
  status: true,
  method: CheckoutMethod.bvn,
  name: ***************,
  verify: true,
  bvn: ***********,
  nin: null,
  score: 98
}
```
## Platform Requirements

### Android
1. **Minimum SDK Version**: Ensure your `minSdkVersion` is at least **21** in `android/app/build.gradle`.

2. **Permissions**: Add these to your `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />

<!-- Required for image processing and cropping -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<!-- For Android 13+ (API 33) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

3. **UCropActivity**: Add the cropping activity to your `<application>` tag (required by `image_cropper`):
```xml
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

4. **ML Kit Models**: (Optional but recommended) To automatically download ML Kit models, add this to your `<application>` tag:
```xml
<meta-data
    android:name="com.google.mlkit.vision.DEPENDENCIES"
    android:value="face,ocr" />
```

### iOS
1. **Minimum iOS Version**: The plugin requires iOS **15.5** or higher.

2. **Permissions**: Add these to your `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face liveness and ID verification.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access for processing verification documents.</string>
```

3. **Permission Handler Setup**: Update your `ios/Podfile` to include the `PERMISSION_CAMERA` macro. Add this to the `post_install` block:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Required for permission_handler
    if target.name == 'permission_handler_apple'
      target.build_configurations.each do |config|
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
          '$(inherited)',
          'PERMISSION_CAMERA=1',
          'PERMISSION_PHOTOS=1',
        ]
      end
    end
  end
end
```

## Getting Started

To get your API keys and for technical support:

📧 **Email**: [odejinmisamuel@gmail.com] or [odejinmiabraham@gmail.com]

## Example

Check the `example/` directory for a complete sample application demonstrating all features.

## Support

This project is a Flutter [plug-in package](https://flutter.dev/to/develop-plugins) with platform-specific implementation code for Android, iOS, Web, Linux, macOS, and Windows.

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev).

## Troubleshooting

### Common Issues

**Camera Permission Denied**
- Ensure camera permissions are added to platform-specific configuration files
- On iOS, make sure to include usage descriptions in Info.plist
- On Android, verify permissions are in AndroidManifest.xml

**Verification Fails**
- Check that API keys are correctly configured
- Ensure network connectivity
- Verify that the BVN/NIN numbers are valid

**Build Issues**
- Run `flutter clean` and `flutter pub get`
- Ensure minimum platform requirements are met
- Check for conflicting dependencies

### Support

For technical support and API key requests:
- 📧 Email: [odejinmisamuel@gmail.com] or [odejinmiabraham@gmail.com]

## License

This project is licensed under the MIT License - see the LICENSE file for details.

