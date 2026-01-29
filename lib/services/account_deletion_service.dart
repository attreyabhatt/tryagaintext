import 'auth_service.dart';
import 'api_client.dart';

class AccountDeletionService {
  /// Phase 2 Implementation: Direct API call to delete account
  ///
  /// This implementation calls the backend API endpoint to delete the account.
  /// The backend handles password verification and deletes all user data.
  static Future<bool> deleteAccount({
    required String password,
  }) async {
    final apiClient = ApiClient();

    try {
      final success = await apiClient.deleteAccount(password: password);

      if (success) {
        // Clear all local data after successful deletion
        await AuthService.clearStoredData();
        return true;
      }

      throw Exception('Account deletion failed');
    } catch (e) {
      if (e is ApiException) {
        // Pass through API exceptions with specific error messages
        if (e.message.contains('Invalid password')) {
          throw Exception('Invalid password');
        }
        throw Exception(e.message);
      }

      if (e.toString().contains('Invalid password')) {
        throw Exception('Invalid password');
      }
      throw Exception('Account deletion failed. Please try again.');
    }
  }

  /// Phase 1 Implementation (Legacy - kept for reference):
  ///
  /// This was the initial implementation that verified password locally,
  /// opened a web form, and cleared local data. Now replaced by Phase 2
  /// which uses a direct API call to the backend.
  ///
  /// static Future<bool> deleteAccountPhase1({
  ///   required String password,
  /// }) async {
  ///   final userData = await AuthService.getStoredUser();
  ///   if (userData == null) {
  ///     throw Exception('No user data found. Please log in again.');
  ///   }
  ///
  ///   try {
  ///     final loginResponse = await AuthService.login(
  ///       username: userData.username,
  ///       password: password,
  ///     );
  ///
  ///     if (!loginResponse.success) {
  ///       throw Exception('Invalid password');
  ///     }
  ///   } catch (e) {
  ///     if (e.toString().contains('Invalid') || e.toString().contains('password')) {
  ///       throw Exception('Invalid password');
  ///     }
  ///     throw Exception('Unable to verify password. Please try again.');
  ///   }
  ///
  ///   final uri = Uri.parse('${AppConfig.baseUrl}/delete-account/');
  ///   final launched = await launchUrl(
  ///     uri,
  ///     mode: LaunchMode.externalApplication,
  ///   );
  ///
  ///   if (!launched) {
  ///     throw Exception('Could not open deletion form. Please try again later.');
  ///   }
  ///
  ///   await AuthService.clearStoredData();
  ///   return true;
  /// }
}
