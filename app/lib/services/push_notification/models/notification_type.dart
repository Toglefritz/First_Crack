part of '../push_notification_service.dart';

/// Enum representing the type of notification.
///
/// Different notification types may be displayed or handled differently in the app. The type is sent in the FCM message
/// data payload.
enum NotificationType {
  /// A brew stage notification showing progress through the brew cycle.
  ///
  /// These notifications are sent at each stage of the brewing process (heating, ready, pre-infusion, extraction,
  /// complete).
  brewStage('brew_stage'),

  /// An alert notification about the brew process.
  ///
  /// These are informational or warning notifications that don't correspond to a specific brew stage.
  brewAlert('brew_alert'),

  /// A notification indicating the brew is complete.
  ///
  /// This is the final notification in the brew cycle, typically including a summary and final image.
  brewComplete('brew_complete');

  /// The string value used in FCM messages.
  final String value;

  /// Creates a notification type with the given string value.
  const NotificationType(this.value);

  /// Creates a NotificationType from a string value.
  ///
  /// Returns [brewStage] if the string doesn't match any known type.
  factory NotificationType.fromString(String value) {
    switch (value) {
      case 'brew_stage':
        return NotificationType.brewStage;
      case 'brew_alert':
        return NotificationType.brewAlert;
      case 'brew_complete':
        return NotificationType.brewComplete;
      default:
        return NotificationType.brewStage;
    }
  }
}
