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
 */
export const BREW_STAGES: StageConfig[] = [
  {
    stage: "heating",
    delaySeconds: 0,
    title: "Heating Water",
    body: "Your espresso machine is heating to the perfect temperature...",
    imageUrl: "/images/machine-heating.jpg",
    deepLink: "firstcrack://brew/status",
    progress: 10,
    highPriority: false,
  },
  {
    stage: "ready",
    delaySeconds: 30,
    title: "Ready to Brew",
    body: "Water temperature reached 93°C. Start your brew?",
    imageUrl: "/images/machine-ready.jpg",
    actions: [
      {
        id: "start_brew",
        title: "Start Brew",
        icon: "play",
        requiresForeground: false,
        deepLink: "firstcrack://brew/start",
      },
      {
        id: "adjust_temp",
        title: "Adjust Temp",
        icon: "settings",
        requiresForeground: true,
        deepLink: "firstcrack://brew/settings",
      },
      {
        id: "cancel",
        title: "Cancel",
        icon: "close",
        requiresForeground: false,
      },
    ],
    deepLink: "firstcrack://brew/ready",
    progress: 30,
    highPriority: true,
    requireInteraction: true,
  },
  {
    stage: "preinfusion_start",
    delaySeconds: 35,
    title: "Pre-infusion Started",
    body: "Gently saturating the coffee puck at 2 bar...",
    imageUrl: "/images/preinfusion.jpg",
    deepLink: "firstcrack://brew/preinfusion",
    progress: 40,
    highPriority: true,
  },
  {
    stage: "preinfusion_complete",
    delaySeconds: 50,
    title: "Pre-infusion Complete",
    body: "Ramping up to 9 bar for extraction...",
    imageUrl: "/images/extraction-start.jpg",
    deepLink: "firstcrack://brew/extraction",
    progress: 55,
    highPriority: false,
  },
  {
    stage: "extraction_progress",
    delaySeconds: 60,
    title: "Extraction in Progress",
    body: "Beautiful crema forming. 15ml extracted so far.",
    videoUrl: "/videos/extraction-live.mp4",
    imageUrl: "/images/extraction-progress.jpg",
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
    deepLink: "firstcrack://brew/extraction",
    progress: 70,
    highPriority: true,
  },
  {
    stage: "extraction_complete",
    delaySeconds: 80,
    title: "Extraction Complete",
    body: "36ml extracted in 28 seconds. Finishing up...",
    imageUrl: "/images/extraction-complete.jpg",
    deepLink: "firstcrack://brew/complete",
    progress: 95,
    highPriority: false,
  },
  {
    stage: "brew_complete",
    delaySeconds: 90,
    title: "Your Espresso is Ready! ☕",
    body: "Perfect extraction: 36ml in 28s at 93°C. Enjoy!",
    imageUrl: "/images/espresso-complete.jpg",
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
