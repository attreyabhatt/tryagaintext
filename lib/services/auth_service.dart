import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:android_id/android_id.dart';
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
  static const String subscriptionKey = 'is_subscribed';
  static const String subscriptionExpiryKey = 'subscription_expiry';
  static const String subscriberWeeklyRemainingKey = 'subscriber_weekly_remaining';
  static const String subscriberWeeklyLimitKey = 'subscriber_weekly_limit';
  // Daily limits (new)
  static const String dailyOpenersRemainingKey = 'daily_openers_remaining';
  static const String dailyOpenersLimitKey = 'daily_openers_limit';
  static const String dailyRepliesRemainingKey = 'daily_replies_remaining';
  static const String dailyRepliesLimitKey = 'daily_replies_limit';
  static const String justSignedUpKey = 'just_signed_up';

  // Store auth token
  static Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
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
      await prefs.setInt(subscriberWeeklyRemainingKey, subscriberWeeklyRemaining);
    }
    if (subscriberWeeklyLimit != null) {
      await prefs.setInt(subscriberWeeklyLimitKey, subscriberWeeklyLimit);
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
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

  // Update stored credits
  static Future<void> updateStoredCredits(int credits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(creditsKey, credits);
  }

  // Clear all stored data
  static Future<void> clearStoredData() async {
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
    await prefs.remove(guestIdKey);
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
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      if (authResponse.success &&
          authResponse.token != null &&
          authResponse.user != null) {
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

      final response = await http.get(
        Uri.parse('$baseUrl/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      final data = jsonDecode(response.body);
      final profileResponse = ProfileResponse.fromJson(data);

      if (profileResponse.success && profileResponse.user != null) {
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

  static Future<String> getOrCreateGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(guestIdKey);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final androidId = await const AndroidId().getId();
        if (androidId != null && androidId.isNotEmpty) {
          if (existing != androidId) {
            await prefs.setString(guestIdKey, androidId);
          }
          return androidId;
        }
      } catch (e) {
        AppLogger.error('Android ID lookup failed', e is Exception ? e : null);
      }
    }
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final id = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await prefs.setString(guestIdKey, id);
    return id;
  }

  static Future<void> updateSubscriptionFromPayload(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    if (json.containsKey('is_subscribed')) {
      await prefs.setBool(subscriptionKey, json['is_subscribed'] == true);
    }
    if (json['subscription_expiry'] != null) {
      await prefs.setString(subscriptionExpiryKey, json['subscription_expiry'].toString());
    }
    // Legacy weekly fields
    if (json['subscriber_weekly_remaining'] != null) {
      await prefs.setInt(subscriberWeeklyRemainingKey, json['subscriber_weekly_remaining'] as int);
    }
    if (json['subscriber_weekly_limit'] != null) {
      await prefs.setInt(subscriberWeeklyLimitKey, json['subscriber_weekly_limit'] as int);
    }
    // New daily fields
    if (json['daily_openers_remaining'] != null) {
      await prefs.setInt(dailyOpenersRemainingKey, json['daily_openers_remaining'] as int);
    }
    if (json['daily_openers_limit'] != null) {
      await prefs.setInt(dailyOpenersLimitKey, json['daily_openers_limit'] as int);
    }
    if (json['daily_replies_remaining'] != null) {
      await prefs.setInt(dailyRepliesRemainingKey, json['daily_replies_remaining'] as int);
    }
    if (json['daily_replies_limit'] != null) {
      await prefs.setInt(dailyRepliesLimitKey, json['daily_replies_limit'] as int);
    }
  }
}
