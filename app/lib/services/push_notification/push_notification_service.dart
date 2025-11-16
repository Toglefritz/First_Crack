/// Service responsible for managing Firebase Cloud Messaging and push notifications.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

part 'models/notification_action_tap.dart';

part 'models/notification_action.dart';

part 'models/notification_data.dart';

part 'models/notification_permission_status.dart';

part 'models/notification_type.dart';

part 'models/pns_brew_stage.dart';

/// Service responsible for managing Firebase Cloud Messaging and push notifications.
///
/// This service handles all aspects of push notification functionality including:
///
/// * Firebase Cloud Messaging (FCM) initialization and configuration
/// * Device token management and retrieval
/// * Notification permission requests
/// * Foreground, background, and terminated state message handling
/// * Local notification display on Android and iOS
/// * Notification action handling and deep linking
/// * Message data parsing and validation
///
/// The service integrates with the First Crack Cloud Functions backend to receive brew stage notifications with rich
/// media content and interactive actions.
///
/// Platform-specific behavior:
///
/// * iOS/macOS: Uses Notification Service Extension for rich notifications
/// * Android: Uses FirebaseMessagingService for custom notification rendering
/// * Web: Uses Service Worker for push notification handling
class PushNotificationService extends ChangeNotifier {
  /// Firebase Messaging instance for FCM operations.
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Flutter Local Notifications plugin for displaying notifications.
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// The current FCM device token. Null if not yet retrieved or unavailable.
  String? _fcmToken;

  /// Current notification permission status.
  NotificationPermissionStatus _permissionStatus = NotificationPermissionStatus.notDetermined;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  /// Stream controller for foreground messages.
  final StreamController<NotificationData> _foregroundMessageController =
      StreamController<NotificationData>.broadcast();

  /// Stream controller for notification taps (when app is in background/terminated).
  final StreamController<NotificationData> _notificationTapController = StreamController<NotificationData>.broadcast();

  /// Stream controller for notification action button taps.
  final StreamController<NotificationActionTap> _actionTapController =
      StreamController<NotificationActionTap>.broadcast();

  // MARK: Getters

  /// Gets the current FCM device token.
  ///
  /// Returns null if the token has not been retrieved yet or if FCM is unavailable on the current platform. The token
  /// is automatically refreshed when it changes.
  String? get fcmToken => _fcmToken;

  /// Gets the current notification permission status.
  NotificationPermissionStatus get permissionStatus => _permissionStatus;

  /// Gets whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Stream of foreground messages received while the app is active.
  ///
  /// Subscribe to this stream to handle notifications when the app is in the foreground. These messages are not
  /// automatically displayed and must be handled manually.
  Stream<NotificationData> get foregroundMessages => _foregroundMessageController.stream;

  /// Stream of notification taps when the app is opened from a notification.
  ///
  /// This stream emits when a user taps a notification while the app is in the background or terminated state. Use this
  /// to handle deep linking and navigation.
  Stream<NotificationData> get notificationTaps => _notificationTapController.stream;

  /// Stream of notification action button taps.
  ///
  /// This stream emits when a user taps an action button on a notification. The action may require opening the app or
  /// can be handled in the background.
  Stream<NotificationActionTap> get actionTaps => _actionTapController.stream;

  // MARK: Initialization

  /// Initializes the push notification service.
  ///
  /// This method must be called before using any other service methods. It performs the following initialization steps:
  /// 1. Ensures Firebase is initialized
  /// 2. Configures local notifications for Android and iOS
  /// 3. Sets up message handlers for all app states
  /// 4. Retrieves the initial FCM token
  /// 5. Listens for token refresh events
  ///
  /// Returns true if initialization was successful, false otherwise.
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('PushNotificationService: Already initialized');
      return true;
    }

    try {
      // Ensure Firebase is initialized
      await Firebase.initializeApp();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up message handlers
      await _setupMessageHandlers();

      // Get initial token
      await _retrieveToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      _isInitialized = true;
      notifyListeners();

      debugPrint('PushNotificationService: Initialized successfully');
      return true;
    } catch (error) {
      debugPrint('PushNotificationService: Initialization failed - $error');
      return false;
    }
  }

  /// Initializes the local notifications plugin for Android and iOS.
  ///
  /// Configures platform-specific settings including:
  ///
  /// * Android: Notification channel, icons, and default settings
  /// * iOS: Alert, badge, and sound settings
  /// * Notification tap handlers for both platforms
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    // Initialize with tap handler
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }
  }

  /// Creates the Android notification channel for brew notifications.
  ///
  /// This channel is used for all brew-related notifications and is configured with high importance to ensure
  /// notifications are displayed prominently.
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'brew_notifications', // Channel ID
      'Brew Notifications', // Channel name
      description: 'Notifications for coffee brewing progress and updates',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Sets up message handlers for all app states.
  ///
  /// Configures handlers for:
  ///
  /// * Foreground messages (app is active)
  /// * Background messages (app is in background)
  /// * Terminated messages (app was closed)
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    await _checkInitialMessage();
  }

  // MARK: Token Management

  /// Retrieves the FCM device token from Firebase.
  ///
  /// The token is used to send push notifications to this specific device. Returns the token string or null if
  /// unavailable.
  Future<String?> _retrieveToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _fcmToken = token;
        notifyListeners();
        debugPrint('PushNotificationService: FCM Token retrieved');
        debugPrint('Token: $token');
      }
      return token;
    } catch (error) {
      debugPrint('PushNotificationService: Failed to get token - $error');
      return null;
    }
  }

  /// Handles FCM token refresh events.
  ///
  /// Called automatically when the FCM token changes. Updates the stored token and notifies listeners. The new token
  /// should be sent to your backend.
  void _onTokenRefresh(String newToken) {
    _fcmToken = newToken;
    notifyListeners();
    debugPrint('PushNotificationService: Token refreshed');
    debugPrint('New Token: $newToken');

    // TODO(Toglefritz): Send new token to backend when API integration is added
  }

  /// Manually refreshes the FCM token.
  ///
  /// Forces FCM to generate a new token. This is rarely needed as tokens are automatically refreshed when necessary.
  ///
  /// Returns the new token or null if the operation fails.
  Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      return await _retrieveToken();
    } catch (error) {
      debugPrint('PushNotificationService: Token refresh failed - $error');
      return null;
    }
  }

  // MARK: Permissions

  /// Requests notification permissions from the user.
  ///
  /// On iOS/macOS, this displays the system permission dialog. On Android 13+, this requests the POST_NOTIFICATIONS
  /// permission. On older Android versions, permissions are granted automatically.
  ///
  /// Returns the permission status after the request.
  Future<NotificationPermissionStatus> requestPermission() async {
    try {
      final NotificationSettings settings = await _firebaseMessaging.requestPermission();

      _permissionStatus = _convertAuthorizationStatus(settings.authorizationStatus);
      notifyListeners();

      debugPrint(
        'PushNotificationService: Permission status - ${_permissionStatus.name}',
      );

      return _permissionStatus;
    } catch (error) {
      debugPrint('PushNotificationService: Permission request failed - $error');
      return NotificationPermissionStatus.denied;
    }
  }

  /// Checks the current notification permission status without requesting.
  ///
  /// Returns the current permission status. This does not trigger a permission dialog and can be called at any time.
  Future<NotificationPermissionStatus> checkPermissionStatus() async {
    try {
      final NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();

      _permissionStatus = _convertAuthorizationStatus(settings.authorizationStatus);
      notifyListeners();

      return _permissionStatus;
    } catch (error) {
      debugPrint('PushNotificationService: Permission check failed - $error');
      return NotificationPermissionStatus.notDetermined;
    }
  }

  /// Converts FCM authorization status to our custom enum.
  NotificationPermissionStatus _convertAuthorizationStatus(
    AuthorizationStatus status,
  ) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return NotificationPermissionStatus.authorized;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionStatus.notDetermined;
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.provisional;
    }
  }

  // MARK: Message Handlers

  /// Handles messages received while the app is in the foreground.
  ///
  /// Foreground messages are not automatically displayed by the system. This handler parses the message data and emits
  /// it to the foreground messages stream for the app to handle.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('PushNotificationService: Foreground message received');
    debugPrint('Message ID: ${message.messageId}');

    final NotificationData? data = _parseMessageData(message);
    if (data != null) {
      _foregroundMessageController.add(data);

      // Optionally display a local notification for foreground messages
      await _displayLocalNotification(data);
    }
  }

  /// Handles notification taps when the app is opened from background.
  ///
  /// Called when a user taps a notification while the app is in the background. Parses the message data and emits it to
  /// the notification taps stream.
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('PushNotificationService: Notification opened app');
    debugPrint('Message ID: ${message.messageId}');

    final NotificationData? data = _parseMessageData(message);
    if (data != null) {
      _notificationTapController.add(data);
    }
  }

  /// Checks for an initial message when the app was opened from terminated state.
  ///
  /// If the app was launched by tapping a notification, this retrieves the message data and emits it to the
  /// notification taps stream.
  Future<void> _checkInitialMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('PushNotificationService: App opened from notification');
      debugPrint('Message ID: ${initialMessage.messageId}');

      final NotificationData? data = _parseMessageData(initialMessage);
      if (data != null) {
        _notificationTapController.add(data);
      }
    }
  }

  /// Handles notification taps from local notifications.
  ///
  /// Called when a user taps a local notification or an action button. Parses the payload and emits appropriate events.
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('PushNotificationService: Local notification tapped');
    debugPrint('Action ID: ${response.actionId}');

    // TODO(Toglefritz): Parse payload and emit to appropriate stream
  }

  // MARK: Data Parsing

  /// Parses FCM message data into a structured NotificationData object.
  ///
  /// Extracts and validates all fields from the message data payload. Returns null if the message data is invalid or
  /// missing required fields.
  NotificationData? _parseMessageData(RemoteMessage message) {
    try {
      final Map<String, dynamic> data = message.data;

      if (data.isEmpty) {
        debugPrint('PushNotificationService: Message has no data payload');
        return null;
      }

      return NotificationData.fromMap(data);
    } catch (error) {
      debugPrint('PushNotificationService: Failed to parse message data - $error');
      return null;
    }
  }

  // MARK: Local Notification Display

  /// Displays a local notification for the given notification data.
  ///
  /// This is used to show notifications when the app is in the foreground, as FCM does not automatically display
  /// foreground messages.
  Future<void> _displayLocalNotification(NotificationData data) async {
    try {
      // Android notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'brew_notifications',
        'Brew Notifications',
        channelDescription: 'Notifications for coffee brewing progress',
        importance: Importance.high,
        priority: Priority.high,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      // Display the notification
      await _localNotifications.show(
        data.hashCode, // Use data hash as notification ID
        data.title,
        data.body,
        notificationDetails,
        payload: data.toJson(),
      );

      debugPrint('PushNotificationService: Local notification displayed');
    } catch (error) {
      debugPrint(
        'PushNotificationService: Failed to display local notification - $error',
      );
    }
  }

  // MARK: Cleanup

  /// Disposes of the service and closes all streams.
  ///
  /// Call this when the service is no longer needed to prevent memory leaks.
  @override
  void dispose() {
    unawaited(_foregroundMessageController.close());
    unawaited(_notificationTapController.close());
    unawaited(_actionTapController.close());

    super.dispose();
  }
}
