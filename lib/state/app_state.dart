import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';

enum AppThemeMode { premiumLightGold, premiumDarkNeonGold }

class AppState extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _localeOverrideCodeKey = 'app_locale_override_code';
  User? _user;
  int _credits = 0;
  bool _isSubscribed = false;
  String? _subscriptionExpiry;
  int? _subscriberWeeklyRemaining;
  int? _subscriberWeeklyLimit;
  // Daily limits (new)
  int? _dailyOpenersRemaining;
  int? _dailyOpenersLimit;
  int? _dailyRepliesRemaining;
  int? _dailyRepliesLimit;
  // Free user daily credits
  int? _freeDailyCreditsRemaining;
  int? _freeDailyCreditsLimit;
  bool _isLoggedIn = false;
  bool _initialized = false;
  AppThemeMode _themeMode = AppThemeMode.premiumDarkNeonGold;
  Locale? _localeOverride;
  // Blocked users
  Set<int> _blockedUserIds = {};

  User? get user => _user;
  int get credits => _credits;
  bool get isSubscribed => _isSubscribed;
  String? get subscriptionExpiry => _subscriptionExpiry;
  int? get subscriberWeeklyRemaining => _subscriberWeeklyRemaining;
  int? get subscriberWeeklyLimit => _subscriberWeeklyLimit;
  // Daily limit getters
  int? get dailyOpenersRemaining => _dailyOpenersRemaining;
  int? get dailyOpenersLimit => _dailyOpenersLimit;
  int? get dailyRepliesRemaining => _dailyRepliesRemaining;
  int? get dailyRepliesLimit => _dailyRepliesLimit;
  // Free daily credit getters
  int? get freeDailyCreditsRemaining => _freeDailyCreditsRemaining;
  int? get freeDailyCreditsLimit => _freeDailyCreditsLimit;
  bool get isLoggedIn => _isLoggedIn;
  bool get initialized => _initialized;
  AppThemeMode get themeMode => _themeMode;
  Locale? get localeOverride => _localeOverride;
  Set<int> get blockedUserIds => _blockedUserIds;
  bool isUserBlocked(int userId) => _blockedUserIds.contains(userId);

  Future<void> initialize() async {
    await _loadThemePreference();
    await _loadLocalePreference();
    await reloadFromStorage();
    if (_isLoggedIn) {
      await refreshUserData();
      await loadBlockedUsers();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> loadBlockedUsers() async {
    try {
      final ids = await ApiClient().getBlockedUserIds();
      _blockedUserIds = ids.toSet();
      notifyListeners();
    } catch (e) {
      AppLogger.error('loadBlockedUsers error', e is Exception ? e : null);
    }
  }

  Future<bool> toggleBlockUser(int userId) async {
    try {
      final result = await ApiClient().toggleBlockUser(userId);
      final blocked = result['blocked'] as bool? ?? false;
      if (blocked) {
        _blockedUserIds.add(userId);
      } else {
        _blockedUserIds.remove(userId);
      }
      notifyListeners();
      return blocked;
    } catch (e) {
      AppLogger.error('toggleBlockUser error', e is Exception ? e : null);
      rethrow;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey);
    if (raw == AppThemeMode.premiumLightGold.name) {
      _themeMode = AppThemeMode.premiumLightGold;
    } else if (raw == AppThemeMode.premiumDarkNeonGold.name) {
      _themeMode = AppThemeMode.premiumDarkNeonGold;
    }
  }

  Future<void> setLocaleOverride(Locale? locale) async {
    _localeOverride = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeOverrideCodeKey);
      return;
    }
    await prefs.setString(_localeOverrideCodeKey, locale.toLanguageTag());
  }

  Future<void> _loadLocalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localeOverrideCodeKey);
    if (raw == null || raw.trim().isEmpty) {
      _localeOverride = null;
      return;
    }

    final parts = raw.split(RegExp('[-_]'));
    if (parts.isEmpty || parts.first.isEmpty) {
      _localeOverride = null;
      return;
    }

    final languageCode = parts.first;
    final countryCode = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1]
        : null;
    _localeOverride = Locale(languageCode, countryCode);
  }

  Future<void> reloadFromStorage() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    _user = await AuthService.getStoredUser();
    _credits = await AuthService.getStoredCredits();
    _isSubscribed = await AuthService.getStoredSubscriptionStatus();
    _subscriptionExpiry = await AuthService.getStoredSubscriptionExpiry();
    _subscriberWeeklyRemaining =
        await AuthService.getStoredSubscriberWeeklyRemaining();
    _subscriberWeeklyLimit = await AuthService.getStoredSubscriberWeeklyLimit();
    // Load daily limits
    _dailyOpenersRemaining = await AuthService.getStoredDailyOpenersRemaining();
    _dailyOpenersLimit = await AuthService.getStoredDailyOpenersLimit();
    _dailyRepliesRemaining = await AuthService.getStoredDailyRepliesRemaining();
    _dailyRepliesLimit = await AuthService.getStoredDailyRepliesLimit();
    // Load free daily credits
    _freeDailyCreditsRemaining =
        await AuthService.getStoredFreeDailyCreditsRemaining();
    _freeDailyCreditsLimit = await AuthService.getStoredFreeDailyCreditsLimit();
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    if (!await AuthService.isLoggedIn()) {
      await reloadFromStorage();
      return;
    }
    final ok = await AuthService.refreshUserData();
    if (!ok) {
      AppLogger.debug('Failed to refresh user data from server');
    }
    await reloadFromStorage();
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _credits = 0;
    _isSubscribed = false;
    _subscriptionExpiry = null;
    _subscriberWeeklyRemaining = null;
    _subscriberWeeklyLimit = null;
    _dailyOpenersRemaining = null;
    _dailyOpenersLimit = null;
    _dailyRepliesRemaining = null;
    _dailyRepliesLimit = null;
    _freeDailyCreditsRemaining = null;
    _freeDailyCreditsLimit = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null || scope.notifier == null) {
      throw StateError('AppStateScope not found in widget tree');
    }
    return scope.notifier!;
  }
}
