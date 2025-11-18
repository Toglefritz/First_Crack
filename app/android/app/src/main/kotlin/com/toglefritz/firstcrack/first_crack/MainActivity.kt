package com.toglefritz.firstcrack.first_crack

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main activity for the First Crack Android app.
 *
 * This activity serves as the entry point for the Flutter application and handles
 * communication between native Android code and Flutter via method channels.
 *
 * Key Responsibilities:
 * * Configure method channel for notification action handling
 * * Process notification taps when app is launched from notifications
 * * Forward notification actions to Flutter for navigation and business logic
 * * Handle app lifecycle events
 *
 * The activity implements a static method for sending notification actions to Flutter,
 * allowing the NotificationActionReceiver to forward actions even when the app is
 * not in the foreground.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val NOTIFICATION_CHANNEL = "com.toglefritz.firstcrack/notifications"
        
        /**
         * Static reference to the method channel for notification actions.
         *
         * This allows the NotificationActionReceiver to send actions to Flutter
         * even when the MainActivity is not in the foreground. The channel is
         * initialized when the Flutter engine is configured.
         */
        private var notificationMethodChannel: MethodChannel? = null
        
        /**
         * Handles notification actions from the NotificationActionReceiver.
         *
         * This static method allows the broadcast receiver to forward notification
         * actions to Flutter via the method channel. If the app is not running,
         * this method launches the MainActivity with the action data.
         *
         * @param context The application context
         * @param actionId The action identifier (e.g., "pause_grinding")
         * @param brewId The unique brew session identifier
         * @param deepLink The deep link URL for navigation
         */
        fun handleNotificationAction(
            context: Context,
            actionId: String,
            brewId: String,
            deepLink: String
        ) {
            Log.d(TAG, "Handling notification action: $actionId for brew: $brewId")
            
            // Try to send via method channel if available
            notificationMethodChannel?.let { channel ->
                val arguments = mapOf(
                    "action" to actionId,
                    "brewId" to brewId,
                    "deepLink" to deepLink
                )
                
                channel.invokeMethod("onNotificationAction", arguments)
                Log.d(TAG, "Sent action to Flutter via method channel")
            } ?: run {
                // Method channel not available, launch activity with action data
                Log.d(TAG, "Method channel not available, launching activity")
                
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("notification_action", true)
                    putExtra("actionId", actionId)
                    putExtra("brewId", brewId)
                    putExtra("deepLink", deepLink)
                }
                
                context.startActivity(intent)
            }
        }
    }

    /**
     * Called when the activity is created.
     *
     * This method checks if the activity was launched from a notification tap
     * and processes any pending notification actions.
     *
     * @param savedInstanceState Saved instance state bundle
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if launched from notification
        handleNotificationIntent(intent)
    }

    /**
     * Called when a new intent is received while the activity is running.
     *
     * This handles notification taps when the app is already in the foreground
     * or background.
     *
     * @param intent The new intent
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        // Handle notification intent
        handleNotificationIntent(intent)
    }

    /**
     * Configures the Flutter engine and sets up method channels.
     *
     * This method is called when the Flutter engine is attached to the activity.
     * It sets up the notification method channel for communication between
     * native Android code and Flutter.
     *
     * @param flutterEngine The Flutter engine instance
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up notification method channel
        notificationMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        )
        
        Log.d(TAG, "Notification method channel configured")
    }

    /**
     * Cleans up the method channel when the Flutter engine is detached.
     *
     * @param flutterEngine The Flutter engine instance
     */
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        notificationMethodChannel = null
        Log.d(TAG, "Notification method channel cleaned up")
    }

    /**
     * Processes notification intents and forwards action data to Flutter.
     *
     * This method extracts notification action data from the intent and sends
     * it to Flutter via the method channel. It handles both notification body
     * taps and action button taps.
     *
     * @param intent The intent containing notification data
     */
    private fun handleNotificationIntent(intent: Intent?) {
        intent ?: return
        
        // Check if this is a notification tap
        val isNotificationTap = intent.getBooleanExtra("notification_tap", false)
        val isNotificationAction = intent.getBooleanExtra("notification_action", false)
        
        if (!isNotificationTap && !isNotificationAction) {
            return
        }
        
        Log.d(TAG, "Processing notification intent")
        
        // Extract notification data
        val brewId = intent.getStringExtra("brewId")
        val actionId = intent.getStringExtra("actionId") ?: intent.getStringExtra("action") ?: "default"
        val deepLink = intent.getStringExtra("deepLink")
        
        if (brewId == null) {
            Log.w(TAG, "Missing brew ID in notification intent")
            return
        }
        
        Log.d(TAG, "Brew ID: $brewId, Action: $actionId")
        
        // Generate deep link if not provided
        val finalDeepLink = deepLink ?: generateDeepLink(actionId, brewId)
        
        Log.d(TAG, "Deep link: $finalDeepLink")
        
        // Send to Flutter via method channel
        notificationMethodChannel?.let { channel ->
            val arguments = mapOf(
                "action" to actionId,
                "brewId" to brewId,
                "deepLink" to finalDeepLink
            )
            
            channel.invokeMethod("onNotificationAction", arguments)
            Log.d(TAG, "Sent notification action to Flutter")
        } ?: run {
            Log.w(TAG, "Method channel not available yet, action will be lost")
        }
        
        // Clear the intent extras to prevent reprocessing
        intent.removeExtra("notification_tap")
        intent.removeExtra("notification_action")
        intent.removeExtra("brewId")
        intent.removeExtra("actionId")
        intent.removeExtra("action")
        intent.removeExtra("deepLink")
    }

    /**
     * Generates a deep link URL for the given action and brew ID.
     *
     * This method maps action identifiers to deep link paths that the Flutter
     * app can use for navigation. The deep link format matches the iOS implementation.
     *
     * @param actionId The action identifier
     * @param brewId The unique brew session identifier
     * @return Deep link URL string for navigation
     */
    private fun generateDeepLink(actionId: String, brewId: String): String {
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
            "default" -> "details"
            else -> "details"
        }
        
        return "firstcrack://brew/$brewId/$actionPath"
    }
}

