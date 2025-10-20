
# ChatPT (demo_app)

ChatPT is a Flutter-based demo application that integrates Firebase authentication and Firestore to provide a multi-role experience (patient/doctor) and basic app flows such as login, password reset, and user profile caching.

This repository contains the Flutter client for the ChatPT app. It includes Android, iOS, web, and desktop platform folders and example services that communicate with Firebase.

## Key features

- Firebase Authentication (email/password)
- Password reset flow
- Role-aware navigation (doctor vs patient)
- Firestore user profile read/merge on login
- Simple, themeable UI with responsive layouts

## Prerequisites

- Flutter SDK (see https://docs.flutter.dev/get-started/install)
- A recent stable Dart/Flutter toolchain (Flutter 3.x or 4.x; use `flutter --version` to confirm)
- Android SDK / Xcode (for mobile platforms) if building for devices or emulators
- A Firebase project with Authentication and Firestore enabled

## Project structure (important files)

- `lib/main.dart` — app entrypoint and routing
- `lib/screens/` — UI screens (login, dashboards, main app screens)
- `lib/services/` — services for user/session handling and Firebase interactions
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` — platform-specific folders
- `firebase.json` and `lib/firebase_options.dart` — Firebase configuration helpers

## Setup

1. Clone the repository and open it in your editor:

	 git clone <repo-url>
	 cd ChatPT

2. Install Flutter packages:

	 flutter pub get

3. Configure Firebase:

	 - Create a Firebase project at https://console.firebase.google.com/
	 - Enable Email/Password sign-in in Authentication -> Sign-in method.
	 - Create a Firestore database (in test or production mode depending on your needs).
	 - If not already present, add platform apps (Android/iOS/web) in the Firebase console and download the config files:
		 - Android: `google-services.json` -> place it under `android/app/`
		 - iOS: `GoogleService-Info.plist` -> place it under `ios/Runner/`
		 - Web: copy the Firebase config and ensure `web/index.html` or `lib/firebase_options.dart` has the correct values.

	 Note: This repo already includes `lib/firebase_options.dart` and an example `android/app/google-services.json`. Verify they match your Firebase project. If you regenerate Firebase options using `flutterfire` CLI, keep the file checked in or update it accordingly.

4. (Optional) If using the `flutterfire` CLI to generate `firebase_options.dart`:

	 flutter pub global activate flutterfire_cli
	 flutterfire configure

## Running the app

- Run on an Android emulator or device:

	flutter run -d android

- Run on iOS (macOS with Xcode installed):

	flutter run -d ios

- Run on web (Chrome):

	flutter run -d chrome

If you run into build errors, run `flutter doctor` to see missing dependencies.

## Authentication notes

- The login screen (`lib/screens/login_screen.dart`) validates email/password and maps common FirebaseAuthException codes to friendly messages.
- On successful sign-in the app reads a `users` document from Firestore and merges available fields into a local `UserService` cache. If the Firestore document is missing the user is treated as a `patient` by default.

## Tests

 - There is a simple widget test in `test/widget_test.dart`. Run tests with:

	 flutter test

## Troubleshooting

- If authentication fails, check that the email/password provider is enabled in the Firebase console and that the app's Firebase configuration matches your project.
- If Firestore reads fail, make sure your Firestore rules allow reads for authenticated users during development, or configure rules appropriately for production.
- On Android, ensure `android/local.properties` has the correct SDK path and that `google-services.json` is in `android/app/`.

## Contributing

Contributions are welcome. Please open issues or PRs for bugs and feature requests.

## License & Contact

This repo is provided as-is for demo/learning purposes. For questions, mention the maintainer in repository issues.
