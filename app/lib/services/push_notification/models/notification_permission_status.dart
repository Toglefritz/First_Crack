part of '../push_notification_service.dart';

/// Represents the current status of notification permissions.
///
/// This enum maps to the various permission states that can exist across different platforms (iOS, Android, macOS,
/// Web).
enum NotificationPermissionStatus {
  /// Permission has not been requested yet.
  ///
  /// This is the initial state before the user has been prompted for notification permissions. On iOS/macOS, this means
  /// the permission dialog has not been shown. On Android 12 and below, this state may not exist as permissions are
  /// granted by default.
  notDetermined,

  /// User has explicitly denied notification permissions.
  ///
  /// The app cannot send notifications and the user must manually enable them in system settings. On iOS/macOS, this
  /// means the user tapped "Don't Allow" in the permission dialog. On Android 13+, this means the user denied the
  /// POST_NOTIFICATIONS permission.
  denied,

  /// User has granted full notification permissions.
  ///
  /// The app can send notifications with alerts, sounds, and badges. This is the desired state for full notification
  /// functionality.
  authorized,

  /// User has granted provisional notification permissions (iOS only).
  ///
  /// Provisional authorization allows the app to send quiet notifications that appear in the notification center but
  /// don't display alerts or play sounds. This is an iOS-specific feature that allows apps to demonstrate the value of
  /// notifications before requesting full permission.
  ///
  /// On other platforms, this status is not used.
  provisional,
}
