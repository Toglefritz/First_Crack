part of '../push_notification_service.dart';

/// Data model representing a parsed push notification message.
///
/// This model contains all the structured data from an FCM message sent by the First Crack Cloud Functions backend. It
/// includes brew parameters, media URLs, action buttons, and metadata needed to display rich notifications.
///
/// The data structure matches the FCM message specification defined in the backend documentation
/// (cloud/docs/FCM_MESSAGE_SPEC.md).
class NotificationData {
  /// Type of notification (brew_stage, brew_alert, brew_complete).
  final NotificationType type;

  /// Current brew stage identifier.
  final BrewStage stage;

  /// Unique identifier for this brew session.
  final String brewId;

  /// Notification title text.
  final String title;

  /// Notification body text.
  final String body;

  /// Optional URL to an image for the notification.
  ///
  /// This image is downloaded and displayed in the notification's expanded view. Typical format: JPEG or PNG.
  /// Recommended size: 1200x600px.
  final String? imageUrl;

  /// Optional URL to a video for the notification.
  ///
  /// This video can be displayed in the notification's expanded view on supported platforms. Typical format: MP4.
  /// Recommended size: < 5MB.
  final String? videoUrl;

  /// Deep link URL for navigation when the notification is tapped.
  ///
  /// Format: firstcrack://path/to/screen Example: firstcrack://brew/status
  final String? deepLink;

  /// Progress percentage from 0 to 100.
  ///
  /// Used to display a progress indicator in the notification showing how far along the brew process is.
  final int? progress;

  /// Type of brew (espresso, lungo, ristretto, americano).
  final String brewType;

  /// Coffee dose in grams.
  final double dose;

  /// Water temperature in Celsius.
  final double temperature;

  /// Extraction pressure in bars.
  final double pressure;

  /// Elapsed time since brew started in seconds.
  final int elapsedTime;

  /// Estimated remaining time in seconds.
  final int? remainingTime;

  /// Current flow rate in ml/s (for extraction stages).
  final double? flowRate;

  /// Total volume extracted in ml (for extraction stages).
  final double? volumeExtracted;

  /// Creates a notification data instance.
  const NotificationData({
    required this.type,
    required this.stage,
    required this.brewId,
    required this.title,
    required this.body,
    required this.brewType,
    required this.dose,
    required this.temperature,
    required this.pressure,
    required this.elapsedTime,
    this.imageUrl,
    this.videoUrl,
    this.deepLink,
    this.progress,
    this.remainingTime,
    this.flowRate,
    this.volumeExtracted,
  });

  /// Creates a NotificationData instance from an FCM message data map.
  ///
  /// Parses all fields from the string-based FCM data payload and converts them to the appropriate types. Returns null
  /// if required fields are missing or if parsing fails.
  factory NotificationData.fromMap(Map<String, dynamic> map) {
    // Parse notification type
    final NotificationType type = NotificationType.fromString(
      map['type'] as String? ?? 'brew_stage',
    );

    // Parse brew stage
    final BrewStage stage = BrewStage.fromString(
      map['stage'] as String? ?? 'heating',
    );

    return NotificationData(
      type: type,
      stage: stage,
      brewId: map['brewId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      deepLink: map['deepLink'] as String?,
      progress: _parseInt(map['progress'] as String?),
      brewType: map['brewType'] as String? ?? 'espresso',
      dose: _parseDouble(map['dose'] as String?) ?? 18.0,
      temperature: _parseDouble(map['temperature'] as String?) ?? 93.0,
      pressure: _parseDouble(map['pressure'] as String?) ?? 9.0,
      elapsedTime: _parseInt(map['elapsedTime'] as String?) ?? 0,
      remainingTime: _parseInt(map['remainingTime'] as String?),
      flowRate: _parseDouble(map['flowRate'] as String?),
      volumeExtracted: _parseDouble(map['volumeExtracted'] as String?),
    );
  }

  /// Converts this notification data to a JSON string.
  ///
  /// Used for storing notification data in local notification payloads so it can be retrieved when the notification is
  /// tapped.
  String toJson() {
    return jsonEncode(<String, dynamic>{
      'type': type.value,
      'stage': stage.name,
      'brewId': brewId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'deepLink': deepLink,
      'progress': progress,
      'brewType': brewType,
      'dose': dose,
      'temperature': temperature,
      'pressure': pressure,
      'elapsedTime': elapsedTime,
      'remainingTime': remainingTime,
      'flowRate': flowRate,
      'volumeExtracted': volumeExtracted,
    });
  }

  /// Safely parses a string to an integer.
  ///
  /// Returns null if the string is null, empty, or cannot be parsed.
  static int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Safely parses a string to a double.
  ///
  /// Returns null if the string is null, empty, or cannot be parsed.
  static double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }
}
