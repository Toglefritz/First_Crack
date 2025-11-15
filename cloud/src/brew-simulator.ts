/**
 * Brew Simulator
 *
 * Core logic for simulating an espresso brewing process.
 * Schedules and sends notifications at appropriate intervals.
 */

import { BrewRequest, BrewResponse, BrewState } from "./types/brew-types";
import { sendBrewNotification } from "./fcm-service";
import { BREW_STAGES, getTotalBrewDuration } from "./data/brew-stages";

/**
 * Start a brew simulation
 * Schedules all notifications for the brew cycle
 */
export async function startBrewSimulation(
  request: BrewRequest
): Promise<BrewResponse> {
  const brewId = generateBrewId();
  const startTime = Date.now();

  const brewState: BrewState = {
    brewId,
    deviceToken: request.deviceToken,
    brewType: request.brewType,
    dose: request.dose,
    targetTemp: request.targetTemp,
    targetPressure: request.targetPressure,
    preinfusionDuration: request.preinfusionDuration || 8,
    extractionTime: request.extractionTime || 28,
    startTime,
    currentStage: "heating",
  };

  console.log("Starting brew simulation:", {
    brewId,
    brewType: request.brewType,
    dose: request.dose,
    targetTemp: request.targetTemp,
  });

  // Schedule all notifications
  scheduleBrewNotifications(brewState);

  return {
    success: true,
    brewId,
    message: "Brew simulation started",
    stages: BREW_STAGES.length,
    estimatedDuration: getTotalBrewDuration(),
  };
}

/**
 * Schedule all notifications for a brew
 * Uses setTimeout to send notifications at the appropriate times
 */
function scheduleBrewNotifications(brewState: BrewState): void {
  BREW_STAGES.forEach((stageConfig) => {
    const delayMs = stageConfig.delaySeconds * 1000;

    setTimeout(async () => {
      try {
        brewState.currentStage = stageConfig.stage;
        await sendBrewNotification(brewState, stageConfig);
      } catch (error) {
        console.error(`Failed to send notification for stage ${stageConfig.stage}:`, error);
      }
    }, delayMs);
  });

  console.log(`Scheduled ${BREW_STAGES.length} notifications for brew ${brewState.brewId}`);
}

/**
 * Generate a unique brew ID
 */
function generateBrewId(): string {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  return `brew_${timestamp}_${random}`;
}

/**
 * Validate brew request parameters
 */
export function validateBrewRequest(request: BrewRequest): {
  valid: boolean;
  errors: string[];
} {
  const errors: string[] = [];

  // Validate device token
  if (!request.deviceToken || request.deviceToken.length < 100) {
    errors.push("Invalid or missing device token");
  }

  // Validate brew type
  const validBrewTypes = ["espresso", "lungo", "ristretto", "americano"];
  if (!validBrewTypes.includes(request.brewType)) {
    errors.push(`Invalid brew type. Must be one of: ${validBrewTypes.join(", ")}`);
  }

  // Validate dose (typical range: 14-22g for espresso)
  if (request.dose < 10 || request.dose > 30) {
    errors.push("Dose must be between 10 and 30 grams");
  }

  // Validate temperature (typical range: 88-96°C)
  if (request.targetTemp < 85 || request.targetTemp > 100) {
    errors.push("Target temperature must be between 85 and 100°C");
  }

  // Validate pressure (typical range: 6-12 bar)
  if (request.targetPressure < 5 || request.targetPressure > 15) {
    errors.push("Target pressure must be between 5 and 15 bar");
  }

  // Validate optional parameters
  if (request.preinfusionDuration !== undefined) {
    if (request.preinfusionDuration < 0 || request.preinfusionDuration > 30) {
      errors.push("Pre-infusion duration must be between 0 and 30 seconds");
    }
  }

  if (request.extractionTime !== undefined) {
    if (request.extractionTime < 15 || request.extractionTime > 60) {
      errors.push("Extraction time must be between 15 and 60 seconds");
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
