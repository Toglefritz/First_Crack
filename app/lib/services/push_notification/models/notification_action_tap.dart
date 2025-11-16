part of '../push_notification_service.dart';

/// Represents a notification action tap event.
///
/// This class combines the action that was tapped with the full notification data context, allowing handlers to respond
/// appropriately.
class NotificationActionTap {
  /// The action that was tapped.
  final NotificationAction action;

  /// The full notification data associated with this action.
  final Map<String, dynamic> notificationData;

  /// Creates a notification action tap event.
  const NotificationActionTap({
    required this.action,
    required this.notificationData,
  });
}
