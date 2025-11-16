part of '../push_notification_service.dart';

/// Model representing an interactive action button on a notification.
///
/// Actions allow users to interact with notifications without opening the app. Examples include "Start Brew", "Cancel",
/// "View Details", etc.
///
/// Each action has an identifier, display text, and optional configuration for icons, foreground requirements, and deep
/// linking.
class NotificationAction {
  /// Unique identifier for this action.
  ///
  /// Used to identify which action was tapped when handling user interactions. Examples: "start_brew", "cancel",
  /// "view_details"
  final String id;

  /// Display text shown on the action button.
  ///
  /// This is the user-visible label for the action. Examples: "Start Brew", "Cancel", "View Details"
  final String title;

  /// Optional icon name for the action button.
  ///
  /// The icon name is platform-specific and must be mapped to actual icon resources in the native code. Examples:
  /// "play", "stop", "info"
  final String? icon;

  /// Whether this action requires the app to be in the foreground.
  ///
  /// If true, tapping this action will open the app before executing. If false, the action can be handled in the
  /// background without opening the app (platform support varies).
  final bool requiresForeground;

  /// Optional deep link URL to navigate to when the action is tapped.
  ///
  /// Format: firstcrack://path/to/screen Example: firstcrack://brew/start
  final String? deepLink;

  /// Additional data to pass with the action.
  ///
  /// This map can contain any custom data needed to handle the action. The data is preserved when the action is tapped
  /// and can be used for context-specific handling.
  final Map<String, String> data;

  /// Creates a notification action.
  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.requiresForeground = false,
    this.deepLink,
    this.data = const <String, String>{},
  });

  /// Creates a NotificationAction from a map.
  ///
  /// Used when parsing actions from the FCM message data payload. The actions are sent as a JSON-encoded array in the
  /// message.
  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      icon: map['icon'] as String?,
      requiresForeground: map['requiresForeground'] as bool? ?? false,
      deepLink: map['deepLink'] as String?,
      data: Map<String, String>.from(
        (map['data'] as Map<String, dynamic>?) ?? <String, String>{},
      ),
    );
  }

  /// Converts this action to a map.
  ///
  /// Used when serializing notification data for storage in local notification payloads.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'icon': icon,
      'requiresForeground': requiresForeground,
      'deepLink': deepLink,
      'data': data,
    };
  }
}
