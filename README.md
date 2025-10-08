# A Sprint_check Plugin for Flutter Apps

Flutter plugin for BVN and NIN Verification with Picture. Fully
supports Android && Ios platform.

## Features
Current
- BVN
- NIN


## Installation
To use this plugin, add `sprint_check` as a [dependency in your pubspec.yaml file](https://flutter.dev/platform-plugins/).

Then initialize the plugin preferably in the `initState` of your widget.


``` dart
import 'package:flutterduplo/flutterduplo.dart';

class _ExamplePayementPageState extends State<ExamplePayementPage> {
  var api_key = 'Add your SprintCheck api_key Key Here';
  var encryption_key = 'Add your SprintCheck Secret Key Here';
  final plugin = SprintCheck();

  @override
  void initState() {
    plugin.initialize(api_key: api_key,encryption_key:encryption_key);
  }
}
```

## Making Verification
There are two ways of making Varification with the plugin.
1.  **BVN**: This is the easy way; as the plugin handles all the
    processes involved in making a BVN verification.
2.  **NIN**: This is the easy way; as the plugin handles all the
    processes involved in making a NIN verification.

### 1. BVN 

 ```dart
     CheckoutResponse response = await plugin.checkout(
       context context,
       CheckoutMethod.bvn, // Defaults to CheckoutMethod.selectable
        "odejinmiabraham@gmail.com", // means to identify who did the verification
        bvn:"1234567890"                                           // direct checkout if you don't want to use our input text
     );
 ```

`plugin.checkout()` returns the state and details of the
verification in an instance of `CheckoutResponse` .



### 2. NIN

```dart
      CheckoutResponse response = await plugin.checkout(
        context context,
        CheckoutMethod.nin, // Defaults to CheckoutMethod.selectable
        "odejinmiabraham@gmail.com", // means to identify who did the verification
        nin:"1234567890"
      );
```

### checkoutresponse
```dart
print("response for the sdk: ${response}");

result:
response for the sdk: CheckoutResponse{message: Verification Completed,reference: 99ed1c4d-362f-4a98-ac32-2f471e12aefb, status: true, method: CheckoutMethod.bvn, name: ***************, verify: true, bvn: ***********,  nin: null, verify: 98, }
```
## Getting Started
you can contact me on [odejinmisamuel@gmail.com] or [odejinmiabraham@gmail.com] for more enquiry and both api and encryption key

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

