import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';

typedef PushNotificationTapHandler =
    Future<void> Function(PushTapAction action);

class PushTapAction {
  static const String actionCommunityComment = 'community_comment';

  final String action;
  final int? postId;
  final int? commentId;

  const PushTapAction._({required this.action, this.postId, this.commentId});

  factory PushTapAction.communityComment({
    required int postId,
    int? commentId,
  }) {
    return PushTapAction._(
      action: actionCommunityComment,
      postId: postId,
      commentId: commentId,
    );
  }

  static PushTapAction? fromAdditionalData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return null;

    final action = data['action']?.toString().trim();
    if (action != actionCommunityComment) {
      return null;
    }

    final postId = _parseInt(data['post_id']);
    if (postId == null) {
      return null;
    }

    return PushTapAction.communityComment(
      postId: postId,
      commentId: _parseInt(data['comment_id']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}

class PushNotificationService {
  static const String actionCommunityComment =
      PushTapAction.actionCommunityComment;

  static bool _initialized = false;
  static bool _clickListenerRegistered = false;
  static String? _syncedExternalId;
  static bool _loggedOutIdentitySynced = false;
  static PushNotificationTapHandler? _tapHandler;
  static final List<PushTapAction> _pendingTapActions = <PushTapAction>[];

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
    _registerClickListener();
    _initialized = true;
    AppLogger.debug('OneSignal initialized.');
  }

  static void _registerClickListener() {
    if (_clickListenerRegistered) return;
    OneSignal.Notifications.addClickListener(_onNotificationClicked);
    _clickListenerRegistered = true;
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await initialize();
  }

  static void _onNotificationClicked(OSNotificationClickEvent event) {
    final action = PushTapAction.fromAdditionalData(
      event.notification.additionalData,
    );
    if (action == null) return;
    if (_tapHandler == null) {
      _pendingTapActions.add(action);
      return;
    }
    unawaited(_dispatchTapAction(action));
  }

  static Future<void> setTapHandler(PushNotificationTapHandler? handler) async {
    _tapHandler = handler;
    await _flushPendingTapActions();
  }

  static Future<void> _flushPendingTapActions() async {
    if (_tapHandler == null || _pendingTapActions.isEmpty) return;
    final actions = List<PushTapAction>.from(_pendingTapActions);
    _pendingTapActions.clear();
    for (final action in actions) {
      await _dispatchTapAction(action);
    }
  }

  static Future<void> _dispatchTapAction(PushTapAction action) async {
    if (_tapHandler == null) return;
    try {
      await _tapHandler!.call(action);
    } catch (e, stackTrace) {
      AppLogger.error('Push tap handler failed', e, stackTrace);
    }
  }

  static Future<void> syncAuthenticatedUser(int? userId) async {
    if (!_supportsCurrentPlatform) return;
    await _ensureInitialized();
    if (!_initialized) return;

    final externalId = userId?.toString().trim() ?? '';
    if (externalId.isEmpty) {
      await clearAuthenticatedUser();
      return;
    }

    if (_syncedExternalId == externalId) return;

    try {
      await OneSignal.login(externalId);
      _syncedExternalId = externalId;
      _loggedOutIdentitySynced = false;
      AppLogger.debug('OneSignal external id synced for user $externalId.');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync OneSignal external id', e, stackTrace);
    }
  }

  static Future<void> clearAuthenticatedUser() async {
    if (!_supportsCurrentPlatform) return;
    await _ensureInitialized();
    if (!_initialized || _loggedOutIdentitySynced) return;

    try {
      await OneSignal.logout();
      _syncedExternalId = null;
      _loggedOutIdentitySynced = true;
      AppLogger.debug('Cleared OneSignal external user context.');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear OneSignal external id', e, stackTrace);
    }
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
