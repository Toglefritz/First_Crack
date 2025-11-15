# First Crack ☕

_First Crack_ is a Flutter demonstration application showcasing how to build **rich, interactive
push notification experiences** across iOS, macOS, Android, and the web. The app simulates remote
control of an automated coffee machine, exposing detailed brewing controls and receiving
interactive, media-enhanced notifications throughout each stage of the brew cycle.

This project exists as both a **technical reference** and a **practical template** for integrating
advanced notification features into Flutter applications.

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
Messaging (FCM), but they’re rendered using **rich, platform-native interfaces**.

## What the App Demonstrates

### 1. Interactive Notifications

The app includes examples of notifications containing:

- **Interactive buttons** (e.g., “Start Brew”, “Pause Flow”, “Increase Temp”)
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

The app uses FCM to receive messages across all supported platforms. Notifications are sent using *
*data messages**, which include structured metadata describing the brewing event and required
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

- Brew type (espresso, pour-over, immersion, etc.)
- Coffee dose
- Pre-infusion duration
- Water flow rate curves
- Temperature profiles
- Pressure targets
- Live video snapshot or media clip

Push notifications guide the user through steps such as:

- “Water heated — Start Brew?”
- “Set Your Temperature” (slider included in the notification)
- “Pre-infusion complete — Continue?”
- “Extraction in progress — view live feed”
- “Brew complete” with a final image or video

This creates a convincing example of rich and interactive push-driven workflows.


## Architecture

_First Crack_ follows a strict MVC (Model–View–Controller) architecture:

### Route (Entry Point)

- Each screen has a `*_route.dart` file containing a `StatefulWidget`
- Routes only define screen entry points
- `createState()` returns the controller

### Controller (Business Logic)

- Controllers extend `State<RouteWidget>`
- They contain all state and event handling
- They call `setState()` to update the UI

### View (Presentation)

- Views are pure `StatelessWidget` classes
- They render UI only
- They receive the controller as a parameter
