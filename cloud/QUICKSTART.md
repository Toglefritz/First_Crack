# Quick Start Guide

Get the First Crack backend running in 5 minutes.

## Prerequisites

- Node.js 20+ installed
- Firebase CLI installed: `npm install -g firebase-tools`
- A Firebase project created

## Step 1: Install Dependencies

```bash
cd cloud
npm install
```

## Step 2: Login to Firebase

```bash
firebase login
```

## Step 3: Set Your Firebase Project

Edit `.firebaserc` in the project root:

```json
{
  "projects": {
    "default": "your-project-id"
  }
}
```

Or use the CLI:

```bash
firebase use --add
```

**Note**: The Firebase project ID is automatically available in Cloud Functions via 
`process.env.GCLOUD_PROJECT`. You don't need to set it as an environment variable.

## Step 4: Test Locally (Optional)

Start the emulator:

```bash
npm run serve
```

Test the endpoint:

```bash
curl -X POST http://localhost:5001/YOUR_PROJECT/us-central1/startBrew \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "test_token_at_least_100_characters_long_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "brewType": "espresso",
    "dose": 18,
    "targetTemp": 93,
    "targetPressure": 9
  }'
```

## Step 5: Deploy to Firebase

```bash
npm run deploy
```

You'll see output with your function URLs:

```
Function URLs:
  startBrew: https://us-central1-your-project.cloudfunctions.net/startBrew
  health: https://us-central1-your-project.cloudfunctions.net/health
```

## Step 6: Test Production Endpoint

```bash
curl https://us-central1-your-project.cloudfunctions.net/health
```

Expected response:

```json
{
  "status": "healthy",
  "service": "first-crack-cloud",
  "version": "1.0.0",
  "timestamp": "2025-11-15T10:30:00.000Z"
}
```

## Step 7: Get FCM Token from Flutter App

In your Flutter app, get the device FCM token:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

final fcmToken = await FirebaseMessaging.instance.getToken();
print('FCM Token: $fcmToken');
```

## Step 8: Start a Brew Simulation

```bash
curl -X POST https://us-central1-your-project.cloudfunctions.net/startBrew \
  -H "Content-Type: application/json" \
  -d '{
    "deviceToken": "YOUR_ACTUAL_FCM_TOKEN_HERE",
    "brewType": "espresso",
    "dose": 18,
    "targetTemp": 93,
    "targetPressure": 9
  }'
```

Expected response:

```json
{
  "success": true,
  "brewId": "brew_1234567890_5678",
  "message": "Brew simulation started",
  "stages": 7,
  "estimatedDuration": 90
}
```

## Step 9: Watch for Notifications

Your device should receive 7 notifications over 90 seconds:

1. **t+0s**: "Heating Water"
2. **t+30s**: "Ready to Brew" (with action buttons)
3. **t+35s**: "Pre-infusion Started"
4. **t+50s**: "Pre-infusion Complete"
5. **t+60s**: "Extraction in Progress" (with video)
6. **t+80s**: "Extraction Complete"
7. **t+90s**: "Your Espresso is Ready! ☕"

## Troubleshooting

### "Billing account not configured"

Enable billing in Firebase Console (required for Cloud Functions).

### "Permission denied"

Run `firebase login` again and ensure you have owner/editor role on the project.

### Notifications not received

- Verify FCM token is valid and current
- Check notification permissions on device
- Review FCM logs in Firebase Console > Cloud Messaging

### Function not found

- Ensure deployment completed successfully
- Check function name matches: `startBrew`
- Verify region: `us-central1`

## Next Steps

- Read [API.md](docs/API.md) for complete API documentation
- Review [FCM_MESSAGE_SPEC.md](docs/FCM_MESSAGE_SPEC.md) for message structure
- Check [DEPLOYMENT.md](docs/DEPLOYMENT.md) for production deployment
- Implement notification rendering in your Flutter app

## Need Help?

- Check the [README.md](README.md) for overview
- Review Firebase Functions logs: `firebase functions:log`
- Verify FCM setup in Firebase Console
