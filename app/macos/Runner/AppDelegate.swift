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
    
    print("First Crack: Registered for remote notifications")
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
  
  /// Called when the user interacts with a notification (tap or action button).
  ///
  /// This method handles notification taps and action button presses. The response is
  /// forwarded to the Flutter app via the firebase_messaging plugin for deep linking
  /// and navigation.
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
    let userInfo = response.notification.request.content.userInfo
    print("First Crack: User interacted with notification: \(response.actionIdentifier)")
    print("First Crack: Notification data: \(userInfo)")
    
    // The firebase_messaging plugin will handle the response
    // and forward it to the Flutter app
    
    completionHandler()
  }
}
