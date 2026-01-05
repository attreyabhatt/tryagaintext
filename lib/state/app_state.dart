import 'package:flutter/widgets.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';

class AppState extends ChangeNotifier {
  User? _user;
  int _credits = 0;
  bool _isLoggedIn = false;
  bool _initialized = false;

  User? get user => _user;
  int get credits => _credits;
  bool get isLoggedIn => _isLoggedIn;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    await reloadFromStorage();
    if (_isLoggedIn) {
      await refreshUserData();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> reloadFromStorage() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    _user = await AuthService.getStoredUser();
    _credits = await AuthService.getStoredCredits();
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
    _isLoggedIn = false;
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null || scope.notifier == null) {
      throw StateError('AppStateScope not found in widget tree');
    }
    return scope.notifier!;
  }
}
