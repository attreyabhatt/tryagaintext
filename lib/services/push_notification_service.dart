import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';

class PushNotificationService {
  static bool _initialized = false;

  static bool get _supportsCurrentPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initialize() async {
    if (_initialized || !_supportsCurrentPlatform) return;

    final appId = AppConfig.oneSignalAppId.trim();
    if (appId.isEmpty) {
      AppLogger.debug(
        'ONESIGNAL_APP_ID is empty; skipping OneSignal initialization.',
      );
      return;
    }

    if (kDebugMode) {
      await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    OneSignal.initialize(appId);
    _initialized = true;
    AppLogger.debug('OneSignal initialized.');
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await initialize();
  }

  static Future<bool> isPermissionGranted() async {
    if (!_supportsCurrentPlatform) return false;
    await _ensureInitialized();
    if (!_initialized) return false;
    return OneSignal.Notifications.permission;
  }

  static Future<bool> canRequestPermission() async {
    if (!_supportsCurrentPlatform) return false;
    await _ensureInitialized();
    if (!_initialized) return false;
    return OneSignal.Notifications.canRequest();
  }

  static Future<bool> requestPermissionFromSystem() async {
    if (!_supportsCurrentPlatform) return false;
    await _ensureInitialized();
    if (!_initialized) return false;

    try {
      if (OneSignal.Notifications.permission) {
        return true;
      }

      final canRequest = await OneSignal.Notifications.canRequest();
      if (!canRequest) {
        AppLogger.debug(
          'Notification permission prompt already used on this device.',
        );
        return false;
      }

      final granted = await OneSignal.Notifications.requestPermission(false);
      AppLogger.debug('Notification permission granted: $granted');
      return granted;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to request OneSignal permission', e, stackTrace);
      return false;
    }
  }

  static Future<void> requestPermissionForDebug() async {
    if (!kDebugMode || !_initialized || !_supportsCurrentPlatform) {
      return;
    }
    await requestPermissionFromSystem();
  }
}
