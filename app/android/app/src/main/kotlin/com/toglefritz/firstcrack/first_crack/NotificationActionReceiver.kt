package com.toglefritz.firstcrack.first_crack

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Broadcast receiver for handling notification action button taps.
 *
 * This receiver is triggered when a user taps an action button on a brew notification.
 * It extracts the action data from the intent and forwards it to the Flutter app via
 * the MainActivity's method channel.
 *
 * The receiver handles both foreground actions (which open the app) and background
 * actions (which may execute without opening the app, depending on the action type).
 *
 * Action Flow:
 * 1. User taps action button on notification
 * 2. PendingIntent triggers this broadcast receiver
 * 3. Receiver extracts action ID, brew ID, and other data
 * 4. Receiver generates deep link URL for navigation
 * 5. Receiver forwards action to MainActivity via static method
 * 6. MainActivity sends action to Flutter via method channel
 * 7. Flutter app handles navigation and business logic
 */
class NotificationActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "NotificationActionReceiver"
    }

    /**
     * Called when a notification action button is tapped.
     *
     * This method extracts the action data from the intent, generates the appropriate
     * deep link URL, and forwards the action to the MainActivity for delivery to Flutter.
     *
     * Intent Extras:
     * * actionId - The action identifier (e.g., "pause_grinding")
     * * brewId - The unique brew session identifier
     * * stage - The current brew stage
     * * deepLink - Optional pre-generated deep link URL
     *
     * @param context The application context
     * @param intent The broadcast intent containing action data
     */
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Notification action received")
        Log.d(TAG, "Action: ${intent.action}")
        
        // Extract action data from intent
        val actionId = intent.getStringExtra("actionId") ?: intent.action ?: run {
            Log.e(TAG, "Missing action ID in intent")
            return
        }
        
        val brewId = intent.getStringExtra("brewId") ?: run {
            Log.e(TAG, "Missing brew ID in intent")
            return
        }
        
        val stage = intent.getStringExtra("stage")
        val deepLink = intent.getStringExtra("deepLink")
        
        Log.d(TAG, "Processing action: $actionId for brew: $brewId")
        
        // Generate deep link URL if not provided
        val finalDeepLink = deepLink ?: generateDeepLink(actionId, brewId)
        
        Log.d(TAG, "Deep link: $finalDeepLink")
        
        // Forward action to MainActivity for delivery to Flutter
        MainActivity.handleNotificationAction(
            context = context,
            actionId = actionId,
            brewId = brewId,
            deepLink = finalDeepLink
        )
    }

    /**
     * Generates a deep link URL for the given action and brew ID.
     *
     * This method maps action identifiers to deep link paths that the Flutter
     * app can use for navigation. The deep link format matches the iOS implementation:
     * `firstcrack://brew/{brewId}/{action}`
     *
     * Action Identifier Mapping:
     * * pause_grinding → firstcrack://brew/{brewId}/pause
     * * adjust_grind → firstcrack://brew/{brewId}/settings
     * * skip_preinfusion → firstcrack://brew/{brewId}/skip-preinfusion
     * * extend_preinfusion → firstcrack://brew/{brewId}/extend-preinfusion
     * * stop_shot → firstcrack://brew/{brewId}/stop
     * * view_live → firstcrack://brew/{brewId}/live
     * * brew_again → firstcrack://brew/{brewId}/repeat
     * * adjust_profile → firstcrack://brew/{brewId}/profile
     * * share → firstcrack://brew/{brewId}/share
     *
     * @param actionId The action identifier from the notification
     * @param brewId The unique brew session identifier
     * @return Deep link URL string for navigation
     */
    private fun generateDeepLink(actionId: String, brewId: String): String {
        // Validate brew ID format to prevent injection attacks
        // Brew IDs should be alphanumeric with optional hyphens and underscores
        val brewIdPattern = Regex("^[a-zA-Z0-9_-]+$")
        if (!brewId.matches(brewIdPattern)) {
            Log.w(TAG, "Invalid brew ID format: $brewId")
            return "firstcrack://brew/$brewId/details"
        }
        
        // Map action identifier to deep link path
        val actionPath = when (actionId) {
            "pause_grinding" -> "pause"
            "adjust_grind" -> "settings"
            "skip_preinfusion" -> "skip-preinfusion"
            "extend_preinfusion" -> "extend-preinfusion"
            "stop_shot" -> "stop"
            "view_live" -> "live"
            "brew_again" -> "repeat"
            "adjust_profile" -> "profile"
            "share" -> "share"
            else -> {
                Log.w(TAG, "Unknown action identifier: $actionId")
                "details"
            }
        }
        
        // Construct deep link URL
        return "firstcrack://brew/$brewId/$actionPath"
    }
}
