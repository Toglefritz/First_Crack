part of '../push_notification_service.dart';

/// Enumeration of available notification actions for brew notifications.
///
/// This enum defines all possible action button types that can appear on brew notifications. Each action corresponds to
/// a specific user interaction with the brew process.
///
/// Action identifiers are used to map between native iOS/macOS action buttons and Flutter navigation logic. The
/// identifiers must match those defined in the AppDelegate.
enum NotificationAction {
  /// Pause the grinding operation.
  ///
  /// Available during: BREW_GRINDING stage Deep link: firstcrack://brew/{brewId}/pause
  pauseGrinding,

  /// Open grind settings screen.
  ///
  /// Available during: BREW_GRINDING stage Deep link: firstcrack://brew/{brewId}/settings
  adjustGrind,

  /// Skip pre-infusion and start extraction immediately.
  ///
  /// Available during: BREW_PREINFUSION stage Deep link: firstcrack://brew/{brewId}/skip-preinfusion
  skipPreinfusion,

  /// Add additional pre-infusion time.
  ///
  /// Available during: BREW_PREINFUSION stage Deep link: firstcrack://brew/{brewId}/extend-preinfusion
  extendPreinfusion,

  /// Stop extraction immediately.
  ///
  /// Available during: BREW_EXTRACTION stage Deep link: firstcrack://brew/{brewId}/stop
  stopShot,

  /// View live extraction progress.
  ///
  /// Available during: BREW_EXTRACTION stage Deep link: firstcrack://brew/{brewId}/live
  viewLive,

  /// Repeat the same brew with identical settings.
  ///
  /// Available during: BREW_COMPLETE stage Deep link: firstcrack://brew/{brewId}/repeat
  brewAgain,

  /// Edit the brew profile parameters.
  ///
  /// Available during: BREW_COMPLETE stage Deep link: firstcrack://brew/{brewId}/profile
  adjustProfile,

  /// Share brew results with others.
  ///
  /// Available during: BREW_COMPLETE stage Deep link: firstcrack://brew/{brewId}/share
  share,

  /// Default action for notification body tap.
  ///
  /// Available during: All stages Deep link: firstcrack://brew/{brewId}/details
  defaultAction;

  /// Creates a NotificationAction from an action identifier string.
  ///
  /// This factory method maps action identifier strings from native code to the corresponding enum value. The
  /// identifiers must match those defined in the AppDelegate's notification category registration.
  ///
  /// Throws [ArgumentError] if the identifier is not recognized.
  static NotificationAction fromIdentifier(String identifier) {
    switch (identifier) {
      case 'pause_grinding':
        return NotificationAction.pauseGrinding;
      case 'adjust_grind':
        return NotificationAction.adjustGrind;
      case 'skip_preinfusion':
        return NotificationAction.skipPreinfusion;
      case 'extend_preinfusion':
        return NotificationAction.extendPreinfusion;
      case 'stop_shot':
        return NotificationAction.stopShot;
      case 'view_live':
        return NotificationAction.viewLive;
      case 'brew_again':
        return NotificationAction.brewAgain;
      case 'adjust_profile':
        return NotificationAction.adjustProfile;
      case 'share':
        return NotificationAction.share;
      case 'com.apple.UNNotificationDefaultActionIdentifier':
      case 'default':
        return NotificationAction.defaultAction;
      default:
        throw ArgumentError('Unknown action identifier: $identifier');
    }
  }

  /// Converts this action to an action identifier string.
  ///
  /// This method converts the enum value back to the action identifier string used in native code. This is useful for
  /// serialization and logging.
  String toIdentifier() {
    switch (this) {
      case NotificationAction.pauseGrinding:
        return 'pause_grinding';
      case NotificationAction.adjustGrind:
        return 'adjust_grind';
      case NotificationAction.skipPreinfusion:
        return 'skip_preinfusion';
      case NotificationAction.extendPreinfusion:
        return 'extend_preinfusion';
      case NotificationAction.stopShot:
        return 'stop_shot';
      case NotificationAction.viewLive:
        return 'view_live';
      case NotificationAction.brewAgain:
        return 'brew_again';
      case NotificationAction.adjustProfile:
        return 'adjust_profile';
      case NotificationAction.share:
        return 'share';
      case NotificationAction.defaultAction:
        return 'default';
    }
  }
}
