/**
 * FCM Service
 *
 * Handles sending Firebase Cloud Messaging notifications.
 * Constructs platform-specific message payloads for iOS, Android, macOS, and web.
 */

import * as admin from "firebase-admin";
import { BrewState } from "./types/brew-types";
import { FCMMessage, NotificationData } from "./types/notification-types";
import { StageConfig, MEDIA_BASE_URL } from "./data/brew-stages";

/**
 * Send a notification for a specific brew stage
 */
export async function sendBrewNotification(
  brewState: BrewState,
  stageConfig: StageConfig
): Promise<void> {
  const message = buildFCMMessage(brewState, stageConfig);

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent notification:", {
      brewId: brewState.brewId,
      stage: stageConfig.stage,
      messageId: response,
    });
  } catch (error) {
    console.error("Error sending notification:", {
      brewId: brewState.brewId,
      stage: stageConfig.stage,
      error,
    });
    throw error;
  }
}

/**
 * Build a complete FCM message with platform-specific configurations
 */
function buildFCMMessage(
  brewState: BrewState,
  stageConfig: StageConfig
): FCMMessage {
  const notificationData = buildNotificationData(brewState, stageConfig);

  // Convert NotificationData to string-only data payload
  const dataPayload: Record<string, string> = {};
  Object.entries(notificationData).forEach(([key, value]) => {
    if (value !== undefined) {
      dataPayload[key] = String(value);
    }
  });

  const message: FCMMessage = {
    token: brewState.deviceToken,
    data: dataPayload,

    // Android configuration
    android: {
      priority: stageConfig.highPriority ? "high" : "normal",
      notification: {
        title: stageConfig.title,
        body: stageConfig.body,
        imageUrl: stageConfig.imageUrl ?
          `${MEDIA_BASE_URL}${stageConfig.imageUrl}` : undefined,
        channelId: "brew_notifications",
        priority: stageConfig.highPriority ? "high" : "default",
        sound: "default",
        tag: `brew_${brewState.brewId}`,
      },
    },

    // iOS/macOS APNS configuration
    apns: {
      headers: {
        "apns-priority": stageConfig.highPriority ? "10" : "5",
        "apns-push-type": "alert",
      },
      payload: {
        aps: {
          alert: {
            title: stageConfig.title,
            body: stageConfig.body,
          },
          sound: "default",
          badge: 1,
          "mutable-content": 1, // Enables Notification Service Extension
          category: stageConfig.actions ? "BREW_ACTIONS" : undefined,
        },
      },
    },

    // Web push configuration
    webpush: {
      notification: {
        title: stageConfig.title,
        body: stageConfig.body,
        icon: "/icons/icon-192.png",
        image: stageConfig.imageUrl ?
          `${MEDIA_BASE_URL}${stageConfig.imageUrl}` : undefined,
        badge: "/icons/badge-72.png",
        requireInteraction: stageConfig.requireInteraction,
      },
      fcmOptions: {
        link: stageConfig.deepLink,
      },
    },
  };

  return message;
}

/**
 * Build the notification data payload
 */
function buildNotificationData(
  brewState: BrewState,
  stageConfig: StageConfig
): NotificationData {
  const elapsedTime = Math.floor((Date.now() - brewState.startTime) / 1000);
  const remainingTime = brewState.extractionTime - elapsedTime;

  const data: NotificationData = {
    type: stageConfig.stage === "brew_complete" ?
      "brew_complete" : "brew_stage",
    stage: stageConfig.stage,
    brewId: brewState.brewId,
    title: stageConfig.title,
    body: stageConfig.body,
    brewType: brewState.brewType,
    dose: String(brewState.dose),
    temperature: String(brewState.targetTemp),
    pressure: String(brewState.targetPressure),
    elapsedTime: String(elapsedTime),
  };

  // Add optional fields
  if (stageConfig.imageUrl) {
    data.imageUrl = `${MEDIA_BASE_URL}${stageConfig.imageUrl}`;
  }

  if (stageConfig.videoUrl) {
    data.videoUrl = `${MEDIA_BASE_URL}${stageConfig.videoUrl}`;
  }

  if (stageConfig.actions) {
    data.actions = JSON.stringify(stageConfig.actions);
  }

  if (stageConfig.deepLink) {
    data.deepLink = stageConfig.deepLink;
  }

  if (stageConfig.progress !== undefined) {
    data.progress = String(stageConfig.progress);
  }

  if (remainingTime > 0) {
    data.remainingTime = String(remainingTime);
  }

  // Add extraction-specific data
  if (stageConfig.stage === "extraction_progress" ||
      stageConfig.stage === "extraction_complete") {
    data.flowRate = "2.5"; // ml/s
    data.volumeExtracted = String(Math.floor(elapsedTime * 1.3)); // Rough calc
  }

  return data;
}

/**
 * Validate an FCM token format
 */
export function isValidFCMToken(token: string): boolean {
  // Basic validation - FCM tokens are typically 152+ characters
  return typeof token === "string" && token.length > 100;
}
