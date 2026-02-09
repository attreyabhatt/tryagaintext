import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/auth_response.dart';
import '../models/profile_response.dart';
import '../models/user.dart';
import '../utils/app_logger.dart';

class AuthService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String creditsKey = 'chat_credits';
  static const String guestIdKey = 'guest_id';
  static const String deviceFingerprintKey = 'device_fingerprint';
  static const String subscriptionKey = 'is_subscribed';
  static const String subscriptionExpiryKey = 'subscription_expiry';
  static const String subscriberWeeklyRemainingKey =
      'subscriber_weekly_remaining';
  static const String subscriberWeeklyLimitKey = 'subscriber_weekly_limit';
  // Daily limits (new)
  static const String dailyOpenersRemainingKey = 'daily_openers_remaining';
  static const String dailyOpenersLimitKey = 'daily_openers_limit';
  static const String dailyRepliesRemainingKey = 'daily_replies_remaining';
  static const String dailyRepliesLimitKey = 'daily_replies_limit';
  // Free user daily credits
  static const String freeDailyCreditsRemainingKey =
      'free_daily_credits_remaining';
  static const String freeDailyCreditsLimitKey = 'free_daily_credits_limit';
  static const String justSignedUpKey = 'just_signed_up';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Store auth token
  static Future<void> _storeToken(String token) async {
    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: tokenKey, value: token);
      } catch (e) {
        AppLogger.error('Secure token write failed', e is Exception ? e : null);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Store a fresh auth token returned by the backend.
  static Future<void> storeTokenFromServer(String token) async {
    final sanitized = token.trim();
    if (sanitized.isEmpty) {
      return;
    }
    await _storeToken(sanitized);
  }

  // Store user data
  static Future<void> _storeUser(
    User user,
    int credits, {
    bool? isSubscribed,
    String? subscriptionExpiry,
    int? subscriberWeeklyRemaining,
    int? subscriberWeeklyLimit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      userKey,
      jsonEncode({
        'id': user.id,
        'username': user.username,
        'email': user.email,
      }),
    );
    await prefs.setInt(creditsKey, credits);
    if (isSubscribed != null) {
      await prefs.setBool(subscriptionKey, isSubscribed);
    }
    if (subscriptionExpiry != null) {
      await prefs.setString(subscriptionExpiryKey, subscriptionExpiry);
    }
    if (subscriberWeeklyRemaining != null) {
      await prefs.setInt(
        subscriberWeeklyRemainingKey,
        subscriberWeeklyRemaining,
      );
    }
    if (subscriberWeeklyLimit != null) {
      await prefs.setInt(subscriberWeeklyLimitKey, subscriberWeeklyLimit);
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    if (!kIsWeb) {
      try {
        final secureToken = await _secureStorage.read(key: tokenKey);
        if (secureToken != null && secureToken.isNotEmpty) {
          return secureToken;
        }
      } catch (e) {
        AppLogger.error('Secure token read failed', e is Exception ? e : null);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(tokenKey);
    if (legacyToken == null || legacyToken.isEmpty) {
      return null;
    }

    if (!kIsWeb) {
      // Migrate legacy token from SharedPreferences to secure storage.
      try {
        await _secureStorage.write(key: tokenKey, value: legacyToken);
        await prefs.remove(tokenKey);
      } catch (e) {
        AppLogger.error(
          'Secure token migration failed',
          e is Exception ? e : null,
        );
      }
    }
    return legacyToken;
  }

  // Get stored user
  static Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);
    if (userData != null) {
      final json = jsonDecode(userData);
      return User.fromJson(json);
    }
    return null;
  }

  // Get stored credits
  static Future<int> getStoredCredits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(creditsKey) ?? 0;
  }

  static Future<bool> getStoredSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(subscriptionKey) ?? false;
  }

  static Future<String?> getStoredSubscriptionExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(subscriptionExpiryKey);
  }

  static Future<int?> getStoredSubscriberWeeklyRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(subscriberWeeklyRemainingKey);
  }

  static Future<int?> getStoredSubscriberWeeklyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(subscriberWeeklyLimitKey);
  }

  // Daily limit getters
  static Future<int?> getStoredDailyOpenersRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dailyOpenersRemainingKey);
  }

  static Future<int?> getStoredDailyOpenersLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dailyOpenersLimitKey);
  }

  static Future<int?> getStoredDailyRepliesRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dailyRepliesRemainingKey);
  }

  static Future<int?> getStoredDailyRepliesLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dailyRepliesLimitKey);
  }

  // Free daily credits getters
  static Future<int?> getStoredFreeDailyCreditsRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(freeDailyCreditsRemainingKey);
  }

  static Future<int?> getStoredFreeDailyCreditsLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(freeDailyCreditsLimitKey);
  }

  // Update stored credits
  static Future<void> updateStoredCredits(int credits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(creditsKey, credits);
  }

  // Clear all stored data
  static Future<void> clearStoredData() async {
    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: tokenKey);
      } catch (e) {
        AppLogger.error(
          'Secure token delete failed',
          e is Exception ? e : null,
        );
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
    await prefs.remove(creditsKey);
    await prefs.remove(subscriptionKey);
    await prefs.remove(subscriptionExpiryKey);
    await prefs.remove(subscriberWeeklyRemainingKey);
    await prefs.remove(subscriberWeeklyLimitKey);
    await prefs.remove(dailyOpenersRemainingKey);
    await prefs.remove(dailyOpenersLimitKey);
    await prefs.remove(dailyRepliesRemainingKey);
    await prefs.remove(dailyRepliesLimitKey);
    await prefs.remove(freeDailyCreditsRemainingKey);
    await prefs.remove(freeDailyCreditsLimitKey);
    await prefs.remove(guestIdKey);
    await prefs.remove(deviceFingerprintKey);
    await prefs.remove(justSignedUpKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Register user
  static Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final deviceFingerprint = await getOrCreateDeviceFingerprint();
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Fingerprint': deviceFingerprint,
          // Backward compatibility for existing backend parsing.
          'X-Guest-Id': deviceFingerprint,
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      if (authResponse.success &&
          authResponse.token != null &&
          authResponse.user != null) {
        await updateSubscriptionFromPayload(data);
        await _storeToken(authResponse.token!);
        await _storeUser(
          authResponse.user!,
          authResponse.chatCredits ?? 0,
          isSubscribed: authResponse.isSubscribed,
          subscriptionExpiry: authResponse.subscriptionExpiry,
          subscriberWeeklyRemaining: authResponse.subscriberWeeklyRemaining,
          subscriberWeeklyLimit: authResponse.subscriberWeeklyLimit,
        );
      }

      return authResponse;
    } catch (e) {
      AppLogger.error('Registration error', e is Exception ? e : null);
      return AuthResponse(
        success: false,
        error: 'Network error. Please try again.',
      );
    }
  }

  // Login user
  static Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final deviceFingerprint = await getOrCreateDeviceFingerprint();
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Fingerprint': deviceFingerprint,
          // Backward compatibility for existing backend parsing.
          'X-Guest-Id': deviceFingerprint,
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      if (authResponse.success &&
          authResponse.token != null &&
          authResponse.user != null) {
        await updateSubscriptionFromPayload(data);
        await _storeToken(authResponse.token!);
        await _storeUser(
          authResponse.user!,
          authResponse.chatCredits ?? 0,
          isSubscribed: authResponse.isSubscribed,
          subscriptionExpiry: authResponse.subscriptionExpiry,
          subscriberWeeklyRemaining: authResponse.subscriberWeeklyRemaining,
          subscriberWeeklyLimit: authResponse.subscriberWeeklyLimit,
        );
      }

      return authResponse;
    } catch (e) {
      AppLogger.error('Login error', e is Exception ? e : null);
      return AuthResponse(
        success: false,
        error: 'Network error. Please try again.',
      );
    }
  }

  // Get profile
  static Future<ProfileResponse> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return ProfileResponse(success: false, error: 'Not authenticated');
      }
      final deviceFingerprint = await getOrCreateDeviceFingerprint();

      final response = await http.get(
        Uri.parse('$baseUrl/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
          'X-Device-Fingerprint': deviceFingerprint,
          // Backward compatibility for existing backend parsing.
          'X-Guest-Id': deviceFingerprint,
        },
      );

      final data = jsonDecode(response.body);
      final profileResponse = ProfileResponse.fromJson(data);

      if (profileResponse.success && profileResponse.user != null) {
        await updateSubscriptionFromPayload(data);
        await _storeUser(
          profileResponse.user!,
          profileResponse.chatCredits ?? 0,
          isSubscribed: profileResponse.isSubscribed,
          subscriptionExpiry: profileResponse.subscriptionExpiry,
          subscriberWeeklyRemaining: profileResponse.subscriberWeeklyRemaining,
          subscriberWeeklyLimit: profileResponse.subscriberWeeklyLimit,
        );
      }

      return profileResponse;
    } catch (e) {
      AppLogger.error('Profile fetch error', e is Exception ? e : null);
      return ProfileResponse(
        success: false,
        error: 'Network error. Please try again.',
      );
    }
  }

  // Logout user
  static Future<void> logout() async {
    await clearStoredData();
  }

  // Refresh user data
  static Future<bool> refreshUserData() async {
    final profileResponse = await getProfile();
    return profileResponse.success;
  }

  static Future<void> markJustSignedUp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(justSignedUpKey, true);
  }

  static Future<bool> consumeJustSignedUp() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool(justSignedUpKey) ?? false;
    if (flag) {
      await prefs.remove(justSignedUpKey);
    }
    return flag;
  }

  static Future<String> getOrCreateDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    final existing =
        prefs.getString(deviceFingerprintKey) ?? prefs.getString(guestIdKey);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidId = await const AndroidId().getId();
        if (androidId != null && androidId.isNotEmpty) {
          return _persistDeviceFingerprint(prefs, androidId, saveSecure: true);
        }
      } catch (e) {
        AppLogger.error('Android ID lookup failed', e is Exception ? e : null);
      }
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final deviceInfo = await DeviceInfoPlugin().iosInfo;
        final idfv = deviceInfo.identifierForVendor;
        if (idfv != null && idfv.isNotEmpty) {
          return _persistDeviceFingerprint(prefs, idfv, saveSecure: true);
        }
      } catch (e) {
        AppLogger.error('IDFV lookup failed', e is Exception ? e : null);
      }
    }

    final secureExisting = await _readSecureDeviceFingerprint();
    if (secureExisting != null && secureExisting.isNotEmpty) {
      return _persistDeviceFingerprint(
        prefs,
        secureExisting,
        saveSecure: false,
      );
    }

    if (existing != null && existing.isNotEmpty) {
      return _persistDeviceFingerprint(prefs, existing, saveSecure: true);
    }

    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return _persistDeviceFingerprint(prefs, id, saveSecure: true);
  }

  static Future<String> getOrCreateGuestId() async {
    return getOrCreateDeviceFingerprint();
  }

  static Future<String?> _readSecureDeviceFingerprint() async {
    if (kIsWeb) return null;
    try {
      return await _secureStorage.read(key: deviceFingerprintKey);
    } catch (e) {
      AppLogger.error('Secure storage read failed', e is Exception ? e : null);
      return null;
    }
  }

  static Future<void> _writeSecureDeviceFingerprint(String value) async {
    if (kIsWeb) return;
    try {
      await _secureStorage.write(key: deviceFingerprintKey, value: value);
    } catch (e) {
      AppLogger.error('Secure storage write failed', e is Exception ? e : null);
    }
  }

  static Future<String> _persistDeviceFingerprint(
    SharedPreferences prefs,
    String value, {
    required bool saveSecure,
  }) async {
    if (prefs.getString(deviceFingerprintKey) != value) {
      await prefs.setString(deviceFingerprintKey, value);
    }
    if (prefs.getString(guestIdKey) != value) {
      await prefs.setString(guestIdKey, value);
    }
    if (saveSecure) {
      await _writeSecureDeviceFingerprint(value);
    }
    return value;
  }

  static Future<void> updateSubscriptionFromPayload(
    Map<String, dynamic> json,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (json.containsKey('is_subscribed')) {
      await prefs.setBool(subscriptionKey, json['is_subscribed'] == true);
    }
    if (json['subscription_expiry'] != null) {
      await prefs.setString(
        subscriptionExpiryKey,
        json['subscription_expiry'].toString(),
      );
    }
    // Legacy weekly fields
    if (json['subscriber_weekly_remaining'] != null) {
      await prefs.setInt(
        subscriberWeeklyRemainingKey,
        json['subscriber_weekly_remaining'] as int,
      );
    }
    if (json['subscriber_weekly_limit'] != null) {
      await prefs.setInt(
        subscriberWeeklyLimitKey,
        json['subscriber_weekly_limit'] as int,
      );
    }
    // New daily fields
    if (json['daily_openers_remaining'] != null) {
      await prefs.setInt(
        dailyOpenersRemainingKey,
        json['daily_openers_remaining'] as int,
      );
    }
    if (json['daily_openers_limit'] != null) {
      await prefs.setInt(
        dailyOpenersLimitKey,
        json['daily_openers_limit'] as int,
      );
    }
    if (json['daily_replies_remaining'] != null) {
      await prefs.setInt(
        dailyRepliesRemainingKey,
        json['daily_replies_remaining'] as int,
      );
    }
    if (json['daily_replies_limit'] != null) {
      await prefs.setInt(
        dailyRepliesLimitKey,
        json['daily_replies_limit'] as int,
      );
    }
    // Free user daily credits
    if (json['free_daily_credits_remaining'] != null) {
      await prefs.setInt(
        freeDailyCreditsRemainingKey,
        json['free_daily_credits_remaining'] as int,
      );
    }
    if (json['free_daily_credits_limit'] != null) {
      await prefs.setInt(
        freeDailyCreditsLimitKey,
        json['free_daily_credits_limit'] as int,
      );
    }
  }
}
