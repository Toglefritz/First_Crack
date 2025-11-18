package com.toglefritz.firstcrack.first_crack

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL

/**
 * Firebase Cloud Messaging service for handling brew notifications.
 *
 * This service receives FCM messages in all app states (foreground, background, terminated)
 * and builds rich notifications with images and action buttons. It mirrors the functionality
 * of the iOS Notification Service Extension, providing:
 *
 * * Automatic media download and attachment
 * * Rich notification layouts with BigPictureStyle
 * * Stage-specific action buttons
 * * Notification updates using brew ID as tag
 * * Deep link integration for navigation
 *
 * The service processes FCM data payloads and constructs NotificationCompat notifications
 * with appropriate styling, actions, and content based on the current brew stage.
 */
class BrewNotificationService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "BrewNotificationService"
        private const val CHANNEL_ID = "brew_notifications"
        private const val CHANNEL_NAME = "Brew Notifications"
        private const val CHANNEL_DESCRIPTION = "Notifications for coffee brewing progress and updates"
        private const val IMAGE_DOWNLOAD_TIMEOUT_MS = 10000
        private const val MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024 // 5MB
    }

    /**
     * Called when a new FCM token is generated.
     *
     * This happens on initial app install, after app reinstall, or when the user
     * clears app data. The new token should be sent to your backend server for
     * future notification delivery.
     *
     * @param token The new FCM registration token
     */
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token generated: $token")
        
        // TODO: Send token to backend server
        // This will be implemented when API integration is added
    }

    /**
     * Called when a message is received from FCM.
     *
     * This method processes the FCM data payload and builds a rich notification
     * with images, action buttons, and stage-specific content. The notification
     * is displayed using the Android notification system.
     *
     * IMPORTANT: This service only handles data-only messages. If the FCM message
     * includes a notification payload, Android will display it automatically and
     * this method may not be called when the app is in the background.
     *
     * Processing Steps:
     * 1. Parse FCM data payload
     * 2. Create notification channel (Android 8.0+)
     * 3. Download media asynchronously if present
     * 4. Build notification with appropriate style and actions
     * 5. Display notification with brew ID as tag for updates
     *
     * @param remoteMessage The FCM message containing notification data
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d(TAG, "Message received from FCM")
        Log.d(TAG, "Message ID: ${remoteMessage.messageId}")
        Log.d(TAG, "Data payload: ${remoteMessage.data}")
        
        // Check if message has notification payload (should not for brew notifications)
        if (remoteMessage.notification != null) {
            Log.w(TAG, "Message has notification payload - this will prevent custom handling in background")
            Log.w(TAG, "Notification title: ${remoteMessage.notification?.title}")
            Log.w(TAG, "Notification body: ${remoteMessage.notification?.body}")
            Log.w(TAG, "Image URL: ${remoteMessage.notification?.imageUrl}")
        }
        
        // Ensure notification channel exists
        createNotificationChannel()
        
        // Parse notification data from FCM payload
        val data = remoteMessage.data
        
        if (data.isEmpty()) {
            Log.w(TAG, "Received message with empty data payload")
            return
        }
        
        // Extract required fields
        val brewId = data["brewId"] ?: run {
            Log.e(TAG, "Missing brewId in notification data")
            return
        }
        
        val stage = data["stage"] ?: "heating"
        val title = data["title"] ?: "First Crack"
        val body = data["body"] ?: ""
        
        Log.d(TAG, "Processing notification for brew: $brewId, stage: $stage")
        
        // Build and display notification asynchronously
        CoroutineScope(Dispatchers.IO).launch {
            try {
                displayBrewNotification(brewId, stage, title, body, data)
            } catch (e: Exception) {
                Log.e(TAG, "Error displaying notification", e)
            }
        }
    }

    /**
     * Creates the notification channel for brew notifications.
     *
     * Notification channels are required on Android 8.0 (API 26) and above.
     * The channel allows users to customize notification behavior including
     * sound, vibration, and importance level.
     *
     * Channel Configuration:
     * * ID: brew_notifications
     * * Name: Brew Notifications
     * * Importance: HIGH (shows as heads-up notification)
     * * Features: Lights, vibration, sound enabled
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            Log.d(TAG, "Notification channel created: $CHANNEL_ID")
        }
    }

    /**
     * Builds and displays a rich brew notification.
     *
     * This method constructs a NotificationCompat notification with:
     * * Title, body, and subtitle from FCM payload
     * * Downloaded image using BigPictureStyle
     * * Stage-specific action buttons
     * * Deep link for notification tap
     * * Brew ID as tag for notification updates
     *
     * The notification is displayed using the NotificationManager and will
     * update any existing notification with the same brew ID tag.
     *
     * @param brewId Unique identifier for the brew session
     * @param stage Current brew stage (heating, grinding, etc.)
     * @param title Notification title
     * @param body Notification body text
     * @param data Complete FCM data payload
     */
    private suspend fun displayBrewNotification(
        brewId: String,
        stage: String,
        title: String,
        body: String,
        data: Map<String, String>
    ) {
        // Download image if present
        val bitmap = data["imageUrl"]?.let { imageUrl ->
            downloadImage(imageUrl)
        }
        
        // Build subtitle from brew parameters
        val subtitle = buildSubtitle(data)
        
        // Create notification tap intent
        val tapIntent = createNotificationTapIntent(brewId, stage, data)
        val tapPendingIntent = PendingIntent.getActivity(
            this,
            brewId.hashCode(),
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Build notification
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setSubText(subtitle)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setAutoCancel(false) // Don't auto-cancel so actions remain visible
            .setOngoing(false) // Not an ongoing notification
            .setContentIntent(tapPendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC) // Show on lock screen
        
        // Add stage-specific action buttons BEFORE setting style
        // This ensures actions are visible in both collapsed and expanded states
        addActionsForStage(notificationBuilder, stage, brewId, data)
        
        // Add large image if downloaded successfully
        if (bitmap != null) {
            notificationBuilder
                .setLargeIcon(bitmap)
                .setStyle(
                    NotificationCompat.BigPictureStyle()
                        .bigPicture(bitmap)
                        .bigLargeIcon(null as Bitmap?) // Hide large icon when expanded
                        .showBigPictureWhenCollapsed(true) // Show image even when collapsed
                )
        }
        
        // Display notification
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(
            brewId, // Use brew ID as tag for updates
            brewId.hashCode(), // Use hash as notification ID
            notificationBuilder.build()
        )
        
        Log.d(TAG, "Notification displayed for brew: $brewId, stage: $stage")
    }

    /**
     * Builds the notification subtitle from brew parameters.
     *
     * The subtitle provides key brew information at a glance:
     * * Format: "{brewType} • {dose}g @ {temperature}°C"
     * * Example: "Espresso • 18g @ 93°C"
     *
     * This mirrors the iOS Notification Service Extension subtitle generation.
     *
     * @param data FCM data payload containing brew parameters
     * @return Formatted subtitle string
     */
    private fun buildSubtitle(data: Map<String, String>): String {
        val brewType = data["brewType"] ?: "Espresso"
        val dose = data["dose"] ?: "18"
        val temperature = data["temperature"] ?: "93"
        
        return "$brewType • ${dose}g @ ${temperature}°C"
    }

    /**
     * Creates an intent for handling notification body taps.
     *
     * When the user taps the notification body (not an action button), this
     * intent launches the MainActivity with the brew ID and stage data. The
     * MainActivity will forward this to Flutter via method channel for navigation.
     *
     * @param brewId Unique identifier for the brew session
     * @param stage Current brew stage
     * @param data Complete FCM data payload
     * @return Intent configured for notification tap handling
     */
    private fun createNotificationTapIntent(
        brewId: String,
        stage: String,
        data: Map<String, String>
    ): Intent {
        return Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("notification_tap", true)
            putExtra("brewId", brewId)
            putExtra("stage", stage)
            putExtra("action", "default")
            
            // Add deep link if present
            data["deepLink"]?.let { deepLink ->
                putExtra("deepLink", deepLink)
            }
        }
    }

    /**
     * Adds stage-specific action buttons to the notification.
     *
     * Each brew stage has appropriate action buttons that allow users to
     * control the brew process directly from the notification. This mirrors
     * the iOS notification categories and actions.
     *
     * Stage Action Mapping:
     * * heating - No actions (informational only)
     * * grinding - Pause Grinding, Adjust Settings
     * * preInfusion - Skip to Extraction, Extend Pre-Infusion
     * * brewing - Stop Shot Now, View Live
     * * complete - Brew Again, Adjust Profile, Share
     *
     * @param builder NotificationCompat.Builder to add actions to
     * @param stage Current brew stage
     * @param brewId Unique identifier for the brew session
     * @param data Complete FCM data payload
     */
    private fun addActionsForStage(
        builder: NotificationCompat.Builder,
        stage: String,
        brewId: String,
        data: Map<String, String>
    ) {
        Log.d(TAG, "Adding actions for stage: $stage")
        
        when (stage) {
            "heating" -> {
                // No actions for heating stage
                Log.d(TAG, "No actions for heating stage")
            }
            "grinding" -> {
                Log.d(TAG, "Adding 2 actions for grinding stage")
                builder.addAction(
                    createNotificationAction(
                        "pause_grinding",
                        "Pause Grinding",
                        brewId,
                        data
                    )
                )
                builder.addAction(
                    createNotificationAction(
                        "adjust_grind",
                        "Adjust Settings",
                        brewId,
                        data
                    )
                )
            }
            "preInfusion" -> {
                Log.d(TAG, "Adding 2 actions for preInfusion stage")
                builder.addAction(
                    createNotificationAction(
                        "skip_preinfusion",
                        "Skip to Extraction",
                        brewId,
                        data
                    )
                )
                builder.addAction(
                    createNotificationAction(
                        "extend_preinfusion",
                        "Extend Pre-Infusion",
                        brewId,
                        data
                    )
                )
            }
            "brewing" -> {
                Log.d(TAG, "Adding 2 actions for brewing stage")
                builder.addAction(
                    createNotificationAction(
                        "stop_shot",
                        "Stop Shot Now",
                        brewId,
                        data
                    )
                )
                builder.addAction(
                    createNotificationAction(
                        "view_live",
                        "View Live",
                        brewId,
                        data
                    )
                )
            }
            "complete" -> {
                Log.d(TAG, "Adding 3 actions for complete stage")
                builder.addAction(
                    createNotificationAction(
                        "brew_again",
                        "Brew Again",
                        brewId,
                        data
                    )
                )
                builder.addAction(
                    createNotificationAction(
                        "adjust_profile",
                        "Adjust Profile",
                        brewId,
                        data
                    )
                )
                builder.addAction(
                    createNotificationAction(
                        "share",
                        "Share",
                        brewId,
                        data
                    )
                )
            }
            else -> {
                Log.w(TAG, "Unknown stage: $stage, no actions added")
            }
        }
    }

    /**
     * Creates a notification action with a PendingIntent.
     *
     * Each action button triggers a broadcast to NotificationActionReceiver,
     * which forwards the action data to Flutter via method channel.
     *
     * @param actionId Unique identifier for the action
     * @param title User-visible action button label
     * @param brewId Unique identifier for the brew session
     * @param data Complete FCM data payload
     * @return NotificationCompat.Action configured with PendingIntent
     */
    private fun createNotificationAction(
        actionId: String,
        title: String,
        brewId: String,
        data: Map<String, String>
    ): NotificationCompat.Action {
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = actionId
            putExtra("brewId", brewId)
            putExtra("actionId", actionId)
            putExtra("stage", data["stage"])
            
            // Add deep link if present
            data["deepLink"]?.let { deepLink ->
                putExtra("deepLink", deepLink)
            }
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            actionId.hashCode() + brewId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Action.Builder(
            getActionIcon(actionId),
            title,
            pendingIntent
        ).build()
    }

    /**
     * Maps action identifiers to appropriate icon resources.
     *
     * Each action button displays an icon alongside its text label.
     * Icons provide visual cues for the action's purpose.
     *
     * @param actionId The action identifier
     * @return Resource ID for the action icon
     */
    private fun getActionIcon(actionId: String): Int {
        return when (actionId) {
            "pause_grinding" -> android.R.drawable.ic_media_pause
            "adjust_grind" -> android.R.drawable.ic_menu_preferences
            "skip_preinfusion" -> android.R.drawable.ic_media_ff
            "extend_preinfusion" -> android.R.drawable.ic_menu_add
            "stop_shot" -> android.R.drawable.ic_delete
            "view_live" -> android.R.drawable.ic_menu_view
            "brew_again" -> android.R.drawable.ic_menu_rotate
            "adjust_profile" -> android.R.drawable.ic_menu_edit
            "share" -> android.R.drawable.ic_menu_share
            else -> android.R.drawable.ic_menu_info_details
        }
    }

    /**
     * Downloads an image from a URL and returns it as a Bitmap.
     *
     * This method performs synchronous HTTP download with timeout and size limits.
     * Large images are automatically resized to fit notification constraints.
     * It should be called from a background thread (IO dispatcher).
     *
     * Download Configuration:
     * * Timeout: 10 seconds
     * * Max size: 5MB
     * * Max dimensions: 1024x1024 (resized if larger)
     * * Error handling: Returns null on failure
     *
     * @param imageUrl URL of the image to download
     * @return Downloaded and resized image as Bitmap, or null if download fails
     */
    private suspend fun downloadImage(imageUrl: String): Bitmap? = withContext(Dispatchers.IO) {
        try {
            Log.d(TAG, "Downloading image: $imageUrl")
            
            val url = URL(imageUrl)
            val connection = url.openConnection() as HttpURLConnection
            
            connection.apply {
                connectTimeout = IMAGE_DOWNLOAD_TIMEOUT_MS
                readTimeout = IMAGE_DOWNLOAD_TIMEOUT_MS
                doInput = true
            }
            
            connection.connect()
            
            // Check response code
            if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                Log.w(TAG, "Image download failed with response code: ${connection.responseCode}")
                return@withContext null
            }
            
            // Check content length
            val contentLength = connection.contentLength
            if (contentLength > MAX_IMAGE_SIZE_BYTES) {
                Log.w(TAG, "Image too large: $contentLength bytes")
                return@withContext null
            }
            
            // Download and decode image with inJustDecodeBounds first to get dimensions
            val inputStream = connection.inputStream
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeStream(inputStream, null, options)
            inputStream.close()
            
            // Calculate sample size for efficient memory usage
            val maxDimension = 1024
            options.inSampleSize = calculateInSampleSize(options, maxDimension, maxDimension)
            options.inJustDecodeBounds = false
            
            // Download again and decode with sample size
            val connection2 = url.openConnection() as HttpURLConnection
            connection2.apply {
                connectTimeout = IMAGE_DOWNLOAD_TIMEOUT_MS
                readTimeout = IMAGE_DOWNLOAD_TIMEOUT_MS
                doInput = true
            }
            connection2.connect()
            
            val inputStream2 = connection2.inputStream
            val bitmap = BitmapFactory.decodeStream(inputStream2, null, options)
            inputStream2.close()
            
            if (bitmap != null) {
                Log.d(TAG, "Image downloaded successfully: ${bitmap.width}x${bitmap.height}")
            } else {
                Log.w(TAG, "Failed to decode image")
            }
            
            bitmap
        } catch (e: Exception) {
            Log.e(TAG, "Error downloading image", e)
            null
        }
    }

    /**
     * Calculates the optimal sample size for decoding a bitmap.
     *
     * This method determines how much to scale down an image during decoding
     * to fit within the specified dimensions while maintaining aspect ratio.
     * Using inSampleSize reduces memory usage significantly for large images.
     *
     * @param options BitmapFactory.Options containing the original image dimensions
     * @param reqWidth Required width in pixels
     * @param reqHeight Required height in pixels
     * @return Sample size value (power of 2) for efficient decoding
     */
    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int
    ): Int {
        val height: Int = options.outHeight
        val width: Int = options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2

            // Calculate the largest inSampleSize value that is a power of 2 and keeps both
            // height and width larger than the requested height and width
            while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }
}
