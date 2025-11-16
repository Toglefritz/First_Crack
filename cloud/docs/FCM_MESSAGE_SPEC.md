# FCM Message Specification

This document provides a complete specification of the Firebase Cloud Messaging (FCM) message
structure used by First Crack. Understanding this structure is essential for implementing rich
notification rendering in the Flutter app's platform-specific extensions.

## Overview

First Crack uses **data messages** rather than notification messages. This approach provides
complete control over how notifications are rendered on each platform through:

- **iOS/macOS**: Notification Service Extension + Notification Content Extension
- **Android**: FirebaseMessagingService + custom NotificationCompat layouts
- **Web**: Service Worker with Push API

## Message Structure

### Complete FCM Message

```typescript
{
  token: string,              // Device FCM token
  data: {                     // All fields are strings (FCM requirement)
    // Core notification fields
    type: string,
    stage: string,
    brewId: string,
    title: string,
    body: string,
    
    // Media fields
    imageUrl?: string,
    videoUrl?: string,
    
    // Interaction fields
    actions?: string,         // JSON-encoded array
    deepLink?: string,
    progress?: string,        // "0" to "100"
    
    // Brew parameters
    brewType: string,
    dose: string,
    temperature: string,
    pressure: string,
    elapsedTime: string,
    remainingTime?: string,
    flowRate?: string,
    volumeExtracted?: string
  },
  
  // Platform-specific configurations
  android: { ... },
  apns: { ... },
  webpush: { ... }
}
```

## Data Payload Fields

All fields in the `data` object are **strings** (FCM requirement). Parse them appropriately in your
app.

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Notification type: `"brew_stage"`, `"brew_alert"`, or `"brew_complete"` |
| `stage` | string | Yes | Current brew stage (see Brew Stages section) |
| `brewId` | string | Yes | Unique identifier for this brew (e.g., `"brew_1234567890_5678"`) |
| `title` | string | Yes | Notification title |
| `body` | string | Yes | Notification body text |

### Media Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `imageUrl` | string | No | Full URL to notification image (JPEG/PNG, recommended: 1200x600px) |
| `videoUrl` | string | No | Full URL to notification video (MP4, recommended: < 5MB) |

**Media URLs** point to publicly accessible resources. In production, use a CDN with proper caching
headers.

### Interaction Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `actions` | string | No | JSON-encoded array of action objects (see Actions section) |
| `deepLink` | string | No | Deep link URL (e.g., `"firstcrack://brew/status"`) |
| `progress` | string | No | Progress percentage as string: `"0"` to `"100"` |

### Brew Parameter Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `brewType` | string | Yes | Brew type: `"espresso"`, `"lungo"`, `"ristretto"`, or `"americano"` |
| `dose` | string | Yes | Coffee dose in grams (e.g., `"18"`) |
| `temperature` | string | Yes | Water temperature in Celsius (e.g., `"93"`) |
| `pressure` | string | Yes | Extraction pressure in bars (e.g., `"9"`) |
| `elapsedTime` | string | Yes | Elapsed time since brew start in seconds (e.g., `"45"`) |
| `remainingTime` | string | No | Estimated remaining time in seconds (e.g., `"15"`) |
| `flowRate` | string | No | Current flow rate in ml/s (e.g., `"2.5"`) - extraction stages only |
| `volumeExtracted` | string | No | Total volume extracted in ml (e.g., `"28"`) - extraction stages only |

## Brew Stages

The `stage` field indicates the current brew stage:

| Stage | Description | Category | Typical Actions |
|-------|-------------|----------|-----------------|
| `heating` | Machine is heating water | - | None |
| `grinding` | Grinding fresh coffee beans | - | None |
| `preInfusion` | Pre-infusion, saturating coffee puck | - | None |
| `brewing` | Active extraction | `BREW_EXTRACTION` | View Live, Stop Now |
| `complete` | Brew finished | `BREW_COMPLETE` | View Details, Brew Again, Share |

## Notification Categories

Notification categories enable action buttons on iOS/macOS. The `category` field in the APNS payload must match a category configured in the app's AppDelegate.

### Available Categories

| Category | When to Use | Actions |
|----------|-------------|---------|
| `BREW_EXTRACTION` | Coffee is actively extracting | View Live, Stop Now |
| `BREW_COMPLETE` | Brew has finished successfully | View Details, Brew Again, Share |

### Category Mapping

Use this mapping in your backend to automatically set the correct category:

```typescript
function getCategoryForStage(stage: string): string | undefined {
  const categoryMap: Record<string, string> = {
    'brewing': 'BREW_EXTRACTION',
    'complete': 'BREW_COMPLETE'
  };
  return categoryMap[stage];
}
```

**Note:** Only stages with interactive actions need a category. Other stages (heating, grinding, preInfusion)
should not include a category field.

## Actions Structure

The `actions` field contains a JSON-encoded array of action objects:

```json
[
  {
    "id": "start_brew",
    "title": "Start Brew",
    "icon": "play",
    "requiresForeground": false,
    "deepLink": "firstcrack://brew/start",
    "data": {
      "key": "value"
    }
  }
]
```

### Action Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique action identifier |
| `title` | string | Yes | Button text |
| `icon` | string | No | Icon name (platform-specific mapping required) |
| `requiresForeground` | boolean | No | Whether action requires app to be in foreground |
| `deepLink` | string | No | Deep link to navigate to when action is tapped |
| `data` | object | No | Additional data to pass with the action |

### Parsing Actions in Your App

**Dart example:**
```dart
import 'dart:convert';

List<NotificationAction> parseActions(String? actionsJson) {
  if (actionsJson == null) return [];
  
  final List<dynamic> actionsList = jsonDecode(actionsJson);
  return actionsList.map((action) => NotificationAction.fromJson(action)).toList();
}
```

## Platform-Specific Configurations

### Android Configuration

```typescript
android: {
  priority: "high" | "normal",
  notification: {
    title: string,
    body: string,
    imageUrl?: string,
    channelId: "brew_notifications",
    priority: "high" | "default" | "low",
    sound: "default",
    tag: string  // e.g., "brew_1234567890_5678"
  }
}
```

**Android Implementation Notes:**
- Create notification channel with ID `"brew_notifications"` in your app
- Use `tag` to update existing notifications for the same brew
- Download images in `FirebaseMessagingService` before showing notification
- Use `NotificationCompat.Builder` with custom layouts for rich content

### iOS/macOS APNS Configuration

```typescript
apns: {
  headers: {
    "apns-priority": "10" | "5",
    "apns-push-type": "alert"
  },
  payload: {
    aps: {
      alert: {
        title: string,
        body: string
      },
      sound: "default",
      badge: 1,
      "mutable-content": 1,  // Enables Notification Service Extension
      category?: string      // Notification category: "BREW_EXTRACTION" or "BREW_COMPLETE"
    }
  }
}
```

**iOS/macOS Implementation Notes:**
- `"mutable-content": 1` triggers your Notification Service Extension
- Download media in the service extension before displaying
- Use `category` to define action buttons (configured in app)
- Notification Content Extension provides custom expanded UI

### Web Push Configuration

```typescript
webpush: {
  notification: {
    title: string,
    body: string,
    icon: string,      // e.g., "/icons/icon-192.png"
    image?: string,
    badge: string,     // e.g., "/icons/badge-72.png"
    requireInteraction?: boolean
  },
  fcmOptions: {
    link?: string      // Deep link
  }
}
```

**Web Implementation Notes:**
- Handle in Service Worker's `push` event listener
- Use `showNotification()` to display
- Handle clicks in `notificationclick` event
- `requireInteraction` keeps notification visible until user interacts

## Example Messages

### Stage 1: Heating

```json
{
  "token": "fGcI8xKLRZe...",
  "data": {
    "type": "brew_stage",
    "stage": "heating",
    "brewId": "brew_1234567890_5678",
    "title": "Heating Water",
    "body": "Your espresso machine is heating to the perfect temperature...",
    "imageUrl": "https://cdn.example.com/images/machine-heating.jpg",
    "deepLink": "firstcrack://brew/status",
    "progress": "10",
    "brewType": "espresso",
    "dose": "18",
    "temperature": "93",
    "pressure": "9",
    "elapsedTime": "0"
  }
}
```

### Stage 2: Grinding

```json
{
  "token": "fGcI8xKLRZe...",
  "data": {
    "type": "brew_stage",
    "stage": "grinding",
    "brewId": "brew_1234567890_5678",
    "title": "Grinding Beans",
    "body": "Grinding fresh coffee beans to the perfect particle size...",
    "imageUrl": "https://cdn.example.com/images/grinding.png",
    "deepLink": "firstcrack://brew/grinding",
    "progress": "40",
    "brewType": "espresso",
    "dose": "18",
    "temperature": "93",
    "pressure": "9",
    "elapsedTime": "30"
  }
}
```

### Stage 4: Brewing (with Video and Actions)

```json
{
  "token": "fGcI8xKLRZe...",
  "data": {
    "type": "brew_stage",
    "stage": "brewing",
    "brewId": "brew_1234567890_5678",
    "title": "Brewing",
    "body": "Extracting espresso at 9 bar. Beautiful crema forming...",
    "imageUrl": "https://cdn.example.com/images/brewing.png",
    "videoUrl": "https://cdn.example.com/videos/extraction-live.mp4",
    "actions": "[{\"id\":\"view_live\",\"title\":\"View Live\",\"icon\":\"videocam\",\"requiresForeground\":true,\"deepLink\":\"firstcrack://brew/live\"},{\"id\":\"stop_early\",\"title\":\"Stop Now\",\"icon\":\"stop\",\"requiresForeground\":false}]",
    "deepLink": "firstcrack://brew/brewing",
    "progress": "80",
    "brewType": "espresso",
    "dose": "18",
    "temperature": "93",
    "pressure": "9",
    "elapsedTime": "45",
    "remainingTime": "30",
    "flowRate": "2.5",
    "volumeExtracted": "15"
  }
}
```

### Stage 5: Complete

```json
{
  "token": "fGcI8xKLRZe...",
  "data": {
    "type": "brew_complete",
    "stage": "complete",
    "brewId": "brew_1234567890_5678",
    "title": "Your Espresso is Ready! ☕",
    "body": "Perfect extraction: 36ml in 28s at 93°C. Enjoy!",
    "imageUrl": "https://cdn.example.com/images/brew_complete.png",
    "actions": "[{\"id\":\"view_details\",\"title\":\"View Details\",\"icon\":\"info\",\"requiresForeground\":true,\"deepLink\":\"firstcrack://brew/details\"},{\"id\":\"brew_again\",\"title\":\"Brew Again\",\"icon\":\"refresh\",\"requiresForeground\":false,\"deepLink\":\"firstcrack://brew/new\"},{\"id\":\"share\",\"title\":\"Share\",\"icon\":\"share\",\"requiresForeground\":true,\"deepLink\":\"firstcrack://brew/share\"}]",
    "deepLink": "firstcrack://brew/complete",
    "progress": "100",
    "brewType": "espresso",
    "dose": "18",
    "temperature": "93",
    "pressure": "9",
    "elapsedTime": "75",
    "flowRate": "2.5",
    "volumeExtracted": "36"
  }
}
```

## Implementation Checklist

### Flutter App (Dart)

- [ ] Add `firebase_messaging` package
- [ ] Request notification permissions
- [ ] Obtain and store FCM token
- [ ] Handle foreground messages
- [ ] Parse data payload fields
- [ ] Implement deep link routing
- [ ] Handle action button taps

### iOS/macOS

- [ ] Create Notification Service Extension target
- [ ] Download media in service extension
- [ ] Modify notification content
- [ ] Create Notification Content Extension (optional)
- [ ] Define notification categories and actions
- [ ] Handle action responses in app delegate

### Android

- [ ] Create `FirebaseMessagingService` subclass
- [ ] Create notification channel
- [ ] Download media before showing notification
- [ ] Build custom notification layout
- [ ] Add action buttons with PendingIntents
- [ ] Handle action responses in activity

### Web

- [ ] Create Service Worker
- [ ] Handle `push` event
- [ ] Call `showNotification()`
- [ ] Handle `notificationclick` event
- [ ] Implement action button handlers

## Testing

### Test with Firebase Console

1. Go to Firebase Console > Cloud Messaging
2. Send a test message
3. Use "Custom data" to add fields from this spec
4. Send to your device token

### Test with cURL

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_TOKEN",
      "data": {
        "type": "brew_stage",
        "stage": "heating",
        "brewId": "test_123",
        "title": "Test Notification",
        "body": "Testing rich notifications",
        "brewType": "espresso",
        "dose": "18",
        "temperature": "93",
        "pressure": "9",
        "elapsedTime": "0"
      }
    }
  }'
```

## Best Practices

1. **Always validate data fields** - They're strings, parse them safely
2. **Handle missing optional fields** - Check for null/undefined
3. **Download media asynchronously** - Don't block notification display
4. **Implement timeouts** - Media downloads should timeout after 5-10 seconds
5. **Cache media** - Avoid re-downloading the same images
6. **Test on all platforms** - Rendering differs significantly
7. **Handle errors gracefully** - Show notification even if media fails to load
8. **Respect user preferences** - Honor notification settings and DND mode

## Troubleshooting

**Notifications not appearing:**
- Check FCM token is valid and current
- Verify notification permissions are granted
- Check platform-specific logs (Xcode, Logcat, browser console)

**Media not loading:**
- Verify URLs are publicly accessible
- Check CORS headers for web
- Ensure HTTPS for all media URLs
- Check file sizes (keep under 5MB)

**Actions not working:**
- Verify action parsing logic
- Check deep link URL scheme is registered
- Ensure action handlers are implemented

## Further Reading

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [iOS Notification Service Extension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)
- [Web Push API](https://developer.mozilla.org/en-US/docs/Web/API/Push_API)
