/**
 * Brew Types
 *
 * Type definitions for coffee brewing parameters and configurations.
 * These types model the parameters of a high-end espresso machine.
 */

/**
 * Supported brew methods
 */
export type BrewType = "espresso" | "lungo" | "ristretto" | "americano";

/**
 * Brew stage identifiers
 * Matches the BrewStage enum defined in the Flutter app
 */
export type BrewStage =
  | "heating"
  | "grinding"
  | "preInfusion"
  | "brewing"
  | "complete";

/**
 * Parameters for starting a brew simulation
 */
export interface BrewRequest {
  /** FCM device token to send notifications to */
  deviceToken: string;

  /** Type of brew to simulate */
  brewType: BrewType;

  /** Coffee dose in grams (typically 14-22g for espresso) */
  dose: number;

  /** Target water temperature in Celsius (typically 88-96°C) */
  targetTemp: number;

  /** Target pressure in bars (typically 8-10 bar for espresso) */
  targetPressure: number;

  /** Optional: Pre-infusion duration in seconds (default: 8) */
  preinfusionDuration?: number;

  /** Optional: Target extraction time in seconds (default: 25-30) */
  extractionTime?: number;

  /** Optional: User ID for tracking (if authenticated) */
  userId?: string;
}

/**
 * Response from starting a brew simulation
 */
export interface BrewResponse {
  /** Whether the brew was successfully started */
  success: boolean;

  /** Unique identifier for this brew */
  brewId: string;

  /** Human-readable message */
  message: string;

  /** Number of notification stages */
  stages: number;

  /** Estimated total duration in seconds */
  estimatedDuration: number;
}

/**
 * Internal brew state tracking
 */
export interface BrewState {
  brewId: string;
  deviceToken: string;
  brewType: BrewType;
  dose: number;
  targetTemp: number;
  targetPressure: number;
  preinfusionDuration: number;
  extractionTime: number;
  startTime: number;
  currentStage: BrewStage;
}
