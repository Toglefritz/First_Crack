import Cocoa
import FlutterMacOS
import UserNotifications

/// Application delegate for the First Crack macOS app.
///
/// This delegate handles application lifecycle events and configures push notification
/// support. It registers the app for remote notifications with APNs and sets up the
/// notification center delegate to handle notification interactions.
@main
class AppDelegate: FlutterAppDelegate {
  
  /// Method channel for communicating notification actions to Flutter.
  ///
  /// This channel is used to send notification action button taps and notification body taps
  /// from the native iOS/macOS code to the Flutter app. The Flutter app can then handle
  /// navigation and business logic based on the action.
  ///
  /// Channel name: "com.toglefritz.firstcrack/notifications"
  /// Methods:
  /// * onNotificationAction - Called when user taps notification or action button
  private var notificationChannel: FlutterMethodChannel?
  
  /// Called when the application has finished launching.
  ///
  /// This method registers the app for remote notifications with APNs, which is required
  /// to receive push notifications from Firebase Cloud Messaging. It also sets up the
  /// notification center delegate to handle notification actions and taps.
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Register for remote notifications with APNs
    // This is required for FCM to work on macOS
    NSApplication.shared.registerForRemoteNotifications()
    
    // Set up notification center delegate
    UNUserNotificationCenter.current().delegate = self
    
    // Register notification categories with action buttons
    registerNotificationCategories()
    
    // Set up method channel for Flutter communication
    setupMethodChannel()
    
    print("First Crack: Registered for remote notifications")
  }
  
  /// Sets up the method channel for communicating with Flutter.
  ///
  /// This method initializes the FlutterMethodChannel that will be used to send notification
  /// action data from native code to the Flutter app. The channel is created after the Flutter
  /// engine is available during app launch.
  ///
  /// The method channel allows bidirectional communication between Swift and Dart code:
  /// * Swift can invoke methods on the Flutter side
  /// * Flutter can invoke methods on the Swift side
  ///
  /// For notification actions, we only need Swift-to-Flutter communication, so we invoke
  /// the "onNotificationAction" method when users interact with notifications.
  ///
  /// Error Handling:
  /// * If the Flutter view controller is not available, logs error and continues
  /// * If channel creation fails, logs error and continues without crashing
  /// * Notifications will still work, but action data won't reach Flutter
  private func setupMethodChannel() {
    // Get the Flutter view controller from the main window
    // This is where the Flutter engine is running
    guard let controller = NSApplication.shared.mainWindow?.contentViewController as? FlutterViewController else {
      print("First Crack: Error - Could not get FlutterViewController for method channel setup")
      print("First Crack: Method channel will not be available")
      return
    }
    
    // Create the method channel with the notifications channel name
    // The channel name must match the name used in the Flutter code
    notificationChannel = FlutterMethodChannel(
      name: "com.toglefritz.firstcrack/notifications",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    print("First Crack: Method channel initialized successfully")
    print("First Crack: Channel name: com.toglefritz.firstcrack/notifications")
  }
  
  /// Registers all notification categories with their associated action buttons.
  ///
  /// This method defines five brew stage notification categories, each with stage-appropriate
  /// action buttons that allow users to control the brew process directly from notifications.
  /// Categories are registered with UNUserNotificationCenter and cached by the system.
  ///
  /// Categories:
  /// * BREW_HEATING - No actions (informational only)
  /// * BREW_GRINDING - Pause and adjust controls
  /// * BREW_PREINFUSION - Pre-infusion timing controls
  /// * BREW_EXTRACTION - Extraction controls
  /// * BREW_COMPLETE - Post-brew actions
  ///
  /// Performance: O(1) - Registration happens once at app launch with minimal overhead (< 10ms)
  private func registerNotificationCategories() {
    do {
      let categories = createBrewNotificationCategories()
      UNUserNotificationCenter.current().setNotificationCategories(categories)
      print("First Crack: Successfully registered \(categories.count) notification categories")
    } catch {
      // Log error but don't crash the app - notifications will display without action buttons
      print("First Crack: Failed to register notification categories: \(error.localizedDescription)")
    }
  }
  
  /// Creates all brew stage notification categories with their action buttons.
  ///
  /// Each category corresponds to a specific brew stage and includes action buttons
  /// appropriate for that stage. Action identifiers are used to map button taps to
  /// deep links for navigation within the Flutter app.
  ///
  /// Action Button Configuration:
  /// * identifier - Unique string for programmatic handling (e.g., "pause_grinding")
  /// * title - User-visible button label (e.g., "Pause Grinding")
  /// * options - Activation mode (.foreground opens app, .destructive shows in red)
  ///
  /// @returns Set of configured notification categories ready for registration
  private func createBrewNotificationCategories() -> Set<UNNotificationCategory> {
    var categories = Set<UNNotificationCategory>()
    
    // BREW_HEATING - No actions (informational only)
    // Users can only view the notification, no interactive controls needed during heating
    let heatingCategory = UNNotificationCategory(
      identifier: "BREW_HEATING",
      actions: [],
      intentIdentifiers: [],
      options: .customDismissAction
    )
    categories.insert(heatingCategory)
    
    // BREW_GRINDING - Pause and adjust controls
    // Allows users to pause grinding or adjust grind settings mid-process
    let pauseGrindingAction = UNNotificationAction(
      identifier: "pause_grinding",
      title: "Pause Grinding",
      options: .foreground
    )
    let adjustGrindAction = UNNotificationAction(
      identifier: "adjust_grind",
      title: "Adjust Settings",
      options: .foreground
    )
    let grindingCategory = UNNotificationCategory(
      identifier: "BREW_GRINDING",
      actions: [pauseGrindingAction, adjustGrindAction],
      intentIdentifiers: [],
      options: .customDismissAction
    )
    categories.insert(grindingCategory)
    
    // BREW_PREINFUSION - Pre-infusion timing controls
    // Allows users to skip pre-infusion or extend it for better extraction
    let skipPreinfusionAction = UNNotificationAction(
      identifier: "skip_preinfusion",
      title: "Skip to Extraction",
      options: .foreground
    )
    let extendPreinfusionAction = UNNotificationAction(
      identifier: "extend_preinfusion",
      title: "Extend Pre-Infusion",
      options: .foreground
    )
    let preinfusionCategory = UNNotificationCategory(
      identifier: "BREW_PREINFUSION",
      actions: [skipPreinfusionAction, extendPreinfusionAction],
      intentIdentifiers: [],
      options: .customDismissAction
    )
    categories.insert(preinfusionCategory)
    
    // BREW_EXTRACTION - Extraction controls
    // Allows users to stop extraction early or view live extraction progress
    // Stop action is destructive (red) to indicate it ends the brew
    let stopShotAction = UNNotificationAction(
      identifier: "stop_shot",
      title: "Stop Shot Now",
      options: [.foreground, .destructive]
    )
    let viewLiveAction = UNNotificationAction(
      identifier: "view_live",
      title: "View Live",
      options: .foreground
    )
    let extractionCategory = UNNotificationCategory(
      identifier: "BREW_EXTRACTION",
      actions: [stopShotAction, viewLiveAction],
      intentIdentifiers: [],
      options: .customDismissAction
    )
    categories.insert(extractionCategory)
    
    // BREW_COMPLETE - Post-brew actions
    // Allows users to repeat the brew, adjust the profile, or share results
    let brewAgainAction = UNNotificationAction(
      identifier: "brew_again",
      title: "Brew Again",
      options: .foreground
    )
    let adjustProfileAction = UNNotificationAction(
      identifier: "adjust_profile",
      title: "Adjust Profile",
      options: .foreground
    )
    let shareAction = UNNotificationAction(
      identifier: "share",
      title: "Share",
      options: .foreground
    )
    let completeCategory = UNNotificationCategory(
      identifier: "BREW_COMPLETE",
      actions: [brewAgainAction, adjustProfileAction, shareAction],
      intentIdentifiers: [],
      options: .customDismissAction
    )
    categories.insert(completeCategory)
    
    return categories
  }
  
  /// Called when the app successfully registers for remote notifications.
  ///
  /// The device token is automatically sent to Firebase Cloud Messaging by the
  /// firebase_messaging plugin, so we just log it here for debugging purposes.
  ///
  /// - Parameter application: The application instance
  /// - Parameter deviceToken: The APNs device token
  override func application(
    _ application: NSApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("First Crack: APNs device token: \(tokenString)")
  }
  
  /// Called when the app fails to register for remote notifications.
  ///
  /// This typically happens when:
  /// - The app is running in the simulator (APNs not supported)
  /// - The APNs certificate/key is not configured in Firebase
  /// - Network connectivity issues
  /// - Entitlements are not properly configured
  ///
  /// - Parameter application: The application instance
  /// - Parameter error: The error that occurred during registration
  override func application(
    _ application: NSApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("First Crack: Failed to register for remote notifications: \(error.localizedDescription)")
  }
  
  /// Called when a remote notification is received while the app is in the foreground.
  ///
  /// This method is called by APNs when a notification arrives. The firebase_messaging
  /// plugin handles the notification processing, but we log it here for debugging.
  ///
  /// - Parameter application: The application instance
  /// - Parameter userInfo: The notification payload
  override func application(
    _ application: NSApplication,
    didReceiveRemoteNotification userInfo: [String: Any]
  ) {
    print("First Crack: Received remote notification: \(userInfo)")
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
  
  /// Called when a notification is about to be presented while the app is in the foreground.
  ///
  /// This method determines how the notification should be displayed when the app is active.
  /// We allow all presentation options (banner, sound, badge) so users can see notifications
  /// even when the app is open.
  ///
  /// - Parameters:
  ///   - center: The notification center
  ///   - notification: The notification to be presented
  ///   - completionHandler: Handler to call with presentation options
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("First Crack: Will present notification: \(notification.request.identifier)")
    
    // Show notification even when app is in foreground
    completionHandler([.banner, .sound, .badge])
  }
  
  /// Maps notification action identifiers to their corresponding deep link URLs.
  ///
  /// This function converts action button identifiers into deep link URLs that the Flutter
  /// app can use for navigation. Each action identifier corresponds to a specific brew
  /// control or navigation target within the app.
  ///
  /// Deep Link Format: `firstcrack://brew/{brewId}/{action}`
  ///
  /// Supported Action Identifiers:
  /// * pause_grinding - Pause the grinding operation
  /// * adjust_grind - Open grind settings screen
  /// * skip_preinfusion - Skip pre-infusion and start extraction
  /// * extend_preinfusion - Add additional pre-infusion time
  /// * stop_shot - Stop extraction immediately
  /// * view_live - View live extraction progress
  /// * brew_again - Repeat the same brew with identical settings
  /// * adjust_profile - Edit the brew profile parameters
  /// * share - Share brew results with others
  /// * default - Default action for notification body tap (view brew details)
  ///
  /// - Parameters:
  ///   - actionIdentifier: The action identifier from the notification response
  ///   - brewId: The unique identifier for the brew session
  /// - Returns: Deep link URL string for navigation, or nil if action is invalid
  private func mapActionToDeepLink(actionIdentifier: String, brewId: String) -> String? {
    // Validate brew ID format to prevent injection attacks
    // Brew IDs should be alphanumeric with optional hyphens and underscores
    let brewIdPattern = "^[a-zA-Z0-9_-]+$"
    guard brewId.range(of: brewIdPattern, options: .regularExpression) != nil else {
      print("First Crack: Invalid brew ID format: \(brewId)")
      return nil
    }
    
    // Map action identifier to deep link path
    let actionPath: String
    
    switch actionIdentifier {
    case "pause_grinding":
      actionPath = "pause"
    case "adjust_grind":
      actionPath = "settings"
    case "skip_preinfusion":
      actionPath = "skip-preinfusion"
    case "extend_preinfusion":
      actionPath = "extend-preinfusion"
    case "stop_shot":
      actionPath = "stop"
    case "view_live":
      actionPath = "live"
    case "brew_again":
      actionPath = "repeat"
    case "adjust_profile":
      actionPath = "profile"
    case "share":
      actionPath = "share"
    case UNNotificationDefaultActionIdentifier:
      // User tapped notification body (not an action button)
      actionPath = "details"
    default:
      // Unknown action identifier
      print("First Crack: Unknown action identifier: \(actionIdentifier)")
      return nil
    }
    
    // Construct deep link URL with brew ID substitution
    let deepLink = "firstcrack://brew/\(brewId)/\(actionPath)"
    
    return deepLink
  }
  
  /// Called when the user interacts with a notification (tap or action button).
  ///
  /// This method handles both notification body taps and action button presses. It extracts
  /// the action identifier and brew ID from the notification, generates the appropriate
  /// deep link URL, and forwards the action data to the Flutter app for navigation.
  ///
  /// Processing Steps:
  /// 1. Extract action identifier from notification response
  /// 2. Retrieve brew ID from notification userInfo
  /// 3. Generate deep link URL using mapping function
  /// 4. Log action for debugging and analytics
  /// 5. Call completion handler to dismiss notification UI
  ///
  /// Error Handling:
  /// * Missing brew ID - Logs error and completes without navigation
  /// * Invalid action identifier - Logs error and completes without navigation
  /// * Invalid brew ID format - Logs error and completes without navigation
  ///
  /// The deep link URL will be handled by the Flutter app's deep link handler,
  /// which will navigate to the appropriate screen based on the action.
  ///
  /// - Parameters:
  ///   - center: The notification center
  ///   - response: The user's response to the notification
  ///   - completionHandler: Handler to call when processing is complete
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // Extract notification data
    let userInfo = response.notification.request.content.userInfo
    let actionIdentifier = response.actionIdentifier
    
    print("First Crack: User interacted with notification")
    print("First Crack: Action identifier: \(actionIdentifier)")
    print("First Crack: Notification data: \(userInfo)")
    
    // Extract brew ID from notification userInfo
    // The brew ID is required for generating the deep link
    guard let brewId = userInfo["brewId"] as? String else {
      print("First Crack: Error - Missing brewId in notification userInfo")
      print("First Crack: Available keys: \(userInfo.keys)")
      // Complete without navigation - user can still open app manually
      completionHandler()
      return
    }
    
    print("First Crack: Brew ID: \(brewId)")
    
    // Generate deep link URL using mapping function
    guard let deepLink = mapActionToDeepLink(actionIdentifier: actionIdentifier, brewId: brewId) else {
      print("First Crack: Error - Failed to generate deep link for action: \(actionIdentifier)")
      // Complete without navigation - fall back to home screen
      completionHandler()
      return
    }
    
    print("First Crack: Generated deep link: \(deepLink)")
    
    // Send action data to Flutter via method channel
    sendActionToFlutter(
      action: actionIdentifier,
      brewId: brewId,
      deepLink: deepLink
    )
    
    // Always call completion handler to dismiss notification UI
    // This must be called within 10 seconds or the system will terminate the app
    completionHandler()
  }
  
  /// Sends notification action data to the Flutter app via method channel.
  ///
  /// This helper method invokes the "onNotificationAction" method on the Flutter side,
  /// passing the action identifier, brew ID, and generated deep link. The Flutter app
  /// can then handle navigation and business logic based on this data.
  ///
  /// The method is called asynchronously and does not wait for a response from Flutter.
  /// Any errors during method invocation are caught and logged without crashing the app.
  ///
  /// Message Format:
  /// ```
  /// {
  ///   "action": String,      // Action identifier (e.g., "pause_grinding")
  ///   "brewId": String,      // Brew ID from notification
  ///   "deepLink": String     // Generated deep link URL
  /// }
  /// ```
  ///
  /// Error Handling:
  /// * If method channel is not initialized, logs error and continues
  /// * If method invocation fails, logs error and continues
  /// * User can still open app manually if method channel fails
  ///
  /// - Parameters:
  ///   - action: The action identifier from the notification response
  ///   - brewId: The unique identifier for the brew session
  ///   - deepLink: The generated deep link URL for navigation
  private func sendActionToFlutter(action: String, brewId: String, deepLink: String) {
    // Check if method channel is available
    guard let channel = notificationChannel else {
      print("First Crack: Error - Method channel not initialized")
      print("First Crack: Cannot send action data to Flutter")
      return
    }
    
    // Prepare arguments map for Flutter
    let arguments: [String: String] = [
      "action": action,
      "brewId": brewId,
      "deepLink": deepLink
    ]
    
    print("First Crack: Sending action to Flutter via method channel")
    print("First Crack: Arguments: \(arguments)")
    
    // Invoke method on Flutter side
    // This is asynchronous and does not wait for a response
    channel.invokeMethod("onNotificationAction", arguments: arguments) { result in
      // Handle method invocation result
      if let error = result as? FlutterError {
        print("First Crack: Method channel error - \(error.code): \(error.message ?? "Unknown error")")
        if let details = error.details {
          print("First Crack: Error details: \(details)")
        }
      } else {
        print("First Crack: Action data sent to Flutter successfully")
      }
    }
  }
}
