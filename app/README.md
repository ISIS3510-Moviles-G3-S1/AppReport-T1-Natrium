# uni_market

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cloud Vision API Key

The app reads Google Cloud Vision key from compile-time environment:
`GOOGLE_CLOUD_VISION_API_KEY`.

Do not hardcode API keys in source code.

Run with key:

```bash
flutter run --dart-define=GOOGLE_CLOUD_VISION_API_KEY=YOUR_KEY_HERE
```

