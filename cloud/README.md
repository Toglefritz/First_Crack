# First Crack Cloud Backend ☁️

This directory contains the Firebase Cloud Functions backend for the First Crack application. The
backend simulates an espresso machine brewing process by sending a series of timed push
notifications via Firebase Cloud Messaging (FCM).

## Architecture Overview

The backend is built using **Firebase Cloud Functions** (2nd generation) with TypeScript. It
provides a single HTTP endpoint that initiates a simulated brew cycle, sending structured FCM
messages at specific intervals to mimic real-world coffee machine behavior.

### Key Components

- **HTTP Trigger**: `startBrew` endpoint that accepts device tokens and brew parameters
- **Scheduled Notifications**: Series of FCM messages sent at timed intervals
- **Message Schemas**: Structured data payloads designed for rich notification rendering
- **Media References**: URLs to images and videos for notification content

## Project Structure

```
cloud/
├── src/
│   ├── index.ts              # Main entry point, exports Cloud Functions
│   ├── brew-simulator.ts     # Core brewing simulation logic
│   ├── fcm-service.ts        # FCM message sending service
│   ├── types/
│   │   ├── brew-types.ts     # Brewing parameter types
│   │   └── notification-types.ts  # FCM message structure types
│   └── data/
│       └── brew-stages.ts    # Brew stage definitions and timing
├── docs/
│   ├── API.md                # API endpoint documentation
│   ├── FCM_MESSAGE_SPEC.md   # Detailed FCM message format specification
│   └── DEPLOYMENT.md         # Deployment and configuration guide
├── package.json
├── tsconfig.json
└── README.md
```

## Quick Start

### Prerequisites

- Node.js 20 or later
- Firebase CLI: `npm install -g firebase-tools`
- A Firebase project with Cloud Functions and FCM enabled

### Installation

```bash
cd cloud
npm install
```

### Local Development

Run the Firebase emulator suite:

```bash
npm run serve
```

This starts the Functions emulator at `http://localhost:5001`.

### Build

Compile TypeScript to JavaScript:

```bash
npm run build
```

### Deploy

Deploy to Firebase:

```bash
npm run deploy
```

## Usage

### Starting a Brew Simulation

Send a POST request to the `startBrew` endpoint:

```bash
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/startBrew \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "DEVICE_FCM_TOKEN",
    "brewType": "espresso",
    "dose": 18,
    "targetTemp": 93,
    "targetPressure": 9
  }'
```

### Response

```json
{
  "success": true,
  "brewId": "brew_1234567890",
  "message": "Brew simulation started",
  "stages": 7,
  "estimatedDuration": 90
}
```

## Brew Simulation Flow

The backend sends notifications at the following stages:

1. **Heating** (t+0s) - Machine is heating water
2. **Ready** (t+30s) - Ready to brew with action buttons
3. **Pre-infusion Start** (t+35s) - Pre-infusion begins with image
4. **Pre-infusion Complete** (t+50s) - Pre-infusion done, extraction starting
5. **Extraction Progress** (t+60s) - Mid-extraction with video/live feed
6. **Extraction Complete** (t+80s) - Extraction finishing
7. **Brew Complete** (t+90s) - Final notification with result image

Each notification includes:
- Stage-specific title and body text
- Relevant media (images, videos)
- Interactive actions where appropriate
- Deep link data for app navigation
- Brewing parameters and progress data

## FCM Message Structure

All messages follow a consistent structure designed to support rich notification rendering on iOS,
Android, macOS, and web platforms. See [FCM_MESSAGE_SPEC.md](docs/FCM_MESSAGE_SPEC.md) for
complete details.

### Message Anatomy

```typescript
{
  token: string,              // Device FCM token
  data: {
    type: string,             // Notification type (e.g., "brew_stage")
    stage: string,            // Current brew stage
    brewId: string,           // Unique brew identifier
    title: string,            // Notification title
    body: string,             // Notification body
    imageUrl?: string,        // Optional image URL
    videoUrl?: string,        // Optional video URL
    actions?: string,         // JSON array of action objects
    deepLink?: string,        // App deep link
    progress?: string,        // Progress percentage (0-100)
    // ... additional brew parameters
  },
  android: {
    priority: "high",
    notification: { ... }
  },
  apns: {
    payload: { ... }
  },
  webpush: {
    notification: { ... }
  }
}
```

## Environment Configuration

Create a `.env` file (not committed to git) for local development:

```env
# Media asset base URL
MEDIA_BASE_URL=https://your-cdn.com/first-crack

# Notification timing (in seconds)
HEATING_DURATION=30
PREINFUSION_DURATION=15
EXTRACTION_DURATION=30
```

**Note**: Firebase project configuration is automatically available via `process.env.GCLOUD_PROJECT` 
in Cloud Functions. Do not use `FIREBASE_` or `X_GOOGLE_` prefixes as they are reserved.

## Common Issues

### Deployment Error: Reserved Environment Variable Prefix

**Error**: `Failed to load environment variables from .env.: Error Key FIREBASE_PROJECT_ID starts with a reserved prefix`

**Solution**: Remove any environment variables with reserved prefixes from your `.env` file:
- `FIREBASE_*` - Reserved by Firebase
- `X_GOOGLE_*` - Reserved by Google Cloud
- `EXT_*` - Reserved for extensions

The Firebase project ID is automatically available as `process.env.GCLOUD_PROJECT` in Cloud Functions.

### Functions Not Deploying

- Ensure you're logged in: `firebase login`
- Check project: `firebase use --add`
- Verify billing is enabled

### Notifications Not Received

- Verify FCM token is valid
- Check device notification permissions
- Review FCM delivery logs in Firebase Console

## Monitoring and Debugging

### View Logs

```bash
npm run logs
```

## Cost Considerations

Firebase Cloud Functions pricing is based on:
- Number of invocations
- Compute time
- Outbound networking

For this demo app:
- Each brew simulation = 1 function invocation + 7 FCM messages
- Estimated cost: < $0.01 per brew simulation
- Free tier: 2M invocations/month

## Testing

### Postman Collection

A complete Postman collection is included for testing all endpoints:

1. Import `First_Crack_API.postman_collection.json` into Postman
2. Configure collection variables (base URL and FCM token)
3. Run requests to test functionality

See [POSTMAN_GUIDE.md](POSTMAN_GUIDE.md) for detailed instructions.

### Manual Testing with cURL

Test the health endpoint:
```bash
curl https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/health
```

Test starting a brew:
```bash
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/startBrew \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "YOUR_FCM_TOKEN",
    "brewType": "espresso",
    "dose": 18,
    "targetTemp": 93,
    "targetPressure": 9
  }'
```

## Further Documentation

- [QUICKSTART.md](QUICKSTART.md) - 5-minute setup guide
- [POSTMAN_GUIDE.md](POSTMAN_GUIDE.md) - Postman collection usage guide
- [API.md](docs/API.md) - Complete API reference
- [FCM_MESSAGE_SPEC.md](docs/FCM_MESSAGE_SPEC.md) - FCM message format specification
