import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_logger.dart';

typedef LocalNotificationTapHandler = Future<void> Function(String action);

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String actionDailyRefill = 'daily_refill';
  static const String actionGuestSignupNudge = 'guest_signup_nudge';
  static const String actionUpgradeNudge = 'upgrade_nudge';

  static const int _dailyRefillNotificationId = 5001;
  static const int _guestSignupNudgeNotificationId = 5002;
  static const int _upgradeNudgeNotificationId = 5003;

  static const String _dailyRefillTitle = 'Your Concierge is Ready \u{2728}';
  static const String _dailyRefillBody =
      "Your 3 complimentary replies have been refreshed. Let's make a flawless impression today.";

  static const String _guestSignupTitle =
      'Elevate Your Conversations \u{1F5DD}\u{FE0F}';
  static const String _guestSignupBody =
      'Create your complimentary account today to unlock 3 signature AI replies every single day.';

  static const String _upgradeTitle = 'Experience Flirtfix Premium \u{1F5A4}';
  static const String _upgradeBody =
      'Never compromise on a first impression. Upgrade to Premium for unlimited, tailored AI replies.';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'flirtfix_v1_notifications',
    'FlirtFix Notifications',
    description: 'FlirtFix engagement and reminder notifications.',
    importance: Importance.max,
  );

  static bool _initialized = false;
  static bool _timezoneInitialized = false;
  static LocalNotificationTapHandler? _tapHandler;
  static final List<String> _pendingTapActions = <String>[];

  static bool get _supportsCurrentPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initialize() async {
    if (_initialized || !_supportsCurrentPlatform) return;

    if (!_timezoneInitialized) {
      tz_data.initializeTimeZones();
      _timezoneInitialized = true;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);

    _initialized = true;
    await _captureLaunchActionIfAny();
  }

  static Future<void> _captureLaunchActionIfAny() async {
    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        _handlePayload(launchDetails?.notificationResponse?.payload);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to read notification launch details',
        e,
        stackTrace,
      );
    }
  }

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  static Future<void> setTapHandler(LocalNotificationTapHandler? handler) async {
    _tapHandler = handler;
    await _flushPendingTapActions();
  }

  static Future<void> _flushPendingTapActions() async {
    if (_tapHandler == null || _pendingTapActions.isEmpty) return;
    final queuedActions = List<String>.from(_pendingTapActions);
    _pendingTapActions.clear();
    for (final action in queuedActions) {
      await _dispatchTapAction(action);
    }
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  static String? _actionFromPayload(String? payload) {
    switch (payload) {
      case actionDailyRefill:
      case actionGuestSignupNudge:
      case actionUpgradeNudge:
        return payload;
      default:
        return null;
    }
  }

  static void _handlePayload(String? payload) {
    final action = _actionFromPayload(payload);
    if (action == null) return;

    if (_tapHandler == null) {
      _pendingTapActions.add(action);
      return;
    }

    unawaited(_dispatchTapAction(action));
  }

  static Future<void> _dispatchTapAction(String action) async {
    if (_tapHandler == null) return;
    try {
      await _tapHandler!.call(action);
    } catch (e, stackTrace) {
      AppLogger.error('Notification tap handler failed', e, stackTrace);
    }
  }

  static Future<bool> requestPermission() async {
    await _ensureInitialized();

    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  static NotificationDetails _details({
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
    StyleInformation? styleInformation,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: importance,
        priority: priority,
        styleInformation: styleInformation,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<bool> _hasPendingNotification(int id) async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((notification) => notification.id == id);
  }

  static Future<void> _showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    await _ensureInitialized();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(importance: importance, priority: priority),
      payload: payload,
    );
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
    bool forceReschedule = false,
  }) async {
    await _ensureInitialized();
    if (!_supportsCurrentPlatform) return;

    if (!forceReschedule && await _hasPendingNotification(id)) {
      AppLogger.debug('Notification $id already pending; skipping schedule.');
      return;
    }

    if (forceReschedule) {
      await _plugin.cancel(id: id);
    }

    final scheduledAt = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledAt,
      notificationDetails: _details(
        importance: Importance.max,
        priority: Priority.high,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );

    AppLogger.debug('Scheduled local notification $id for $scheduledAt.');
  }

  // v1 campaign notifications

  static Future<void> scheduleDailyRefillReminder({
    Duration delay = const Duration(hours: 24),
    bool forceReschedule = false,
  }) async {
    await _schedule(
      id: _dailyRefillNotificationId,
      title: _dailyRefillTitle,
      body: _dailyRefillBody,
      payload: actionDailyRefill,
      delay: delay,
      forceReschedule: forceReschedule,
    );
  }

  static Future<void> scheduleGuestSignupNudge({
    Duration delay = const Duration(hours: 24),
    bool forceReschedule = false,
  }) async {
    await _schedule(
      id: _guestSignupNudgeNotificationId,
      title: _guestSignupTitle,
      body: _guestSignupBody,
      payload: actionGuestSignupNudge,
      delay: delay,
      forceReschedule: forceReschedule,
    );
  }

  static Future<void> scheduleUpgradeNudge({
    Duration delay = const Duration(hours: 24),
    bool forceReschedule = false,
  }) async {
    await _schedule(
      id: _upgradeNudgeNotificationId,
      title: _upgradeTitle,
      body: _upgradeBody,
      payload: actionUpgradeNudge,
      delay: delay,
      forceReschedule: forceReschedule,
    );
  }

  static Future<void> showDailyRefillNow() async {
    await _showNow(
      id: _dailyRefillNotificationId,
      title: _dailyRefillTitle,
      body: _dailyRefillBody,
      payload: actionDailyRefill,
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  static Future<void> showGuestSignupNudgeNow() async {
    await _showNow(
      id: _guestSignupNudgeNotificationId,
      title: _guestSignupTitle,
      body: _guestSignupBody,
      payload: actionGuestSignupNudge,
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  static Future<void> showUpgradeNudgeNow() async {
    await _showNow(
      id: _upgradeNudgeNotificationId,
      title: _upgradeTitle,
      body: _upgradeBody,
      payload: actionUpgradeNudge,
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  // Legacy/manual test variants kept for ad hoc QA.

  static Future<void> showBasic() async {
    await _showNow(
      id: 9001,
      title: 'FlirtFix Test',
      body: 'Basic local notification.',
    );
  }

  static Future<void> showBigText() async {
    await _ensureInitialized();
    const longText =
        'This is a big text style notification test. Use this to verify expanded '
        'text rendering and long-body behavior on your current Android device.';
    await _plugin.show(
      id: 9002,
      title: 'FlirtFix Big Text Test',
      body: 'Expand me to view long content.',
      notificationDetails: _details(
        styleInformation: const BigTextStyleInformation(longText),
      ),
    );
  }

  static Future<void> showHeadsUp() async {
    await _ensureInitialized();
    await _plugin.show(
      id: 9003,
      title: 'FlirtFix Heads-up Test',
      body: 'High priority local notification.',
      notificationDetails: _details(
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }

  static Future<void> scheduleInTenSeconds() async {
    await _schedule(
      id: 9004,
      title: 'FlirtFix Scheduled Test',
      body: 'This local notification was delayed by 10 seconds.',
      delay: const Duration(seconds: 10),
      forceReschedule: true,
    );
  }

  static Future<List<int>> pendingNotificationIds() async {
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    final ids = pending.map((item) => item.id).toList()..sort();
    return ids;
  }

  static Future<void> cancelDailyRefillReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _dailyRefillNotificationId);
  }

  static Future<void> cancelGuestSignupNudge() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _guestSignupNudgeNotificationId);
  }

  static Future<void> cancelUpgradeNudge() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _upgradeNudgeNotificationId);
  }

  static Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
    await _plugin.cancelAllPendingNotifications();
  }

  static Future<void> cancelV1CampaignNotifications() async {
    await cancelDailyRefillReminder();
    await cancelGuestSignupNudge();
    await cancelUpgradeNudge();
  }
}

