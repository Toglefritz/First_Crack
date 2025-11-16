# First Crack Notifications

Complete guide to the notification system implementation across all platforms.

## Platform Overview

First Crack implements rich, interactive notifications across three platforms:

- **iOS/macOS** - Native Notification Service Extension + AppDelegate categories
- **Android** - FirebaseMessagingService + NotificationCompat with custom layouts
- **Web** - Service Worker + Push API with notification actions

Each platform has its own approach to rich notifications, but all share the same FCM data payload structure.

---

## iOS/macOS Architecture

```
┌─────────────────────────────────────────────────────────┐
│  FCM Backend (Cloud Functions)                          │
│  - Sends data messages with brew updates                │
│  - Includes category field for action buttons           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  macOS System                                           │
│  - Receives notification with mutable-content: 1        │
│  - Launches Notification Service Extension              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Notification Service Extension                         │
│  - Downloads media (images/videos)                      │
│  - Enhances notification with brew details              │
│  - Attaches media to notification                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  iOS/macOS Notification Center                              │
│  - Displays rich notification with media                │
│  - Shows action buttons based on category               │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼ (user taps action)
┌─────────────────────────────────────────────────────────┐
│  AppDelegate (Main App)                                 │
│  - Handles action button taps                           │
│  - Sends deep link to Flutter via method channel        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Flutter App                                            │
│  - Receives deep link via method channel                │
│  - Navigates to appropriate screen                      │
└─────────────────────────────────────────────────────────┘
```

### Components

#### 1. Notification Service Extension
**File:** `FirstCrackNotificationServiceExtension/NotificationService.swift`

**Purpose:** Intercepts notifications and enhances them before display

**Features:**
- Downloads and attaches media (images/videos)
- Parses FCM data payload
- Enhances notification text with brew details
- Adds subtitle with brew parameters

#### 2. AppDelegate
**File:** `Runner/AppDelegate.swift`

**Purpose:** Configures notification categories and handles user interactions

**Features:**
- Defines 3 notification categories with action buttons
- Handles action button taps
- Sends deep links to Flutter via method channel
- Shows notifications even when app is in foreground

#### 3. Notification Categories

##### BREW_READY
- Start Brew
- Adjust Temp
- Cancel

##### BREW_EXTRACTION
- View Live
- Stop Now

##### BREW_COMPLETE
- View Details
- Brew Again
- Share

---

## Android Architecture

```
┌─────────────────────────────────────────────────────────┐
│  FCM Backend (Cloud Functions)                          │
│  - Sends data messages with brew updates                │
│  - Includes Android-specific configuration              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Android System (FCM)                                   │
│  - Receives notification via Firebase SDK               │
│  - Wakes FirebaseMessagingService                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  FirebaseMessagingService                               │
│  - onMessageReceived() called with data payload         │
│  - Downloads media asynchronously                       │
│  - Builds custom notification layout                    │
│  - Creates NotificationCompat.Builder                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  NotificationCompat.Builder                             │
│  - Sets title, body, subtitle                           │
│  - Attaches downloaded image (BigPictureStyle)          │
│  - Adds action buttons with PendingIntents              │
│  - Sets notification channel (brew_notifications)       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Android Notification Manager                           │
│  - Displays notification with rich media                │
│  - Shows action buttons                                 │
│  - Handles notification updates (same tag)              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼ (user taps action)
┌─────────────────────────────────────────────────────────┐
│  MainActivity / BroadcastReceiver                       │
│  - Receives action intent                               │
│  - Extracts action ID and brew data                     │
│  - Sends to Flutter via method channel                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Flutter App                                            │
│  - Receives action via method channel                   │
│  - Navigates to appropriate screen                      │
└─────────────────────────────────────────────────────────┘
```

### Android Components

#### 1. FirebaseMessagingService
**File:** `android/app/src/main/kotlin/.../MyFirebaseMessagingService.kt`

**Purpose:** Receives FCM messages and builds rich notifications

**Key Methods:**
```kotlin
override fun onMessageReceived(remoteMessage: RemoteMessage) {
    // Parse FCM data payload
    val data = remoteMessage.data
    val stage = data["stage"]
    val brewId = data["brewId"]
    
    // Download media if present
    val imageUrl = data["imageUrl"]
    val bitmap = downloadImage(imageUrl)
    
    // Build notification
    val notification = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle(data["title"])
        .setContentText(data["body"])
        .setSubText("${data["brewType"]} • ${data["dose"]}g @ ${data["temperature"]}°C")
        .setLargeIcon(bitmap)
        .setStyle(NotificationCompat.BigPictureStyle()
            .bigPicture(bitmap))
        .addAction(createAction("start_brew", "Start Brew"))
        .build()
    
    notificationManager.notify(brewId.hashCode(), notification)
}
```

#### 2. Notification Channel
**Setup:** Required for Android 8.0+

```kotlin
private fun createNotificationChannel() {
    val channel = NotificationChannel(
        "brew_notifications",
        "Brew Notifications",
        NotificationManager.IMPORTANCE_HIGH
    ).apply {
        description = "Notifications for brew status updates"
        enableLights(true)
        enableVibration(true)
    }
    
    notificationManager.createNotificationChannel(channel)
}
```

#### 3. Action Buttons
**Implementation:** PendingIntents with action identifiers

```kotlin
private fun createAction(actionId: String, title: String): NotificationCompat.Action {
    val intent = Intent(this, NotificationActionReceiver::class.java).apply {
        action = actionId
        putExtra("brewId", brewId)
    }
    
    val pendingIntent = PendingIntent.getBroadcast(
        this, 
        actionId.hashCode(),
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    
    return NotificationCompat.Action.Builder(
        getActionIcon(actionId),
        title,
        pendingIntent
    ).build()
}
```

#### 4. Action Handler
**File:** `NotificationActionReceiver.kt`

```kotlin
class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val actionId = intent.action
        val brewId = intent.getStringExtra("brewId")
        
        // Send to Flutter via method channel
        when (actionId) {
            "start_brew" -> sendToFlutter("firstcrack://brew/start")
            "view_live" -> sendToFlutter("firstcrack://brew/live")
            "stop_early" -> sendToFlutter("firstcrack://brew/stop")
            // ... etc
        }
    }
}
```

### Android Features

**Rich Media:**
- BigPictureStyle for large images
- MediaStyle for video thumbnails
- Custom RemoteViews for advanced layouts

**Action Buttons:**
- Up to 3 actions per notification
- Icons and text labels
- PendingIntents for handling taps

**Notification Updates:**
- Use same tag to update existing notification
- Progress indicators for extraction
- Expandable/collapsible content

**Channels:**
- Separate channel for brew notifications
- User-configurable importance and sound
- LED color and vibration patterns

---

## Web Architecture

```
┌─────────────────────────────────────────────────────────┐
│  FCM Backend (Cloud Functions)                          │
│  - Sends data messages with brew updates                │
│  - Includes webpush configuration                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Browser Push Service                                   │
│  - Receives push message from FCM                       │
│  - Wakes Service Worker                                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Service Worker (sw.js)                                 │
│  - push event listener triggered                        │
│  - Parses FCM data payload                              │
│  - Fetches media if needed (optional)                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  showNotification() API                                 │
│  - Creates notification with title, body, icon          │
│  - Sets image for rich media                            │
│  - Defines action buttons                               │
│  - Sets badge, tag, and other options                   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Browser Notification System                            │
│  - Displays notification (OS-specific UI)               │
│  - Shows action buttons                                 │
│  - Handles notification persistence                     │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼ (user taps action or notification)
┌─────────────────────────────────────────────────────────┐
│  Service Worker (notificationclick event)               │
│  - Identifies which action was clicked                  │
│  - Opens or focuses app window                          │
│  - Navigates to appropriate route                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Flutter Web App                                        │
│  - Receives navigation from Service Worker              │
│  - Displays appropriate screen                          │
└─────────────────────────────────────────────────────────┘
```

### Web Components

#### 1. Service Worker Registration
**File:** `web/firebase-messaging-sw.js`

```javascript
// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/9.x.x/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.x.x/firebase-messaging-compat.js');

// Initialize Firebase
firebase.initializeApp({
  apiKey: "...",
  projectId: "...",
  messagingSenderId: "...",
  appId: "..."
});

const messaging = firebase.messaging();
```

#### 2. Push Event Handler
**Receives and displays notifications**

```javascript
self.addEventListener('push', function(event) {
  if (!event.data) return;
  
  // Parse FCM data
  const data = event.data.json();
  const payload = data.data;
  
  // Extract brew information
  const title = payload.title || 'First Crack';
  const body = payload.body || '';
  const stage = payload.stage;
  const brewId = payload.brewId;
  
  // Build notification options
  const options = {
    body: body,
    icon: '/icons/icon-192.png',
    badge: '/icons/badge-72.png',
    image: payload.imageUrl,
    tag: `brew_${brewId}`,  // Updates existing notification
    requireInteraction: stage === 'ready' || stage === 'brew_complete',
    data: {
      brewId: brewId,
      stage: stage,
      deepLink: payload.deepLink
    },
    actions: getActionsForStage(stage)
  };
  
  // Show notification
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});
```

#### 3. Action Definitions
**Stage-specific action buttons**

```javascript
function getActionsForStage(stage) {
  switch (stage) {
    case 'ready':
      return [
        { action: 'start_brew', title: '▶️ Start Brew' },
        { action: 'adjust_temp', title: '🌡️ Adjust Temp' },
        { action: 'cancel', title: '❌ Cancel' }
      ];
    
    case 'extraction_progress':
      return [
        { action: 'view_live', title: '📹 View Live' },
        { action: 'stop_early', title: '🛑 Stop Now' }
      ];
    
    case 'brew_complete':
      return [
        { action: 'view_details', title: 'ℹ️ View Details' },
        { action: 'brew_again', title: '🔄 Brew Again' },
        { action: 'share', title: '📤 Share' }
      ];
    
    default:
      return [];
  }
}
```

#### 4. Notification Click Handler
**Handles action button and notification taps**

```javascript
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  
  const action = event.action;
  const data = event.notification.data;
  const brewId = data.brewId;
  
  // Determine target URL based on action
  let targetUrl = '/';
  
  if (action) {
    // Action button was clicked
    switch (action) {
      case 'start_brew':
        targetUrl = '/brew/start';
        break;
      case 'view_live':
        targetUrl = `/brew/${brewId}/live`;
        break;
      case 'stop_early':
        targetUrl = `/brew/${brewId}/stop`;
        break;
      case 'view_details':
        targetUrl = `/brew/${brewId}/details`;
        break;
      case 'brew_again':
        targetUrl = '/brew/new';
        break;
      case 'share':
        targetUrl = `/brew/${brewId}/share`;
        break;
    }
  } else {
    // Notification body was clicked
    targetUrl = data.deepLink || `/brew/${brewId}`;
  }
  
  // Open or focus app window
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then(function(clientList) {
        // Check if app is already open
        for (let client of clientList) {
          if (client.url.includes(targetUrl) && 'focus' in client) {
            return client.focus();
          }
        }
        
        // Open new window
        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
      })
  );
});
```

### Web Features

**Rich Media:**
- `icon` - Small icon (192x192px recommended)
- `badge` - Monochrome badge for notification tray (72x72px)
- `image` - Large hero image displayed in notification

**Action Buttons:**
- Up to 2 actions on mobile browsers
- Up to 4 actions on desktop browsers
- Text labels with optional emoji icons

**Notification Options:**
- `tag` - Updates existing notification with same tag
- `requireInteraction` - Keeps notification visible until user interacts
- `silent` - No sound or vibration
- `vibrate` - Custom vibration pattern
- `timestamp` - Display time

**Browser Support:**
- Chrome/Edge: Full support
- Firefox: Full support
- Safari: Limited support (no actions on iOS)

**Permissions:**
- Must request notification permission
- User can revoke at any time
- Check permission status before showing

---

## Platform Comparison

| Feature | iOS/macOS | Android | Web |
|---------|-----------|---------|-----|
| **Rich Media** | Images, Videos | Images, Videos | Images only |
| **Action Buttons** | 3 per notification | 3 per notification | 2-4 per notification |
| **Custom UI** | Content Extension | RemoteViews | Limited |
| **Background Processing** | Service Extension | MessagingService | Service Worker |
| **Media Download** | Automatic | Manual | Manual |
| **Notification Updates** | By ID | By tag | By tag |
| **Deep Links** | URL Schemes | Intents | URLs |
| **Permissions** | System prompt | System prompt | Browser prompt |

## Common FCM Data Payload

All platforms receive the same data payload structure:

```json
{
  "type": "brew_stage",
  "stage": "extraction_progress",
  "brewId": "brew_123",
  "title": "Extraction in Progress",
  "body": "Beautiful crema forming",
  "imageUrl": "https://cdn.example.com/image.jpg",
  "brewType": "espresso",
  "dose": "18",
  "temperature": "93",
  "pressure": "9",
  "elapsedTime": "60",
  "flowRate": "2.5",
  "volumeExtracted": "15"
}
```

Each platform then:
1. Parses this data
2. Downloads media if needed
3. Builds platform-specific notification
4. Displays with appropriate UI
5. Handles user interactions

--
-

## Setup Checklist

### iOS/macOS Native (Complete ✅)
- [x] Notification Service Extension implemented
- [x] Media download and attachment
- [x] Content enhancement
- [x] Notification categories configured
- [x] Action handlers implemented
- [x] Method channel for Flutter communication

### Android Native (TODO)
- [ ] Create FirebaseMessagingService subclass
- [ ] Implement onMessageReceived handler
- [ ] Create notification channel
- [ ] Build NotificationCompat with actions
- [ ] Download and attach media
- [ ] Create NotificationActionReceiver
- [ ] Set up method channel for Flutter

### Web (TODO)
- [ ] Create firebase-messaging-sw.js
- [ ] Implement push event listener
- [ ] Implement notificationclick handler
- [ ] Define action buttons per stage
- [ ] Handle window focus/open logic
- [ ] Request notification permissions
- [ ] Register service worker

### Flutter App (TODO)
- [ ] Set up method channel handler (iOS/macOS/Android)
- [ ] Implement deep link routing
- [ ] Handle notification actions
- [ ] Request notification permissions (all platforms)
- [ ] Register FCM token
- [ ] Handle foreground notifications

### Backend (Complete ✅)
- [x] Add `category` field to FCM messages
- [x] Map brew stages to categories
- [x] Configure Android-specific payload
- [x] Configure webpush payload
- [x] Test with all notification types

---

## Implementation Priority

### Phase 1: iOS/macOS (Complete ✅)
Rich notifications with action buttons fully implemented and tested.

### Phase 2: Android (Recommended Next)
Similar architecture to iOS/macOS. Implement:
1. FirebaseMessagingService for message handling
2. NotificationCompat for rich notifications
3. Action buttons with PendingIntents
4. Method channel integration with Flutter

### Phase 3: Web
Browser-based notifications with Service Worker. Implement:
1. Service Worker registration
2. Push event handling
3. Notification display with actions
4. Click handling and navigation

### Phase 4: Flutter Integration
Unified notification handling across all platforms:
1. Method channel handlers for native platforms
2. Deep link routing system
3. Notification permission management
4. FCM token registration and management

---

## Testing Strategy

### Per-Platform Testing

**iOS/macOS:**
```bash
# Send test notification
curl -X POST http://localhost:3000/brew/start \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "YOUR_IOS_TOKEN",
    "brewType": "espresso",
    "dose": 18,
    "targetTemp": 93,
    "targetPressure": 9
  }'
```

**Android:**
```bash
# Same endpoint, different token
curl -X POST http://localhost:3000/brew/start \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "YOUR_ANDROID_TOKEN",
    "brewType": "espresso",
    "dose": 18,
    "targetTemp": 93,
    "targetPressure": 9
  }'
```

**Web:**
```bash
# Same endpoint, web token
curl -X POST http://localhost:3000/brew/start \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "YOUR_WEB_TOKEN",
    "brewType": "espresso",
    "dose": 18,
    "targetTemp": 93,
    "targetPressure": 9
  }'
```

### Cross-Platform Verification

Test each brew stage on all platforms:

| Stage | Time | Expected Notification | Actions |
|-------|------|----------------------|---------|
| heating | 0s | "Heating Water" | None |
| ready | 30s | "Ready to Brew" | 3 actions |
| preinfusion_start | 35s | "Pre-infusion Started" | None |
| preinfusion_complete | 50s | "Pre-infusion Complete" | None |
| extraction_progress | 60s | "Extraction in Progress" | 2 actions |
| extraction_complete | 80s | "Extraction Complete" | None |
| brew_complete | 90s | "Your Espresso is Ready!" | 3 actions |

### Action Button Testing

For each platform, verify:
1. Action buttons appear correctly
2. Tapping action opens app (if foreground action)
3. Correct deep link is triggered
4. App navigates to correct screen
5. Console shows correct action identifier

---

## Documentation

### Platform-Specific Docs

**iOS/macOS:**
- `macos/NOTIFICATION_CATEGORIES.md` - Category configuration
- `macos/README_NOTIFICATIONS.md` - Architecture overview
- `macos/FirstCrackNotificationServiceExtension/NotificationService.swift` - Fully documented

**Android:**
- TBD: `android/NOTIFICATION_SETUP.md`
- TBD: `android/app/src/main/kotlin/.../MyFirebaseMessagingService.kt`

**Web:**
- TBD: `web/SERVICE_WORKER_GUIDE.md`
- TBD: `web/firebase-messaging-sw.js`

**Backend:**
- `cloud/docs/FCM_MESSAGE_SPEC.md` - Complete FCM specification
- `cloud/docs/NOTIFICATION_CATEGORIES_BACKEND.md` - Backend integration
- `cloud/README_CATEGORIES.md` - Quick reference

---

## Next Steps

1. ✅ iOS/macOS implementation complete
2. ⏳ Implement Android FirebaseMessagingService
3. ⏳ Implement Web Service Worker
4. ⏳ Create Flutter method channel handlers
5. ⏳ Test end-to-end on all platforms
6. ⏳ Add analytics for notification interactions
7. ⏳ Implement notification preferences UI

---

## Resources

### Apple Documentation
- [UNNotificationServiceExtension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)
- [UNNotificationCategory](https://developer.apple.com/documentation/usernotifications/unnotificationcategory)
- [Handling Notifications](https://developer.apple.com/documentation/usernotifications/handling_notifications_and_notification-related_actions)

### Android Documentation
- [FirebaseMessagingService](https://firebase.google.com/docs/reference/android/com/google/firebase/messaging/FirebaseMessagingService)
- [NotificationCompat](https://developer.android.com/reference/androidx/core/app/NotificationCompat)
- [Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)

### Web Documentation
- [Push API](https://developer.mozilla.org/en-US/docs/Web/API/Push_API)
- [Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [Notifications API](https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API)

### Firebase Documentation
- [FCM Architecture](https://firebase.google.com/docs/cloud-messaging/concept-options)
- [Send Messages to Multiple Platforms](https://firebase.google.com/docs/cloud-messaging/send-message#send-messages-to-multiple-platforms)
- [FCM Message Structure](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
