/**
 * Notification Types
 *
 * Type definitions for FCM notification payloads.
 * These structures are designed to support rich notification rendering
 * across iOS, Android, macOS, and web platforms.
 */

import { BrewStage, BrewType } from "./brew-types";

/**
 * Action button configuration for interactive notifications
 */
export interface NotificationAction {
  /** Unique identifier for this action */
  id: string;

  /** Display text for the action button */
  title: string;

  /** Icon name (platform-specific) */
  icon?: string;

  /** Whether this action requires app to be in foreground */
  requiresForeground?: boolean;

  /** Deep link to navigate to when action is tapped */
  deepLink?: string;

  /** Additional data to pass with the action */
  data?: Record<string, string>;
}

/**
 * Core notification data payload
 * This is sent in the FCM message's `data` field
 */
export interface NotificationData {
  /** Notification type identifier */
  type: "brew_stage" | "brew_alert" | "brew_complete";

  /** Current brew stage */
  stage: BrewStage;

  /** Unique brew identifier */
  brewId: string;

  /** Notification title */
  title: string;

  /** Notification body text */
  body: string;

  /** URL to image for notification (optional) */
  imageUrl?: string;

  /** URL to video for notification (optional) */
  videoUrl?: string;

  /** JSON-encoded array of NotificationAction objects */
  actions?: string;

  /** Deep link for tapping the notification */
  deepLink?: string;

  /** Progress percentage (0-100) for progress indicators */
  progress?: string;

  /** Current brew type */
  brewType: BrewType;

  /** Coffee dose in grams */
  dose: string;

  /** Current/target temperature in Celsius */
  temperature: string;

  /** Current/target pressure in bars */
  pressure: string;

  /** Elapsed time in seconds */
  elapsedTime: string;

  /** Estimated remaining time in seconds */
  remainingTime?: string;

  /** Current flow rate in ml/s (for extraction stages) */
  flowRate?: string;

  /** Total volume extracted in ml (for extraction stages) */
  volumeExtracted?: string;
}

/**
 * Complete FCM message structure
 */
export interface FCMMessage {
  /** Device FCM token */
  token: string;

  /** Data payload (always included) */
  data: Record<string, string>;

  /** Android-specific configuration */
  android?: {
    priority: "high" | "normal";
    notification?: {
      title?: string;
      body?: string;
      imageUrl?: string;
      channelId?: string;
      priority?: "high" | "default" | "low";
      sound?: string;
      tag?: string;
    };
  };

  /** iOS/macOS APNS configuration */
  apns?: {
    headers?: {
      "apns-priority"?: string;
      "apns-push-type"?: string;
    };
    payload: {
      aps: {
        alert?: {
          title?: string;
          body?: string;
        };
        sound?: string;
        badge?: number;
        "mutable-content"?: number;
        "content-available"?: number;
        category?: string;
      };
    };
  };

  /** Web push configuration */
  webpush?: {
    notification?: {
      title?: string;
      body?: string;
      icon?: string;
      image?: string;
      badge?: string;
      requireInteraction?: boolean;
    };
    fcmOptions?: {
      link?: string;
    };
  };
}
