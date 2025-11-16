# First Crack Notification Design Specification

## Overview

This document describes the notification design for the First Crack espresso machine application. The notification system transforms push notifications from passive alerts into an interactive control surface that provides real-time brew monitoring, rich media experiences, and contextual controls throughout the brewing process.

## Design Philosophy

### Core Principles

**1. Notifications as Control Surface**

Rather than simple status alerts, First Crack notifications serve as a functional interface for monitoring and controlling the brew process without requiring the user to open the app. Each notification provides relevant information and actionable controls appropriate to the current brew stage.

**2. Progressive Feature Demonstration**

The five brew stages demonstrate increasingly sophisticated notification capabilities:
- **Heating**: Basic text enrichment and progress tracking
- **Grinding**: Media attachments and stage-specific actions
- **Pre-Infusion**: Live parameter visualization and timing controls
- **Brewing**: Full interactive dashboard with multiple controls
- **Complete**: Summary presentation with reflection and next actions

**3. Context-Aware Presentation**

Notifications adapt their content, media, and available actions based on the current brew stage. Each stage provides information and controls that are relevant to that specific phase of the brewing process, creating a seamless and intuitive user experience.

## Architecture Components

### Flutter Application Layer

**PushNotificationService**
- Manages Firebase Cloud Messaging (FCM) integration
- Handles device token registration and refresh
- Processes incoming notifications across all app states
- Displays local notifications for foreground messages
- Manages notification permission requests

**NotificationData Model**
- Structured representation of FCM message payloads
- Type-safe parsing of brew parameters and metadata
- Serialization for local notification storage
- Validation of required fields

**BrewStage Enum**
- Defines the sequential stages of the brewing process
- Provides localized labels for UI display
- Supports comparison operators for stage progression
- Maps to stage-specific images and behaviors

### Firebase Cloud Messaging (FCM)

**Message Delivery**
- Delivers notifications to devices across all app states (foreground, background, terminated)
- Supports data-only messages for silent updates
- Handles message priority and time-to-live settings
- Provides delivery receipts and analytics

**Rich Media Support**
- Image attachments via URL references
- Video attachments for dynamic content
- Automatic media download and caching
- Fallback handling for failed media loads

**Interactive Actions**
- Category-based action button configuration
- Platform-specific action definitions
- Deep link integration for navigation
- Background action handling

### Platform-Specific Extensions

**iOS Notification Service Extension (NSE)**
- Intercepts notifications before display
- Downloads and attaches media content
- Enriches notification text with brew parameters
- Computes dynamic subtitles and body text
- Validates and formats data fields

**iOS Notification Content Extension**
- Provides custom UI for expanded notifications
- Displays live brew parameters and progress
- Renders interactive controls and visualizations
- Updates in real-time during active brews

**Android FirebaseMessagingService**
- Receives FCM messages in all app states
- Builds custom notification layouts
- Downloads and attaches media asynchronously
- Creates notification channels and categories
- Handles action button interactions

## Brew Stage Notification Designs

### Stage 1: Heating

**Goal**: Demonstrate basic text enrichment and progress tracking from the Notification Service Extension.

#### Collapsed Notification

**Title**: `Heating water for espresso`

**Subtitle**: `Espresso • 18g @ 93°C`
- Dynamically constructed by NSE from brew profile data
- Format: `{brewType} • {dose}g @ {temperature}°C`

**Body**: `Your First Crack machine is heating water to the target brewing temperature.`
- Static descriptive text explaining the current stage
- Optional enhancement: `About 20 seconds remaining.` (if time estimate available)

**Media**: None (text-only notification for simplicity)

#### Notification Service Extension Processing

The NSE performs the following enrichment:

1. **Parse Brew Profile**: Extract `brewType`, `dose`, `temperature` from `userInfo`
2. **Build Subtitle**: Construct formatted string with brew parameters
3. **Enhance Body**: Optionally add time remaining if `remainingTime` field present
4. **Set Category**: Assign `BREW_HEATING` category (no actions for this stage)

```swift
// Example NSE processing
let brewType = userInfo["brewType"] as? String ?? "Espresso"
let dose = userInfo["dose"] as? String ?? "18"
let temperature = userInfo["temperature"] as? String ?? "93"

bestAttemptContent.subtitle = "\(brewType) • \(dose)g @ \(temperature)°C"

if let remainingTime = userInfo["remainingTime"] as? String {
    bestAttemptContent.body += "\nAbout \(remainingTime) seconds remaining."
}
```

#### Expanded Content (Content Extension)

When the user expands the notification, the content extension displays:

**Progress Indicator**
- General progress bar showing heating stage completion
- Visual representation based on elapsed time vs expected duration
- Simple percentage display

**Brew Profile Summary**
- Brew type: Espresso
- Dose: 18g
- Target temperature: 93°C
- Target pressure: 9 bar

**Actions**
- Single action button: `Cancel Brew`
- Tapping opens app or triggers cancellation flow

#### Technical Focus

- **NSE**: Text enrichment using `userInfo` data
- **Content Extension**: Simple progress visualization
- **Demonstration**: Informative but not heavily interactive
- **User Value**: Clear status without opening app

---

### Stage 2: Grinding

**Goal**: Demonstrate media attachments and stage-specific actions via notification categories.

#### Collapsed Notification

**Title**: `Grinding beans for your shot`

**Subtitle**: `Espresso • 18g dose`
- Dynamically constructed from brew profile data
- Format: `{brewType} • {dose}g dose`

**Body**: `Fresh beans are being ground to the selected profile.`

**Media**: Still image of beans falling into the grinder
- Downloaded by NSE from `imageUrl` field
- Attached as `UNNotificationAttachment`
- Fallback to app icon if download fails

#### Notification Service Extension Processing

1. **Parse Brew Profile**: Extract `brewType`, `dose` from `userInfo`
2. **Build Subtitle**: Construct formatted string with brew parameters
3. **Download Media**: Fetch image from `imageUrl` and create attachment
4. **Set Category**: Assign `BREW_GRINDING` category for stage-specific actions

```swift
// Example NSE media download
if let imageUrlString = userInfo["imageUrl"] as? String,
   let imageUrl = URL(string: imageUrlString) {
    
    let attachment = try await downloadAndAttachMedia(
        from: imageUrl,
        options: nil
    )
    
    bestAttemptContent.attachments = [attachment]
}

bestAttemptContent.categoryIdentifier = "BREW_GRINDING"
```

#### Expanded Content (Content Extension)

**Media Display**
- Larger image of grinding process
- Fallback to static image if unavailable

**Status Label**
- `Grinding in progress`
- Progress indicator based on elapsed time
- Estimated time remaining

**Brew Parameters**
- Brew type: Espresso
- Dose: 18g
- Target temperature: 93°C
- Target pressure: 9 bar

**Actions**
- `Pause Grinding` - Temporarily stops the grinder
- `Adjust Settings` - Opens app to brew settings

#### Technical Focus

- **NSE**: Media download and attachment creation
- **Categories**: Stage-specific action buttons
- **Content Extension**: Media display with progress UI
- **Demonstration**: Rich media integration and contextual actions

---

### Stage 3: Pre-Infusion

**Goal**: Display live parameters from `userInfo` and demonstrate how the content extension can visualize a short phase with limited controls.

#### Collapsed Notification

**Title**: `Pre-infusion in progress`

**Subtitle**: `Espresso • 18g @ 2 bar`
- Format: `{brewType} • {dose}g @ {pressure} bar`
- Shows current pressure during pre-infusion

**Body**: `Gently saturating the coffee puck for even extraction.`
- Optional enhancement: `Pre-infusion: 4 / 8 seconds.`

**Media**: None (focus on text and timing information)

#### Notification Service Extension Processing

1. **Parse Pre-Infusion Parameters**: Extract `pressure`, `preInfusionTime`, `elapsedTime`
2. **Build Subtitle**: Include current pressure reading
3. **Enhance Body**: Add timing information if available
4. **Set Category**: Assign `BREW_PREINFUSION` category

```swift
// Example NSE processing
let pressure = userInfo["pressure"] as? String ?? "2"
let elapsedTime = userInfo["elapsedTime"] as? String ?? "0"
let preInfusionTime = userInfo["preInfusionTime"] as? String ?? "8"

bestAttemptContent.subtitle = "\(brewType) • \(dose)g @ \(pressure) bar"

if !elapsedTime.isEmpty && !preInfusionTime.isEmpty {
    bestAttemptContent.body += "\nPre-infusion: \(elapsedTime) / \(preInfusionTime) seconds."
}
```

#### Expanded Content (Content Extension)

**Visual Puck Representation**
- Circular graphic representing the coffee puck
- Gradually darkens or fills with water as pre-infusion progresses
- Animation shows water saturation spreading through the puck

**Timer Display**
- Large countdown: `Pre-infusion: 4.2 s / 8.0 s`
- Progress ring around the puck visualization
- Color changes as time progresses (blue → amber → green)

**Pressure Indicator**
- Current pressure: `2.0 bar`
- Small horizontal bar or gauge visualization
- Target pressure range indicator

**Brew Parameters**
- Dose: 18g
- Temperature: 200°F
- Target ratio: 1:2.0

**Actions**
- `Skip to Extraction` - Immediately begins full pressure extraction
- `Extend Pre-Infusion` - Adds additional time to pre-infusion phase

#### Technical Focus

- **NSE**: Stage-aware text enhancement with timing data
- **Content Extension**: Custom UI with timer and stylized puck visualization
- **Actions**: Stage-specific controls for adjusting brew parameters
- **Demonstration**: Real-time parameter display and interactive controls

---

### Stage 4: Brewing (Extraction)

**Goal**: This is the "hero" notification demonstrating rich media, live stats, and multiple controls in a single expanded view.

#### Collapsed Notification

**Title**: `Extraction in progress`

**Subtitle**: `Espresso • 19s elapsed`
- Dynamically constructed from brew profile and timing data
- Format: `{brewType} • {elapsed}s elapsed`
- Updates as extraction progresses

**Body**: `Your espresso shot is pulling. Tap to view live stats.`
- Optional enhancement: `Flow rate: 1.2 ml/s` (if available)

**Media**: Still image from naked portafilter perspective
- Shows espresso extraction in progress
- Downloaded from `imageUrl` by NSE
- Captures the "espresso stream" visual

#### Notification Service Extension Processing

1. **Parse Extraction Parameters**: Extract `brewType`, `dose`, `elapsedTime`, `pressure`, `temperature`
2. **Build Subtitle**: Format with brew type and elapsed time
3. **Download Media**: Fetch extraction image from `imageUrl`
4. **Enhance Body**: Add flow rate if available
5. **Set Category**: Assign `BREW_EXTRACTION` category

```swift
// Example NSE processing
let brewType = userInfo["brewType"] as? String ?? "Espresso"
let elapsedTime = userInfo["elapsedTime"] as? String ?? "0"
let flowRate = userInfo["flowRate"] as? String

bestAttemptContent.subtitle = "\(brewType) • \(elapsedTime)s elapsed"

if let flow = flowRate {
    bestAttemptContent.body += "\nFlow rate: \(flow) ml/s"
}
```

#### Expanded Content (Content Extension)

**Large Media Display**
- Full-width image or live-like snapshot of extraction
- "Tiny camera in the cup" perspective showing espresso flowing
- Updates periodically if multiple images available

**Key Stats Grid**
- **Elapsed**: `19s` (time since extraction started)
- **Pressure**: `9.0 bar` (current extraction pressure)
- **Temperature**: `93°C` (water temperature)
- **Dose**: `18g` (coffee dose)
- **Flow**: `1.2 ml/s` (current flow rate, if available)
- **Volume**: `15 ml` (total extracted volume, if available)

**Timeline/Progress Bar**
- Visual indicator showing current position in expected shot time
- Typical range: 25-35 seconds
- Simple progress visualization

**Interactions**
- `Stop Shot Now` - Immediately ends extraction
- `View Live` - Opens app to live extraction view

#### Technical Focus

- **NSE**: Data parsing and media attachment
- **Content Extension**: Brew dashboard with live parameters
- **Media**: Rich visual content showing extraction process
- **Actions**: Meaningful controls for brew management
- **Demonstration**: Notifications as a control panel, not just an alert

---

### Stage 5: Complete

**Goal**: Demonstrate a summary notification with rich formatting, final stats, and calls to action for review or repeat brew.

#### Collapsed Notification

**Title**: `Espresso shot complete`

**Subtitle**: `Completed in 28s`
- Final brew statistics
- Format: `Completed in {time}s`

**Body**: `Your espresso is ready. Enjoy!`

**Media**: Final cup image showing finished espresso with crema
- Downloaded from `imageUrl` by NSE
- Hero shot of the completed beverage

#### Notification Service Extension Processing

1. **Parse Final Statistics**: Extract `elapsedTime` from `userInfo`
2. **Build Subtitle**: Format with final time
3. **Download Media**: Fetch final cup image from `imageUrl`
4. **Enhance Body**: Add short summary line
5. **Set Category**: Assign `BREW_COMPLETE` category

```swift
// Example NSE processing
let elapsedTime = userInfo["elapsedTime"] as? String ?? "28"

bestAttemptContent.subtitle = "Completed in \(elapsedTime)s"
bestAttemptContent.body = "Your espresso is ready. Enjoy!"
```

#### Expanded Content (Content Extension)

**Hero Image**
- Large, high-quality image of finished espresso
- Shows crema quality and presentation
- "Instagram-worthy" shot composition

**Summary Card**
- **Brew Type**: `Espresso`
- **Dose**: `18g`
- **Time**: `28s`
- **Temperature**: `93°C`
- **Pressure**: `9.0 bar`

**Brew Notes**
- Simple completion message
- Example: "Perfect extraction completed. Your espresso is ready to enjoy."
- Encourages user to try the brew

**Actions**
- `Brew Again` - Starts new brew with same parameters
- `Adjust Profile` - Deep links to brew profile editor in app
- `Share` - Opens share sheet with brew stats and image

#### Technical Focus

- **NSE**: Final statistics enhancement and media attachment
- **Content Extension**: Summary-style UI focused on completion and next actions
- **Actions**: Workflow completion actions (repeat, adjust, share)
- **Demonstration**: Notifications help close the loop on a workflow, not just signal its end

---

## Notification Categories and Actions

### Category Definitions

Each brew stage maps to a specific notification category that defines available actions:

#### BREW_HEATING
- **Actions**: None (informational only)
- **Rationale**: User cannot meaningfully interact during heating phase

#### BREW_GRINDING
- **Actions**:
  - `pause_grinding` - Pause Grinding
  - `adjust_grind` - Adjust Grind Size
- **Rationale**: User may want to pause or adjust grind settings

#### BREW_PREINFUSION
- **Actions**:
  - `skip_preinfusion` - Skip to Extraction
  - `extend_preinfusion` - Extend Pre-Infusion
- **Rationale**: User can control pre-infusion duration

#### BREW_EXTRACTION
- **Actions**:
  - `stop_shot` - Stop Shot Now
  - `view_live` - View Live
- **Rationale**: User can stop early or view live extraction details

#### BREW_COMPLETE
- **Actions**:
  - `brew_again` - Brew Again
  - `adjust_profile` - Adjust Profile
  - `share` - Share
- **Rationale**: User can repeat, modify, or share the completed brew

### Action Handling

**iOS/macOS**
- Actions handled in `AppDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)`
- Action identifiers mapped to deep links
- Deep links sent to Flutter via method channel

**Android**
- Actions handled in `NotificationActionReceiver.onReceive()`
- PendingIntents trigger broadcast receiver
- Action data sent to Flutter via method channel

**Web**
- Actions handled in Service Worker `notificationclick` event
- Action identifiers mapped to navigation URLs
- App window opened or focused with target URL

---

## Data Payload Structure

### Common Fields

All notifications include these base fields:

```json
{
  "type": "brew_stage",
  "stage": "brewing",
  "brewId": "brew_123",
  "title": "Extraction in progress",
  "body": "Your espresso shot is pulling.",
  "imageUrl": "https://cdn.example.com/extraction.jpg",
  "deepLink": "firstcrack://brew/123/live"
}
```

### Brew-Specific Fields

Additional fields vary by brew stage:

```json
{
  "brewType": "espresso",
  "dose": "18",
  "temperature": "93",
  "pressure": "9",
  "elapsedTime": "19",
  "remainingTime": "9",
  "flowRate": "1.2",
  "volumeExtracted": "15"
}
```

### Platform-Specific Configuration

**iOS/macOS**
```json
{
  "apns": {
    "payload": {
      "aps": {
        "mutable-content": 1,
        "category": "BREW_EXTRACTION",
        "sound": "default"
      }
    }
  }
}
```

**Android**
```json
{
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "brew_notifications",
      "tag": "brew_123"
    }
  }
}
```

**Web**
```json
{
  "webpush": {
    "notification": {
      "icon": "/icons/icon-192.png",
      "badge": "/icons/badge-72.png",
      "requireInteraction": true
    }
  }
}
```

---

## User Experience Flow

### Complete Brew Cycle

1. **User Initiates Brew** (in app)
   - Selects brew profile
   - Taps "Start Brew" button
   - App sends request to espresso machine

2. **Heating Stage** (0-30s)
   - Notification: "Heating water for espresso"
   - Shows temperature progress
   - No user interaction required

3. **Grinding Stage** (30-45s)
   - Notification: "Grinding beans for your shot"
   - Shows grinding progress with image
   - User can pause or adjust settings

4. **Pre-Infusion Stage** (45-53s)
   - Notification: "Pre-infusion in progress"
   - Shows puck saturation visualization
   - User can skip or extend pre-infusion

5. **Extraction Stage** (53-81s)
   - Notification: "Extraction in progress"
   - Shows live stats and extraction image
   - User can stop early or view live

6. **Complete Stage** (81s+)
   - Notification: "Espresso shot complete"
   - Shows final stats and cup image
   - User can brew again, adjust, or share

### Notification Interaction Patterns

**Tap Notification Body**
- Opens app to brew detail screen
- Shows full brew history and parameters
- Provides access to all controls

**Tap Action Button**
- Executes specific action (stop, extend, etc.)
- May open app if foreground action required
- May execute in background if possible

**Expand Notification**
- Shows content extension with rich UI
- Displays live parameters and visualizations
- Provides access to all available actions

**Dismiss Notification**
- Removes notification from notification center
- Does not affect brew process
- Can be re-displayed if brew still active

---

## Implementation Guidelines

### Notification Service Extension (iOS/macOS)

**Media Download Best Practices**
- Set reasonable timeout (10 seconds)
- Implement retry logic for failed downloads
- Provide fallback to app icon if download fails
- Cache downloaded media for repeated notifications
- Validate media format and size before attaching

**Text Enhancement Guidelines**
- Keep subtitle concise (< 50 characters)
- Use consistent formatting across stages
- Validate all data fields before using
- Provide sensible defaults for missing data
- Localize all user-facing text

**Performance Considerations**
- NSE has 30-second execution limit
- Prioritize critical enhancements first
- Fail gracefully if time limit approached
- Log errors for debugging but don't crash
- Test with slow network conditions

### Content Extension (iOS/macOS)

**UI Design Principles**
- Keep layout simple and focused
- Use large, readable text for key stats
- Provide clear visual hierarchy
- Ensure touch targets are adequately sized
- Support both light and dark mode

**Update Frequency**
- Update UI when notification data changes
- Avoid excessive animation or CPU usage
- Batch updates to minimize redraws
- Consider battery impact of frequent updates

**Accessibility**
- Provide VoiceOver labels for all elements
- Ensure sufficient color contrast
- Support Dynamic Type for text scaling
- Test with accessibility features enabled

### Android Implementation

**Notification Channel Configuration**
- Create dedicated channel for brew notifications
- Set appropriate importance level (HIGH)
- Configure sound, vibration, and LED
- Allow user customization of channel settings

**Custom Layout Guidelines**
- Use RemoteViews for custom layouts
- Keep layout complexity reasonable
- Test on various screen sizes and densities
- Provide fallback to standard layout if needed

**Action Button Design**
- Limit to 3 actions per notification
- Use clear, concise action labels
- Provide appropriate icons for actions
- Handle action failures gracefully

### Web Implementation

**Service Worker Best Practices**
- Keep service worker logic minimal
- Cache notification assets for offline use
- Handle push events within time limit
- Provide fallback for unsupported features

**Browser Compatibility**
- Test across Chrome, Firefox, Edge, Safari
- Gracefully degrade on unsupported browsers
- Provide clear messaging about limitations
- Document browser-specific behaviors

**Permission Handling**
- Request permission at appropriate time
- Explain value of notifications to user
- Respect user's permission decision
- Provide way to re-enable if denied

---

## Testing Strategy

### Unit Testing

**Notification Data Parsing**
- Test parsing of all field types
- Verify handling of missing fields
- Test invalid data formats
- Verify default value assignment

**Subtitle Generation**
- Test all brew stage subtitle formats
- Verify unit conversion (°F/°C)
- Test with edge case values
- Verify localization

**Media Download**
- Test successful download
- Test failed download with fallback
- Test timeout handling
- Test invalid URL handling

### Integration Testing

**End-to-End Brew Cycle**
- Start brew and verify all stage notifications
- Verify notification updates in real-time
- Test action button functionality
- Verify deep link navigation

**Cross-Platform Testing**
- Test on iOS, Android, and Web
- Verify consistent behavior across platforms
- Test platform-specific features
- Verify media display on all platforms

**App State Testing**
- Test notifications in foreground
- Test notifications in background
- Test notifications when app terminated
- Verify proper app launch from notification

### User Acceptance Testing

**Usability Testing**
- Verify notifications are informative
- Confirm actions are intuitive
- Test with real users
- Gather feedback on notification frequency

**Performance Testing**
- Measure notification delivery latency
- Test with poor network conditions
- Verify battery impact
- Test with multiple concurrent brews

---

## Analytics and Monitoring

### Key Metrics

**Delivery Metrics**
- Notification delivery rate
- Time from send to delivery
- Delivery failures by platform
- Retry success rate

**Engagement Metrics**
- Notification open rate
- Action button tap rate
- Notification dismissal rate
- Time to interaction

**User Behavior**
- Most used actions by stage
- Notification preferences
- Opt-out rate
- Re-engagement rate

### Error Tracking

**Common Errors**
- Media download failures
- Invalid data payloads
- Permission denied errors
- Deep link navigation failures

**Monitoring**
- Real-time error alerts
- Error rate by platform
- Error trends over time
- User impact assessment

---

## Future Enhancements

### Potential Features

**Advanced Visualizations**
- Real-time video streaming in notifications
- Animated extraction progress
- 3D puck visualization
- Pressure/flow graphs

**Machine Learning Integration**
- Predicted extraction quality
- Personalized brew recommendations
- Anomaly detection and alerts
- Automatic profile optimization

**Social Features**
- Share brews with friends
- Compare brews with community
- Leaderboards and achievements
- Collaborative brew sessions

**Enhanced Controls**
- Fine-grained parameter adjustment
- Custom action button configuration
- Programmable notification rules
- Integration with smart home systems

### Platform-Specific Enhancements

**iOS/macOS**
- Live Activities for ongoing brews
- Dynamic Island integration (iPhone 14+)
- Apple Watch complications
- Siri Shortcuts integration

**Android**
- Wear OS companion app
- Notification bubbles
- Conversation-style notifications
- Adaptive notification timing

**Web**
- Progressive Web App installation
- Background sync for offline brews
- Web Share API integration
- Notification badges

---

## Conclusion

The First Crack notification system demonstrates how push notifications can evolve from simple alerts into a rich, interactive control surface. By progressively enhancing notifications through the five brew stages, the system showcases:

1. **Text enrichment** with dynamic brew parameters
2. **Rich media** integration with images and videos
3. **Interactive controls** for adjusting brew parameters
4. **Real-time updates** with live statistics
5. **Workflow completion** with summary and next actions

This design provides users with a comprehensive brew monitoring experience without requiring them to open the app, while demonstrating best practices for notification implementation across iOS, Android, and Web platforms.
