/**
 * First Crack Cloud Functions
 *
 * Main entry point for Firebase Cloud Functions.
 * Exports HTTP endpoints for the brew simulation backend.
 */

import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { startBrewSimulation, validateBrewRequest } from "./brew-simulator";
import { isValidFCMToken } from "./fcm-service";
import { BrewRequest } from "./types/brew-types";

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * HTTP endpoint to start a brew simulation
 *
 * POST /startBrew
 * Body: BrewRequest JSON
 *
 * Example:
 * {
 *   "deviceToken": "fcm_token_here",
 *   "brewType": "espresso",
 *   "dose": 18,
 *   "targetTemp": 93,
 *   "targetPressure": 9
 * }
 */
export const startBrew = onRequest(
  {
    cors: true,
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async (request, response) => {
    // Only accept POST requests
    if (request.method !== "POST") {
      response.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      });
      return;
    }

    try {
      const brewRequest = request.body as BrewRequest;

      // Validate request
      const validation = validateBrewRequest(brewRequest);
      if (!validation.valid) {
        response.status(400).json({
          success: false,
          error: "Invalid request parameters",
          details: validation.errors,
        });
        return;
      }

      // Additional token validation
      if (!isValidFCMToken(brewRequest.deviceToken)) {
        response.status(400).json({
          success: false,
          error: "Invalid FCM device token format",
        });
        return;
      }

      // Start the brew simulation
      const result = await startBrewSimulation(brewRequest);

      response.status(200).json(result);
    } catch (error) {
      console.error("Error in startBrew function:", error);
      response.status(500).json({
        success: false,
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);

/**
 * Health check endpoint
 *
 * GET /health
 */
export const health = onRequest(
  {
    cors: true,
    region: "us-central1",
  },
  async (request, response) => {
    response.status(200).json({
      status: "healthy",
      service: "first-crack-cloud",
      version: "1.0.0",
      timestamp: new Date().toISOString(),
    });
  }
);
