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
 * Sends all notifications for the brew cycle with appropriate delays
 *
 * Note: This function sends notifications sequentially with delays, which means
 * it will keep the Cloud Function alive for the entire brew duration (~75 seconds).
 * In a production environment, you would use Cloud Scheduler or Cloud Tasks to
 * schedule notifications independently.
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

  // Send notifications asynchronously (don't wait for completion)
  // This allows the HTTP response to be sent immediately while notifications
  // continue to be sent in the background
  sendBrewNotificationsSequentially(brewState).catch((error) => {
    console.error("Error sending brew notifications:", error);
  });

  return {
    success: true,
    brewId,
    message: "Brew simulation started",
    stages: BREW_STAGES.length,
    estimatedDuration: getTotalBrewDuration(),
  };
}

/**
 * Send all notifications for a brew sequentially with delays
 *
 * This function sends notifications one at a time with the appropriate delays
 * between them. It uses actual delays (await sleep) rather than setTimeout
 * to ensure the Cloud Function stays alive for the entire brew duration.
 *
 * Note: This approach keeps the Cloud Function running for ~75 seconds, which
 * is acceptable for a demo but not ideal for production. In production, use
 * Cloud Scheduler or Cloud Tasks to schedule notifications independently.
 */
async function sendBrewNotificationsSequentially(brewState: BrewState): Promise<void> {
  console.log(`Starting sequential notification delivery for brew ${brewState.brewId}`);

  let previousDelaySeconds = 0;

  for (const stageConfig of BREW_STAGES) {
    // Calculate delay from previous stage
    const delayFromPrevious = stageConfig.delaySeconds - previousDelaySeconds;

    if (delayFromPrevious > 0) {
      console.log(`Waiting ${delayFromPrevious}s before sending ${stageConfig.stage} notification`);
      await sleep(delayFromPrevious * 1000);
    }

    try {
      brewState.currentStage = stageConfig.stage;
      console.log(`Sending ${stageConfig.stage} notification for brew ${brewState.brewId}`);
      await sendBrewNotification(brewState, stageConfig);
      console.log(`Successfully sent ${stageConfig.stage} notification`);
    } catch (error) {
      console.error(`Failed to send notification for stage ${stageConfig.stage}:`, error);
      // Continue with next notification even if one fails
    }

    previousDelaySeconds = stageConfig.delaySeconds;
  }

  console.log(`Completed all notifications for brew ${brewState.brewId}`);
}

/**
 * Sleep for a specified number of milliseconds
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
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
