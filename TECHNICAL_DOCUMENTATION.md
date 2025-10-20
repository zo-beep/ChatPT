<!--
Comprehensive technical documentation for ChatPT
This file is intended for inclusion in technical reports and handoffs.
-->

# ChatPT — Technical Documentation

Version: 1.0.0
Generated: 2025-10-21

## Executive Summary

ChatPT is a cross-platform conversational application built with Flutter. It provides users with an interactive AI-powered chat experience, video/exercise content, account management, and administrative tooling. The app is integrated with Firebase for authentication and real-time data storage, and it uses Google's Generative AI SDK (Gemini) to power assistant responses. This document is intended to support engineering, QA, DevOps, and product teams during development, deployment, and maintenance.

Key outcomes
- Deliver a secure, maintainable client application for iOS, Android, web and desktop.
- Enable AI-driven conversational features while preserving security best practices (API key management, least-privilege access).
- Provide admin tooling and migration scripts to operate and evolve the data model safely.

## Table of Contents

1. Project Overview
2. System Architecture
3. Technologies Used
4. Installation Guide
5. Configuration
6. Code Structure
7. API & Data Model
8. Error Handling & Logging
9. Testing Strategy
10. Deployment Instructions
11. CI/CD Example (GitHub Actions)
12. Maintenance & Troubleshooting
13. Appendix: Useful Commands & Scripts

---

## 1. Project Overview

Purpose
- Provide a modern, responsive chat application that uses generative AI to assist users in various tasks (chat, exercise guidance, FAQs), while storing relevant conversation data and user metadata in Firestore.

Primary Users
- End users consuming chat and media features.
- Admins who manage user roles and run data migration or backfill tasks.

Primary Use Cases
- User signup and authentication.
- Conversational prompts and AI-assisted responses.
- Video-based exercises and content consumption.
- Admin batch updates (role assignment, user backfills).

Non-goals (explicit exclusions)
- The repository does not include an authoritative, production-grade backend service for AI key management (server-side proxy) by default. It is recommended to implement one for production to avoid exposing API keys.

---

## 2. System Architecture

Overview
- The architecture is client-centric (Flutter), with Firebase providing serverless backend services for auth and data persistence. AI capabilities are provided by the Google Generative AI SDK; calls may be made directly from the client for development, but production should use a secure server-side proxy.

High-level component diagram

```
+----------------------+     +------------------------+     +-----------------------+
|    Flutter Client    | <-> |   Firebase Services    | <-> | Admin Node Scripts    |
| (iOS/Android/Web/PC) |     | (Auth, Firestore, CI)  |     | (tools/*.js)          |
+----------------------+     +------------------------+     +-----------------------+
         |  ^                               |
         |  | SDK/API                        | (managed services)
         v  |                               v
  +--------------------+             +--------------------+
  | Google Generative  |             | Optional Backend   |
  | AI (Gemini SDK)    |             | Proxy (recommended)|
  +--------------------+             +--------------------+
```

Data flow (example: chat)
1. User sends prompt from client UI.
2. Client calls AiService (local service class) which prepares prompt and metadata.
3a. Development: AiService calls Google Generative AI SDK directly and returns result.
3b. Production (recommended): AiService calls a secure backend proxy that forwards request to the AI provider.
4. App writes conversation metadata and transcript to Firestore.

Security considerations
- Do not store API keys in the client source. Use CI secrets or backend proxy to manage keys.
- Secure Firestore rules to enforce least-privilege (users can only read their own chats, admins have elevated permissions).

---

## 3. Technologies Used

Primary
- Flutter (Dart) — app framework targeting mobile, web, and desktop.
- Firebase — Authentication, Cloud Firestore, and other managed services.
- Google Generative AI SDK (`google_generative_ai`) — Gemini models.

Notable dependencies (from `pubspec.yaml`)
- firebase_core, firebase_auth, cloud_firestore
- google_generative_ai
- video_player, flutter_markdown, fluttertoast, shared_preferences
- flutter_lints (dev)

Supporting tools
- Node.js scripts in `tools/` for migration and admin tasks.
- Optional: `firebase-tools` (for hosting and emulators), `sentry` or `firebase_crashlytics` for logging.

Compatibility
- Dart SDK: See `pubspec.yaml` environment (e.g., ^3.9.2)
- Flutter: Use the version compatible with the project's dependencies. Run `flutter doctor` and `flutter pub get` to verify local environment.

---

## 4. Installation Guide

Goal: Walk a new developer through setting up the project locally for development and testing.

Prerequisites
- Install Flutter (stable channel recommended). Follow: https://flutter.dev/docs/get-started/install
- Install Android Studio (or Android SDK) and set up an emulator OR have a USB device connected.
- For iOS builds: macOS + Xcode.
- Node.js and npm (for `tools/` scripts and potential backend tooling).
- Optional: install `firebase-tools` globally for local Firebase emulation and deployment.

Clone repository and fetch dependencies

```powershell
git clone https://github.com/zo-beep/ChatPT.git
cd ChatPT
flutter pub get
```

Configure Firebase locally
- The repo contains `lib/firebase_options.dart`. If you need to reconfigure the Firebase project, run the FlutterFire CLI to generate new options for your Firebase project:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Add platform-specific Firebase configuration
- Android: place `google-services.json` under `android/app/`.
- iOS: place `GoogleService-Info.plist` in `ios/Runner/`.

Run the app

```powershell
# Launch app on connected device/emulator
flutter run

# Run a specific flavor/target if configured
flutter run -t lib/main.dart
```

Run Node admin scripts

```powershell
cd tools
npm install
node migrateUsersCollection.js
```

Local Firebase emulation (optional)

```powershell
npm i -g firebase-tools
firebase emulators:start --only auth,firestore
```

---

## 5. Configuration

Environment variables and build-time defines

The app expects certain environment values for AI integration and advanced features. Prefer build-time defines and CI secret injection.

Common variables
- GEMINI_API_KEY — (string) API key for Google Generative AI (Gemini). Do not commit.
- FIREBASE_PROJECT_ID — (string) Firebase project id if you dynamically load configuration

Examples (PowerShell)

```powershell
# run locally with an API key (development only)
flutter run --dart-define=GEMINI_API_KEY="your_dev_key"

# build release with dart-define
flutter build apk --dart-define=GEMINI_API_KEY="your_prod_key"
```

Recommended secret management
- For CI/CD, store secrets in the platform's secret store and pass them as environment variables to build steps. If you create a backend proxy, store keys there and never embed them in the client.

Firebase security rules
- Ensure Firestore rules limit reads/writes appropriately. Example (pseudo):

```text
match /chats/{chatId} {
  allow read, write: if request.auth.uid == resource.data.userId || request.auth.token.role == 'admin';
}
```

---

## 6. Code Structure

This section explains the main folders and files and their responsibilities. Paths are relative to project root.

- `lib/`
  - `main.dart` — application entrypoint; sets up services and routes.
  - `firebase_options.dart` — platform-specific Firebase configuration (generated by FlutterFire).
  - `screens/` — screen classes (login, main, chat, admin, doctor, exercise, help)
    - `login_screen.dart` — authentication UI
    - `chatbot_screen.dart` — main chat interface
    - `admin_dashboard_screen.dart` — admin controls
  - `services/` — business logic and integration layers
    - `auth_service.dart` — Firebase Auth wrapper
    - `firestore_service.dart` — Firestore read/write helpers
    - `ai_service.dart` — wrapper for Generative AI calls (Gemini SDK)
    - `video_service.dart` — video player helpers
  - `models/` — data model classes (User, ChatMessage, Conversation)
  - `widgets/` — reusable UI components (ChatBubble, MediaCard)
- `assets/` — media assets (videos, images)
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` — platform projects
- `tools/` — Node.js helper scripts
  - `backfillUsers.js`, `migrateUsersCollection.js`, `setRoleClaim.js`
- `test/` — unit and widget tests

Coding conventions
- Linting provided by `flutter_lints`. Run `flutter analyze` and address lints prior to merging.

Extension points
- `AiService` is the main integration point for model calls; swap implementation to route through a secure backend without changing UI code.

---

## 7. API & Data Model

This project uses Cloud Firestore as the primary data store. Here are the documented collections, fields, and sample reads/writes.

Data model (recommended canonical schema)

- users (collection)
  - document id: uid
  - fields:
    - displayName: string
    - email: string
    - role: string (e.g., "user", "admin", "doctor")
    - createdAt: timestamp

- chats (collection)
  - document id: chatId (or use a nested collection under user document)
  - fields:
    - userId: uid
    - messages: array of message objects or nested `messages` subcollection
    - updatedAt: timestamp

- messages (subcollection under chats/{chatId}/messages) — recommended to avoid large arrays
  - fields:
    - senderId: uid or 'assistant'
    - content: string
    - contentType: string ("text", "markdown", "media")
    - createdAt: timestamp

Sample Firestore write (Dart)

```dart
final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
await chatRef.collection('messages').add({
  'senderId': uid,
  'content': 'Hello, can you help me?',
  'contentType': 'text',
  'createdAt': FieldValue.serverTimestamp(),
});

await chatRef.set({'userId': uid, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
```

AI request/response flow (suggested production design)
1. Client sends prompt to `/api/ai/generate` on a server-side proxy with an authenticated bearer token.
2. Proxy injects server-side API key and forwards request to Gemini.
3. Proxy validates/limits request size and logs usage to an internal metrics system.
4. Proxy returns response, client stores transcript to Firestore.

Sample proxy request (JSON)

Request

```json
{
  "userId": "uid-123",
  "prompt": "Explain the benefits of breathing exercises",
  "conversationId": "conv-456"
}
```

Response

```json
{
  "text": "Breathing exercises reduce stress by...",
  "tokens": 234,
  "metadata": {"model": "gemini"}
}
```

---

## 8. Error Handling & Logging

Principles
- Fail fast for developer errors; graceful degrade for user-facing errors.
- Log detailed diagnostics to remote log/monitoring systems in production.

Client-side patterns
- Wrap all async calls with try/catch and show contextual error messages.
- Use local fallback strategies when possible (e.g., retry logic for transient network errors, offline cache for recent chats).

Example error handling (Dart)

```dart
try {
  final result = await aiService.generateReply(prompt);
} on NetworkException catch (e) {
  Fluttertoast.showToast(msg: 'Network error — please check your connection.');
} catch (e, st) {
  log.error('Unhandled error in AI generation', error: e, stackTrace: st);
  Fluttertoast.showToast(msg: 'Unexpected error occurred.');
}
```

Logging & monitoring
- Development: use `print()` and `dart:developer` for ad-hoc traces.
- Production: integrate Crashlytics or Sentry. Log level strategy:
  - ERROR: crashes, uncaught exceptions
  - WARNING: user-facing recoverable errors, degraded functionality
  - INFO: key business events (account creation, significant AI usage)

---

## 9. Testing Strategy

Testing goals
- Verify business logic of service layers.
- Validate critical UI flows (authentication, chat lifecycle).
- Ensure Firestore reads/writes conform to expected schemas.

Test types
- Unit tests: pure functions, services (e.g., message parsing, ai_service when stubbed).
- Widget tests: UI components and screens.
- Integration tests: optional, use device/emulator and emulate real flows.

Running tests

```powershell
flutter test
```

Mocking external services
- Mock Firestore and Auth using mock packages or by abstracting services behind interfaces and providing fake implementations during tests.
- For AI responses, create a `FakeAiService` that returns deterministic responses.

Sample unit test snippet (Dart)

```dart
test('AiService returns response', () async {
  final fakeAi = FakeAiService();
  final result = await fakeAi.generateReply('hello');
  expect(result.text, contains('hello'));
});
```

Coverage & quality gates
- Add `flutter test --coverage` to CI and fail builds below a coverage threshold (optional).

---

## 10. Deployment Instructions

Android

```powershell
# Build debug
flutter build apk

# Build release
flutter build apk --release

# App bundle (recommended for Play Store)
flutter build appbundle --release
```

iOS
- Build on macOS using Xcode/Flutter toolchain; configure provisioning and app identifiers.

Web (Firebase Hosting)

```powershell
flutter build web
firebase deploy --only hosting
```

Backend proxy (recommended)
- If you create a proxy for AI requests, deploy it on a secure platform (Cloud Run, App Engine, or another managed container service) and protect it with authentication and rate limiting.

Rollout strategy
- Staged rollouts for mobile stores (internal test -> alpha -> beta -> production).
- Monitor logs & metrics after release, and be ready to roll back changes quickly.

---

## 11. CI/CD Example (GitHub Actions)

Below is a minimal workflow that installs Flutter, runs analysis, and runs tests. Place this in `.github/workflows/flutter-ci.yml`.

```yaml
name: Flutter CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      - name: Install dependencies
        run: flutter pub get
      - name: Analyze
        run: flutter analyze
      - name: Run tests
        run: flutter test --coverage

# For release workflows, add build and publish steps with secrets for signing and distribution.
```

Secrets to set in GitHub Actions
- GEMINI_API_KEY (if used in CI builds; prefer proxy approach instead)
- ANDROID_KEYSTORE / store credentials for play store signing

---

## 12. Maintenance & Troubleshooting

Common issues & solutions
- Firebase auth errors
  - Symptoms: login fails with permission errors.
  - Check: `lib/firebase_options.dart` matches project, `google-services.json`/`GoogleService-Info.plist` present, Firestore rules allow intended accesses.

- AI responses fail or return 401/403
  - Check: API key validity, billing/quota, and whether requests are being proxied. If calls originate from clients, ensure the key hasn't been revoked.

- Video playback issues
  - Ensure `assets/videos/` are included in `pubspec.yaml` and the `video_player` plugin is initialized correctly.

Upgrade procedure
1. Bump dependency in `pubspec.yaml`.
2. Run `flutter pub upgrade --major-versions` optionally to test major updates.
3. Run `flutter analyze` and `flutter test` and fix any breaking changes.

Data migration
- Use scripts in `tools/` for non-trivial migrations. Always run migrations on a staging copy first and keep a Firestore export backup in case of rollback.

Backups
- Schedule Firestore exports to Cloud Storage using `gcloud` scheduled tasks or Cloud Functions triggered exports.

Ownership & contacts
- Repo owner: `zo-beep`
- Add or update `CODEOWNERS` to identify reviewers for PRs.

---

## 13. Appendix: Useful Commands & Scripts

Project commands

```powershell
# Fetch deps
flutter pub get

# Run app
flutter run

# Run tests
flutter test

# Build Android release
flutter build appbundle --release

# Generate firebase options if reconfiguring
flutterfire configure
```

Admin scripts

```powershell
cd tools
npm ci
node backfillUsers.js
node migrateUsersCollection.js
node setRoleClaim.js --uid <uid> --role admin
```

Security checklist before production release
- Remove any dart-define keys in source control and inject them from CI.
- Deploy an AI-proxy service and update `AiService` to use it.
- Harden Firestore rules and test with the Firebase emulator.

---

End of documentation.

If you want this converted to a printable PDF or enriched with visual diagrams (PNG/SVG) and a section summarizing risk & mitigation, tell me which diagrams you'd like and I can add them.
## Project Overview

Project: ChatPT (Flutter)

Purpose
- A cross-platform Flutter application that provides conversational AI features, user accounts, media (video) playback, and administrative tooling. The app integrates with Firebase for authentication and data storage and uses Google's generative AI (Gemini) SDK to power chat/assistant capabilities.

Key features
- User authentication (Firebase Auth)
- Conversational AI using Google Generative AI (Gemini)
- Firestore-backed data storage for users, chats, and app data
- Video playback and media assets
- In-app notifications and toast messaging
- Admin scripts to manage user roles and data (see `tools/`)

Goals
- Provide a reliable, secure, and extendable mobile/web chat experience using managed cloud services.
- Keep the app modular so features (chat, video, exercises, admin) can be extended independently.

## System Architecture

High-level components
- Mobile/Web Flutter client (UI, local storage, media playback)
- Firebase services (Authentication, Cloud Firestore, Hosting for web if used)
- Google Generative AI (Gemini) for conversational responses
- Admin tooling (Node.js scripts under `tools/`) for batch jobs and role management

ASCII diagram

```
[Flutter Client] <---> [Firebase Auth]
       |                     |
       |                     V
       |               [Cloud Firestore]
       |                     |
       V                     V
 [Google Generative AI] <---> [Admin Scripts]
```

Explanation
- The Flutter client authenticates users using Firebase Auth and reads/writes app data to Firestore. Conversational requests that require model responses are forwarded to Google Generative AI via the client (or a secure backend if implemented). Admin scripts are provided to run batch operations (e.g., backfilling users, setting claims) against Firebase.

## Technologies Used

- Flutter (Dart) — cross-platform UI framework
- Firebase (Auth, Cloud Firestore, Hosting) — backend services
- Google Generative AI SDK (`google_generative_ai`) — Gemini model integration
- video_player — in-app video playback
- shared_preferences — local key-value storage
- flutter_markdown — render markdown content
- fluttertoast — lightweight user notifications
- Node.js scripts for admin tasks (under `tools/`)

Key files showing tech usage
- `pubspec.yaml` — lists app dependencies and assets
- `lib/firebase_options.dart` — generated Firebase options (platform configs)
- `tools/` — Node.js scripts for administration and migration

## Installation Guide

Prerequisites
- Install Flutter (matching the project's SDK constraints; see `pubspec.yaml` environment sdk). Windows users: install Flutter SDK, Android Studio (or VS Code + Android SDK), and enable developer tools.
- Install Node.js (for running admin scripts in `tools/`).

Clone and fetch dependencies

```powershell
git clone https://github.com/zo-beep/ChatPT.git
cd ChatPT
flutter pub get
```

Platform-specific steps
- Android
  - Ensure Android SDK and an emulator or device are available.
  - If building for release, configure `android/app/google-services.json` and set signing configs.
- iOS
  - macOS required for iOS tooling. Configure `ios/Runner/Info.plist` and add `GoogleService-Info.plist` if using Firebase on iOS.
- Web
  - If deploying to Firebase Hosting, ensure `firebase-tools` is installed (npm i -g firebase-tools) and `firebase login` has been completed.

Run app (development)

```powershell
# Run on an available device/emulator
flutter run

# Run tests
flutter test
```

## Configuration

Environment & credentials
- Firebase configuration files are platform-specific and typically placed as:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- The project includes a generated `lib/firebase_options.dart` — keep this file in sync with your Firebase project configuration.
- Google Generative AI / Gemini requires credentials or API key. Options for storing keys in Flutter apps:
  - Use Dart define during build: `flutter run --dart-define=GEMINI_API_KEY=your_key_here`
  - Store in secure backend and proxy requests through a server (recommended for production).

Sample `launch` and build defines (PowerShell)

```powershell
# Development run with Gemin API key via dart-define
flutter run --dart-define=GEMINI_API_KEY="YOUR_KEY"

# Build APK with API key
flutter build apk --dart-define=GEMINI_API_KEY="YOUR_KEY"
```

Best practices
- Never commit secrets or API keys to source control. Use CI secrets or a secret manager.
- For production, route AI calls through a trusted backend that injects the API key server-side.

## Code Structure

Top-level layout (important folders and files)

- `lib/` — main Flutter source
  - `main.dart` — app entrypoint
  - `firebase_options.dart` — Firebase configuration (generated)
  - `screens/` — UI screens (login_screen.dart, main_screen.dart, chat, admin, doctor, etc.)
  - `services/` — service layer (Firebase wrappers, AI client wrappers, video helpers)
  - `widgets/` or shared components — reusable UI components (may be present)
- `assets/` — static resources (e.g., `assets/videos/`)
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` — platform folders
- `tools/` — Node.js admin scripts
- `test/` — unit/widget tests (e.g., `widget_test.dart`)

How pieces interact
- UI screens call into `services/` for data and actions. Services abstract Firestore reads/writes and AI calls. Business logic should be kept out of widgets for testability.

## API Documentation (Firebase + App-level)

This project primarily uses Firebase and client-side SDKs. There is no documented separate REST API in the repository. Below documents the primary Firestore collections and client operations (assumptions based on repository structure and typical patterns):

Collections (assumed)
- `users` — user profiles and roles
  - fields: `uid`, `displayName`, `email`, `role`, `createdAt`
- `chats` — conversation records
  - fields: `chatId`, `userId`, `messages` (array of message objects), `updatedAt`
- `exercises` — content for exercise screens
  - fields: `exerciseId`, `title`, `description`, `mediaRefs`
- `videos` — reference metadata for videos in `assets/videos/`

Sample Firestore read (Dart)

```dart
final snapshot = await FirebaseFirestore.instance
  .collection('chats')
  .where('userId', isEqualTo: uid)
  .orderBy('updatedAt', descending: true)
  .get();
```

Sample chat generation flow (high-level)
1. App sends user prompt to a service class (e.g., `AiService.sendPrompt`).
2. Service forwards prompt to Google Generative AI SDK or backend proxy.
3. AI response is returned and appended to the `chats` document in Firestore.

Notes & assumptions
- If your project includes a backend proxy or BFF, add its endpoints and request/response contracts here. The repository currently contains Node scripts under `tools/` for admin tasks but no dedicated API server.

## Error Handling & Logging

Client-side error handling
- Use try/catch around asynchronous calls (Firebase, AI SDK, video playback).
- Surface user-friendly messages with `fluttertoast` or dialog widgets.

Logging
- During development, use `print()` for quick logs and `dart:developer`'s `log()` for structured messages.
- Integrate a remote logging service (Sentry, Firebase Crashlytics) for production crash reporting and diagnostics.

Example pattern (Dart)

```dart
try {
  final resp = await AiService.sendPrompt(prompt);
} catch (e, st) {
  // local notification
  Fluttertoast.showToast(msg: 'Something went wrong');
  // log
  developer.log('AI request failed', error: e, stackTrace: st);
  // optionally send to remote error tracker
}
```

## Testing

Test strategy
- Unit tests for pure logic and service classes.
- Widget tests for critical UI flows (authentication, chat, main screen).
- Integration tests for end-to-end flows (optional; requires device/emulator and test accounts).

Run tests

```powershell
flutter test
```

Notes
- The repo includes `test/widget_test.dart` as a starting point.
- Mock Firebase and AI responses when running unit tests; use packages like `cloud_firestore_mocks` or create interfaces you can swap with fake implementations.

## Deployment Instructions

Android (APK / AAB)

```powershell
# debug
flutter build apk

# release
flutter build apk --release

# or build app bundle
flutter build appbundle --release
```

iOS
- Requires macOS and proper Apple Developer provisioning:
  - `flutter build ios --release`
  - Archive from Xcode and upload to App Store Connect.

Web (Firebase Hosting example)

```powershell
flutter build web
firebase deploy --only hosting
```

CI/CD recommendations
- Use GitHub Actions or other CI to run `flutter analyze`, `flutter test`, and `flutter build` on merges to main.
- Store secrets (API keys, Firebase service account keys) in the CI secret store and inject via environment variables or build-time `--dart-define`.

## Maintenance Notes

Troubleshooting
- If Firebase features fail, confirm `lib/firebase_options.dart` matches your Firebase project and the platform-specific `google-services.json` / `GoogleService-Info.plist` are present.
- For AI failures, check the API key, quota, and whether calls are being made directly from client or proxied.

Updating dependencies
- Update `pubspec.yaml` dependencies and run `flutter pub upgrade --major-versions` to test major updates.
- Run `flutter analyze` and `flutter test` after updates.

Database migrations
- Use Firestore-managed migration scripts in `tools/` when bulk updates are required (the repo includes migration scripts such as `migrateUsersCollection.js` and `backfillUsers.js`).

Backups
- Export Firestore using scheduled automated exports or Firestore export tools.

Contact and ownership
- Repository owner: `zo-beep`
- For permissions and production credentials, contact the project owner or the DevOps lead managing Firebase/GCP access.

---

If you'd like, I can also:
- Add a small CI workflow example (GitHub Actions) for linting/testing/building.
- Generate a minimal secure backend stub that proxies Gemini requests (recommended for production).

End of document.
