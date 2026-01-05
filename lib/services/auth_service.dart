import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // Store auth token
  static Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Store user data
  static Future<void> _storeUser(User user, int credits) async {
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
      ).timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      if (authResponse.success &&
          authResponse.token != null &&
          authResponse.user != null) {
        await _storeToken(authResponse.token!);
        await _storeUser(authResponse.user!, authResponse.chatCredits ?? 0);
      }

      return authResponse;
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error('Registration request timed out', e, stackTrace);
      return AuthResponse(
        success: false,
        error: 'Request timed out. Please try again.',
      );
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
      ).timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      if (authResponse.success &&
          authResponse.token != null &&
          authResponse.user != null) {
        await _storeToken(authResponse.token!);
        await _storeUser(authResponse.user!, authResponse.chatCredits ?? 0);
      }

      return authResponse;
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error('Login request timed out', e, stackTrace);
      return AuthResponse(
        success: false,
        error: 'Request timed out. Please try again.',
      );
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
      ).timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body);
      final profileResponse = ProfileResponse.fromJson(data);

      if (profileResponse.success && profileResponse.user != null) {
        await _storeUser(
          profileResponse.user!,
          profileResponse.chatCredits ?? 0,
        );
      }

      return profileResponse;
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error('Profile request timed out', e, stackTrace);
      return ProfileResponse(
        success: false,
        error: 'Request timed out. Please try again.',
      );
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
}
