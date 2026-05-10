# Olmeg Connect

Olmeg Connect is a Flutter marketplace application for buying and selling new, used, and handmade products. The codebase combines marketplace flows, social posting, chat, notifications, ratings, admin tooling, and Firebase-powered backend services in a single cross-platform app.

## Overview

The project is built with Flutter and Riverpod and uses Firebase for authentication, database, storage, messaging, hosting, and web/app platform configuration.

Main goals of the app:

- Let users browse, search, and manage products.
- Support buying and selling flows inside one app.
- Add a social/community layer through posts and feed content.
- Enable user-to-user chat and notifications.
- Provide admin moderation and broadcast capabilities.

## Current Tech Stack

### Frontend

- Flutter
- Dart SDK `>=3.0.0 <4.0.0`
- Riverpod for state management
- GoRouter for navigation
- Material UI with custom theming
- Custom localization for English and Arabic

### Firebase

- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Firebase Hosting
- Firebase Cloud Functions configuration folder

### Other Packages

- `image_picker`
- `cached_network_image`
- `shimmer`
- `gap`
- `uuid`
- `intl`
- `equatable`
- `dartz`
- `state_notifier`
- `shared_preferences`
- `timeago`
- `flutter_paypal`
- `flutter_rating_bar`

## App Features

Based on the current codebase, Olmeg Connect includes the following functional areas.

### Authentication

- Login screen
- Register screen
- Firebase-backed auth state handling
- Router redirect logic for authenticated vs unauthenticated access

### Marketplace / Products

- Product listing and browsing
- Product details
- Add product flow
- Category filtering
- Favorites
- My products
- Product cards, badges, gallery, and seller UI components
- Product moderation service hooks

### Search

- Search screen
- Advanced search screen
- Search provider, repository, and datasource layers
- Search filter entity support

### Cart and Payments

- Cart screen and cart provider
- Payment provider and repository layer
- PayPal package included in dependencies

### Social Posts

- Feed screen
- Create post screen
- Post profile screen
- Post/product matching utilities
- Image grid and preview widgets
- Reaction bar
- Enhanced post card widgets

### Chat

- Chat list screen
- Chat detail screen
- Chat provider, entity, model, and datasource layers

### Notifications

- Notifications screen
- Notification provider and repository layers
- Firebase Cloud Messaging integration
- Foreground/background notification handling service

### Ratings

- Rating entity, model, datasource, repository, provider
- Rating widget

### Profile and Settings

- User profile screen
- Edit profile screen
- Settings screen
- Favorites screen
- Privacy policy screen
- Terms of service screen
- Dark mode setting support
- Locale switching support

### Admin

- Admin dashboard
- Admin notification screen
- Admin product moderation screen

### Analytics

- Analytics service and datasource layer present in the codebase

### UI / Shell

- Main bottom navigation shell
- UI showcase screen
- Shared reusable widgets and theme helpers

## Navigation Structure

The router currently defines these main routes:

- `/login`
- `/register`
- `/home`
- `/product/:id`
- `/cart`
- `/create-post`
- `/demo`
- `/chats`
- `/chat/:id`
- `/settings`
- `/favorites`
- `/my-products`
- `/privacy-policy`
- `/terms`
- `/edit-profile`
- `/search`
- `/advanced-search`
- `/notifications`
- `/admin`
- `/admin/notify`
- `/admin/moderation`

Routing behavior:

- Unauthenticated users are redirected to `/login`.
- Authenticated users trying to access `/login` or `/register` are redirected to `/home`.

## Main Application Flow

Application entry starts in [`lib/main.dart`](/C:/flutter%20project/olmeg_connect/lib/main.dart).

Startup responsibilities:

- Ensure Flutter bindings are initialized
- Initialize Firebase using [`lib/firebase_options.dart`](/C:/flutter%20project/olmeg_connect/lib/firebase_options.dart)
- Start Riverpod `ProviderScope`
- Initialize notification services after first frame
- Load router, theme mode, and locale from providers

The main shell in [`lib/features/shell/presentation/main_shell.dart`](/C:/flutter%20project/olmeg_connect/lib/features/shell/presentation/main_shell.dart) uses an indexed bottom navigation layout for:

- Home
- Feed
- Add product
- Chat
- Notifications
- Profile

## Localization

Localization is handled in [`lib/core/localization/app_localizations.dart`](/C:/flutter%20project/olmeg_connect/lib/core/localization/app_localizations.dart).

Supported locales currently configured:

- English (`en`)
- Arabic (`ar`)

## Project Structure

High-level layout:

```text
olmeg_connect/
|- lib/
|  |- core/
|  |  |- constants/
|  |  |- errors/
|  |  |- localization/
|  |  |- router/
|  |  |- services/
|  |  |- theme/
|  |  |- utils/
|  |  `- widgets/
|  `- features/
|     |- admin/
|     |- analytics/
|     |- auth/
|     |- cart/
|     |- chat/
|     |- home/
|     |- notifications/
|     |- payments/
|     |- posts/
|     |- products/
|     |- profile/
|     |- ratings/
|     |- search/
|     |- settings/
|     `- shell/
|- test/
|- web/
|- android/
|- ios/
|- macos/
|- linux/
|- windows/
|- functions/
|- firebase.json
|- firestore.rules
|- storage.rules
`- pubspec.yaml
```

Architecture style in the feature folders is mostly layered and resembles clean architecture:

- `data`
- `domain`
- `presentation`
- feature-specific `services`, `models`, `entities`, `providers`, and `widgets`

## Important Files

- [`pubspec.yaml`](/C:/flutter%20project/olmeg_connect/pubspec.yaml): package metadata and dependencies
- [`lib/main.dart`](/C:/flutter%20project/olmeg_connect/lib/main.dart): app entry point
- [`lib/core/router/app_router.dart`](/C:/flutter%20project/olmeg_connect/lib/core/router/app_router.dart): navigation and auth redirects
- [`lib/core/services/notification_service.dart`](/C:/flutter%20project/olmeg_connect/lib/core/services/notification_service.dart): FCM setup and message handlers
- [`firebase.json`](/C:/flutter%20project/olmeg_connect/firebase.json): Firebase hosting, Firestore, Storage, and Functions config
- [`firestore.rules`](/C:/flutter%20project/olmeg_connect/firestore.rules): Firestore security rules
- [`storage.rules`](/C:/flutter%20project/olmeg_connect/storage.rules): Firebase Storage rules
- [`test/widget_test.dart`](/C:/flutter%20project/olmeg_connect/test/widget_test.dart): basic widget smoke test

## Firebase Configuration

The project is already connected to Firebase through FlutterFire config.

Configured platforms in [`firebase.json`](/C:/flutter%20project/olmeg_connect/firebase.json):

- Android
- iOS
- macOS
- Web
- Windows

Configured Firebase services:

- Hosting with `build/web` as the public output folder
- Firestore rules and indexes
- Storage rules
- Functions source directory at `functions`

### Cloud Functions

The `functions` folder currently contains:

- `package.json`
- `package-lock.json`

Configured environment:

- Node.js `20`
- `firebase-admin`
- `firebase-functions`

At the moment, no checked-in Cloud Functions source file was found in the `functions` directory root, so backend function implementation may still be pending or omitted from this repo snapshot.

## Security Notes

The current rules appear to be development-friendly and not production-safe:

### Firestore rules

[`firestore.rules`](/C:/flutter%20project/olmeg_connect/firestore.rules) currently allow:

- Read/write access to all collections for any authenticated user

### Storage rules

[`storage.rules`](/C:/flutter%20project/olmeg_connect/storage.rules) currently allow:

- Public read access
- Public write access

If this app is meant for production, these rules should be tightened before deployment.

## Development Setup

### Prerequisites

- Flutter SDK installed
- Dart SDK compatible with the Flutter version in use
- Firebase CLI installed
- A Firebase project configured for the app
- Android Studio, VS Code, or another Flutter-compatible IDE

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

To run on a specific platform:

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

### Run tests

```bash
flutter test
```

### Analyze code

```bash
flutter analyze
```

## Build and Deployment

### Web build

```bash
flutter build web
```

### Firebase Hosting deploy

```bash
firebase deploy --only hosting
```

### Firestore, Storage, and Functions deploy

```bash
firebase deploy --only firestore,storage,functions
```

### Functions local serve

```bash
cd functions
firebase emulators:start --only functions
```

## Testing Status

The repository currently includes a basic widget smoke test in [`test/widget_test.dart`](/C:/flutter%20project/olmeg_connect/test/widget_test.dart) that pumps the root app widget inside a `ProviderScope`.

Also present in the repository are several project notes and testing documents, including:

- [`TESTING_REPORT.md`](/C:/flutter%20project/olmeg_connect/TESTING_REPORT.md)
- [`TEST_REPORT.md`](/C:/flutter%20project/olmeg_connect/TEST_REPORT.md)
- [`FINAL_TEST_SUMMARY.md`](/C:/flutter%20project/olmeg_connect/FINAL_TEST_SUMMARY.md)
- [`TESTING_CHECKLIST.md`](/C:/flutter%20project/olmeg_connect/TESTING_CHECKLIST.md)

These suggest active manual tracking of implementation and QA work alongside the app code.

## Additional Project Documentation

This repository contains several supporting documents for implementation, UI work, Firebase setup, and testing, such as:

- [`IMPLEMENTATION_SUMMARY.md`](/C:/flutter%20project/olmeg_connect/IMPLEMENTATION_SUMMARY.md)
- [`IMPLEMENTATION_CHECKLIST.md`](/C:/flutter%20project/olmeg_connect/IMPLEMENTATION_CHECKLIST.md)
- [`UI_IMPROVEMENTS.md`](/C:/flutter%20project/olmeg_connect/UI_IMPROVEMENTS.md)
- [`UI_COMPONENTS_GUIDE.md`](/C:/flutter%20project/olmeg_connect/UI_COMPONENTS_GUIDE.md)
- [`HOW_TO_APPLY_FIRESTORE_RULES.md`](/C:/flutter%20project/olmeg_connect/HOW_TO_APPLY_FIRESTORE_RULES.md)
- [`FIREBASE_CONSOLE_VISUAL_GUIDE.md`](/C:/flutter%20project/olmeg_connect/FIREBASE_CONSOLE_VISUAL_GUIDE.md)
- [`COMPLETION_REPORT.md`](/C:/flutter%20project/olmeg_connect/COMPLETION_REPORT.md)

If you are onboarding to the project, those files are worth reviewing alongside this README.

## Known Observations

- The previous `README.md` had unresolved merge conflict markers and has been replaced.
- The project is under active development with many modified and untracked files in the working tree.
- The app appears to target multiple desktop and mobile platforms in addition to web.
- The `functions` directory is configured but does not currently include an `index.js` or equivalent checked-in functions entry file.
- There is a `settings.json` file in the repository root that appears environment-related and should be reviewed carefully before sharing or publishing the repo.

## Version

Current app version from [`pubspec.yaml`](/C:/flutter%20project/olmeg_connect/pubspec.yaml):

- `1.6.1`

## License

See [`LICENSE`](/C:/flutter%20project/olmeg_connect/LICENSE).
