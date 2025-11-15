# First Crack ☕

_First Crack_ is a Flutter demonstration application showcasing how to build **rich, interactive
push notification experiences** across iOS, macOS, Android, and the web. The app simulates remote
control of an automated coffee machine, exposing detailed brewing controls and receiving
interactive, media-enhanced notifications throughout each stage of the brew cycle.

This project exists as both a **technical reference** and a **practical template** for integrating
advanced notification features into Flutter applications.

## Project Structure

```
first-crack/
├── app/                    # Flutter application
│   ├── lib/               # Dart source code
│   ├── ios/               # iOS native code
│   ├── android/           # Android native code
│   ├── macos/             # macOS native code
│   ├── web/               # Web platform code
│   └── README.md          # Flutter app documentation
│
├── cloud/                 # Firebase Cloud Functions backend
│   ├── src/              # TypeScript source code
│   ├── docs/             # Backend documentation
│   └── README.md         # Backend documentation
│
├── firebase.json         # Firebase configuration
└── README.md            # This file
```

## Overview

Modern apps often rely on push notifications for more than simple text alerts. They deliver
actionable information, media, status updates, and sometimes full control flows, all without
requiring the user to open the app.

_First Crack_ demonstrates these capabilities through the lens of a fictional smart coffee machine.
The app models a realistic brewing workflow and uses push notifications to drive interactions such
as:

- Starting the brew after water reaches temperature
- Adjusting temperature or flow rate directly from a notification
- Monitoring live brewing progress
- Displaying images or short video clips during the brew
- Performing one-tap actions or quick adjustments

All notifications are triggered by a simulated backend and delivered through Firebase Cloud
Messaging (FCM), but they're rendered using **rich, platform-native interfaces**.

## What the App Demonstrates

### 1. Interactive Notifications

The app includes examples of notifications containing:

- **Interactive buttons** (e.g., "Start Brew", "Pause Flow", "Increase Temp")
- **Dynamic controls**, such as sliders or quick-select options
- **Deep links** into specific parts of the app
- **Actions that execute directly from a notification**, where supported

### 2. Media-Enhanced Notifications

Throughout the brew cycle, notifications can include media such as:

- High-resolution images of the group head
- Short video clips showing live extraction
- Step-by-step illustrations
- Animated status indicators

### 3. Cross-Platform Notification Infrastructure

Although FCM is used as the **transport layer**, each platform handles rendering differently. _First
Crack_ shows how to unify the high-level architecture while delivering a native experience on each
OS.

## How Rich Notifications Work

### Firebase Cloud Messaging (Backend Transport)

The app uses FCM to receive messages across all supported platforms. Notifications are sent using
**data messages**, which include structured metadata describing the brewing event and required
interactions.

### Platform-Specific Rendering Layers

#### iOS / macOS

- A **Notification Service Extension** fetches media, modifies content, and constructs rich
  notifications.
- A **Notification Content Extension** optionally provides a custom expanded UI.

#### Android

- FCM data messages are interpreted using:
    - a background Dart isolate or Kotlin service
    - custom `NotificationCompat` layouts
    - inline actions
    - platform media attachments

#### Web

- A Service Worker uses the **Push API** and `showNotification()` with:
    - interactive buttons
    - images and icons
    - background event handlers for click actions

#### Flutter Desktop (macOS)

- Mirrors the iOS extension-based system for notification customization.

## Coffee Machine Simulation

The fictional coffee machine exposes detailed brewing parameters:

- Brew type (espresso, lungo, ristretto, americano)
- Coffee dose (grams)
- Pre-infusion duration
- Water temperature
- Pressure targets
- Live video snapshot or media clip

Push notifications guide the user through steps such as:

- "Water heated — Start Brew?"
- "Set Your Temperature" (slider included in the notification)
- "Pre-infusion complete — Continue?"
- "Extraction in progress — view live feed"
- "Brew complete" with a final image or video

This creates a convincing example of rich and interactive push-driven workflows.

## Architecture

### Flutter App

The Flutter app follows a strict MVC (Model–View–Controller) architecture:

- **Route (Entry Point)**: Each screen has a `*_route.dart` file containing a `StatefulWidget`
- **Controller (Business Logic)**: Controllers extend `State<RouteWidget>` and contain all state
  and event handling
- **View (Presentation)**: Views are pure `StatelessWidget` classes that render UI only

See [app/README.md](app/README.md) for detailed Flutter app documentation.

### Cloud Backend

The backend is built with Firebase Cloud Functions (TypeScript) and provides:

- **HTTP Endpoint**: `/startBrew` to initiate brew simulations
- **Scheduled Notifications**: Sends 7 timed FCM messages simulating brew stages
- **Structured Data Payloads**: Rich message format for platform-specific rendering

See [cloud/README.md](cloud/README.md) for detailed backend documentation.

## Getting Started

### Prerequisites

- **Flutter SDK** 3.0 or later
- **Node.js** 20 or later
- **Firebase CLI**: `npm install -g firebase-tools`
- A Firebase project with FCM enabled

### 1. Set Up Firebase Project

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Cloud Messaging
3. Enable Cloud Functions (requires billing)
4. Download configuration files for your platforms

### 2. Deploy Cloud Backend

```bash
cd cloud
npm install
npm run deploy
```

See [cloud/docs/DEPLOYMENT.md](cloud/docs/DEPLOYMENT.md) for detailed deployment instructions.

### 3. Configure Flutter App

1. Add Firebase configuration files to the Flutter app
2. Update FCM endpoint URL in app configuration
3. Install dependencies: `flutter pub get`
4. Run the app: `flutter run`

See [app/README.md](app/README.md) for detailed Flutter setup instructions.

## How It Works

### 1. User Initiates Brew

The Flutter app calls the `/startBrew` endpoint with:
- Device FCM token
- Brew parameters (type, dose, temperature, pressure)

### 2. Backend Schedules Notifications

The Cloud Function schedules 7 notifications at specific intervals:

| Time | Stage | Description |
|------|-------|-------------|
| t+0s | Heating | Machine is heating water |
| t+30s | Ready | Ready to brew (with action buttons) |
| t+35s | Pre-infusion Start | Pre-infusion begins |
| t+50s | Pre-infusion Complete | Pre-infusion done |
| t+60s | Extraction Progress | Mid-extraction (with video) |
| t+80s | Extraction Complete | Extraction finishing |
| t+90s | Brew Complete | Brew finished (with actions) |

### 3. Platform-Specific Rendering

Each platform receives FCM data messages and renders them using native APIs:

- **iOS/macOS**: Notification Service Extension downloads media and modifies content
- **Android**: FirebaseMessagingService builds custom NotificationCompat layouts
- **Web**: Service Worker uses Push API to display rich notifications

### 4. User Interactions

Users can:
- Tap action buttons directly in notifications
- View media (images, videos) in expanded notifications
- Deep link into specific app screens
- Monitor brew progress without opening the app

## Documentation

### Backend Documentation

- [cloud/README.md](cloud/README.md) - Backend overview and quick start
- [cloud/docs/API.md](cloud/docs/API.md) - Complete API reference
- [cloud/docs/FCM_MESSAGE_SPEC.md](cloud/docs/FCM_MESSAGE_SPEC.md) - FCM message format
  specification
- [cloud/docs/DEPLOYMENT.md](cloud/docs/DEPLOYMENT.md) - Deployment guide

### Flutter App Documentation

- [app/README.md](app/README.md) - Flutter app documentation

## Key Features

### Rich Notification Content

- High-resolution images
- Video clips
- Progress indicators
- Custom layouts

### Interactive Actions

- Action buttons (Start, Stop, Adjust)
- Deep links to app screens
- Background action handling
- Foreground-only actions

### Cross-Platform Support

- iOS (Notification Service Extension + Content Extension)
- macOS (Same as iOS)
- Android (FirebaseMessagingService + custom layouts)
- Web (Service Worker + Push API)

### Realistic Simulation

- Authentic espresso machine parameters
- Timed notification sequence
- Brewing stage progression
- Media at each stage

## Development

### Local Development

**Backend:**
```bash
cd cloud
npm run serve
```

**Flutter App:**
```bash
cd app
flutter run
```

### Testing

**Test Backend Endpoint:**
```bash
curl -X POST http://localhost:5001/YOUR_PROJECT/us-central1/startBrew \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "test_token",
    "brewType": "espresso",
    "dose": 18,
    "targetTemp": 93,
    "targetPressure": 9
  }'
```

**Test Flutter App:**
```bash
cd app
flutter test
```

## Contributing

This is a demonstration project. Feel free to:
- Fork and modify for your own use cases
- Use as a reference for implementing rich notifications
- Adapt the architecture for production applications

## License

This project is provided as-is for educational and demonstration purposes.

## Support

For questions or issues:
- Review the documentation in `cloud/docs/` and `app/`
- Check Firebase documentation for platform-specific guidance
- Refer to Flutter documentation for app development

## Acknowledgments

This project demonstrates best practices for:
- Firebase Cloud Messaging integration
- Platform-specific notification rendering
- Flutter cross-platform development
- TypeScript Cloud Functions development
