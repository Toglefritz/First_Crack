/**
 * Brew Stage Definitions
 *
 * Defines the timing, content, and media for each stage of the brew simulation.
 * Each stage represents a notification that will be sent to the device.
 */

import { BrewStage } from "../types/brew-types";
import { NotificationAction } from "../types/notification-types";

/**
 * Configuration for a single brew stage
 */
export interface StageConfig {
  /** Stage identifier */
  stage: BrewStage;

  /** Delay in seconds from brew start */
  delaySeconds: number;

  /** Notification title */
  title: string;

  /** Notification body text */
  body: string;

  /** Image URL (relative to media base URL) */
  imageUrl?: string;

  /** Video URL (relative to media base URL) */
  videoUrl?: string;

  /** Interactive actions for this notification */
  actions?: NotificationAction[];

  /** Deep link destination */
  deepLink?: string;

  /** Progress percentage (0-100) */
  progress?: number;

  /** Whether this notification should be high priority */
  highPriority: boolean;

  /** Whether notification should require interaction (web) */
  requireInteraction?: boolean;
}

/**
 * Media base URL - in production, this would point to your CDN
 * For demo purposes, these can be placeholder URLs
 */
export const MEDIA_BASE_URL = process.env.MEDIA_BASE_URL ||
  "https://storage.googleapis.com/first-crack-demo";

/**
 * Complete brew stage timeline
 * Defines all notifications sent during a brew simulation
 * Matches the BrewStage enum and timing defined in the Flutter app
 * 
 * Timing breakdown (matches brew_service.dart):
 * - Heating: 0-30s (30s duration)
 * - Grinding: 30s (instant notification)
 * - Pre-infusion: 30-45s (15s duration)
 * - Brewing: 45-75s (30s duration)
 * - Complete: 75s
 */
export const BREW_STAGES: StageConfig[] = [
  {
    stage: "heating",
    delaySeconds: 0,
    title: "Heating Water",
    body: "Your espresso machine is heating to the perfect temperature...",
    imageUrl: "/images/heating.png",
    deepLink: "firstcrack://brew/heating",
    progress: 0,
    highPriority: false,
  },
  {
    stage: "grinding",
    delaySeconds: 30,
    title: "Grinding Beans",
    body: "Grinding fresh coffee beans to the perfect particle size...",
    imageUrl: "/images/grinding.png",
    deepLink: "firstcrack://brew/grinding",
    progress: 40,
    highPriority: false,
  },
  {
    stage: "preInfusion",
    delaySeconds: 30,
    title: "Pre-infusion",
    body: "Gently saturating the coffee puck at 2 bar...",
    imageUrl: "/images/pre_infusion.png",
    deepLink: "firstcrack://brew/preinfusion",
    progress: 60,
    highPriority: true,
  },
  {
    stage: "brewing",
    delaySeconds: 45,
    title: "Brewing",
    body: "Extracting espresso at 9 bar. Beautiful crema forming...",
    videoUrl: "/videos/extraction-live.mp4",
    imageUrl: "/images/brewing.png",
    actions: [
      {
        id: "view_live",
        title: "View Live",
        icon: "videocam",
        requiresForeground: true,
        deepLink: "firstcrack://brew/live",
      },
      {
        id: "stop_early",
        title: "Stop Now",
        icon: "stop",
        requiresForeground: false,
      },
    ],
    deepLink: "firstcrack://brew/brewing",
    progress: 80,
    highPriority: true,
  },
  {
    stage: "complete",
    delaySeconds: 75,
    title: "Your Espresso is Ready! ☕",
    body: "Perfect extraction: 36ml in 28s at 93°C. Enjoy!",
    imageUrl: "/images/brew_complete.png",
    actions: [
      {
        id: "view_details",
        title: "View Details",
        icon: "info",
        requiresForeground: true,
        deepLink: "firstcrack://brew/details",
      },
      {
        id: "brew_again",
        title: "Brew Again",
        icon: "refresh",
        requiresForeground: false,
        deepLink: "firstcrack://brew/new",
      },
      {
        id: "share",
        title: "Share",
        icon: "share",
        requiresForeground: true,
        deepLink: "firstcrack://brew/share",
      },
    ],
    deepLink: "firstcrack://brew/complete",
    progress: 100,
    highPriority: true,
    requireInteraction: true,
  },
];

/**
 * Get total brew duration in seconds
 */
export function getTotalBrewDuration(): number {
  return Math.max(...BREW_STAGES.map((stage) => stage.delaySeconds));
}

/**
 * Get stage configuration by stage identifier
 */
export function getStageConfig(stage: BrewStage): StageConfig | undefined {
  return BREW_STAGES.find((s) => s.stage === stage);
}

/**
 * Get all stages sorted by delay
 */
export function getSortedStages(): StageConfig[] {
  return [...BREW_STAGES].sort((a, b) => a.delaySeconds - b.delaySeconds);
}
