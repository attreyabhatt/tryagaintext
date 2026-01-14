import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../state/app_state.dart';
import '../../utils/app_logger.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../models/suggestion.dart';
import 'login_screen.dart';
import 'package:flirtfix/views/screens/pricing_screen.dart';
import 'package:flirtfix/views/screens/report_issue_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  String _situation = 'stuck_after_reply';
  String _selectedTone = 'Natural'; // Default tone
  final _conversationCtrl = TextEditingController();
  final _herInfoCtrl = TextEditingController();
  List<Suggestion> _suggestions = [];
  bool _isLoading = false;
  bool _isExtractingImage = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isTrialExpired = false;

  // Initialize API client
  final _apiClient = ApiClient();

  bool _isAnalyzingProfile = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _showAuthDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Credits Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              _isTrialExpired
                  ? 'Your free trial has expired. Sign up to get free credits and continue using FlirtFix!'
                  : 'You need credits to generate replies. Sign up now to get free credits!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == true) {
      _navigateToAuth();
    }
  }

  Future<void> _navigateToAuth() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (!mounted) return;
    if (result == true) {
      final appState = AppStateScope.of(context);
      await appState.reloadFromStorage();
      // User successfully logged in, refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Welcome back! You have ${appState.credits} credits'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navigateToPricing() async {
    final purchased = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PricingScreen()),
    );

    if (!mounted) return;
    // Refresh credits after returning from pricing
    await AppStateScope.of(context).reloadFromStorage();
    if (purchased == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Purchase successful. Credits added!'),
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      setState(() {
        _isTrialExpired = false;
        _suggestions = [];
      });
      await AppStateScope.of(context).logout();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _navigateToReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
    );
  }

  Future<void> _generateSuggestions() async {
    if (_situation != 'just_matched' && _conversationCtrl.text.trim().isEmpty) {
      _showError('Please add your conversation first');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestions = [];
    });

    try {
      final suggestions = await _apiClient.generate(
        lastText: _situation == 'just_matched'
            ? 'just_matched'
            : _conversationCtrl.text,
        situation: _situation,
        herInfo: _situation == 'just_matched' ? _herInfoCtrl.text : '',
        tone: _selectedTone,
      );

      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });

      await AppStateScope.of(context).reloadFromStorage();

      if (suggestions.isNotEmpty) {
        _animationController.forward();
      }
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (_isCreditError(e)) {
        await _handleCreditError(e);
      } else {
        setState(() {
          _errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Oops! Something went wrong. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Oops! Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _uploadScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;
      HapticFeedback.selectionClick();

      setState(() {
        _isExtractingImage = true;
        _errorMessage = null;
      });

      final file = File(image.path);
      if (!await file.exists()) {
        throw Exception('Selected file does not exist');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Selected file is empty');
      }

      if (fileSize > 10 * 1024 * 1024) {
        throw Exception(
          'File size too large. Please select an image under 10MB.',
        );
      }

      final buffer = StringBuffer();
      await for (final event in _apiClient.extractFromImageStream(file)) {
        if (!mounted) return;
        final type = event['type']?.toString();

        if (type == 'reset') {
          buffer.clear();
          _conversationCtrl.text = '';
          continue;
        }

        if (type == 'delta') {
          buffer.write(event['text']?.toString() ?? '');
          _conversationCtrl.text = buffer.toString();
          _conversationCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _conversationCtrl.text.length),
          );
        } else if (type == 'done') {
          final extractedConversation =
              event['conversation']?.toString() ?? buffer.toString();

          if (event['credits_remaining'] is int) {
            await AuthService.updateStoredCredits(
              event['credits_remaining'] as int,
            );
            await AppStateScope.of(context).reloadFromStorage();
          }

          setState(() {
            _conversationCtrl.text = extractedConversation;
            _isExtractingImage = false;
            _suggestions = [];
          });

          _animationController.reset();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Screenshot processed successfully!'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        } else if (type == 'error') {
          final errorCode = event['error']?.toString();
          if (errorCode == 'insufficient_credits' ||
              errorCode == 'trial_expired') {
            setState(() {
              _isExtractingImage = false;
            });
            await _handleCreditError(
              ApiException(
                event['message']?.toString() ?? 'Credits required',
                errorCode == 'trial_expired'
                    ? ApiErrorCode.trialExpired
                    : ApiErrorCode.insufficientCredits,
              ),
            );
          } else {
            setState(() {
              _errorMessage =
                  event['message']?.toString() ??
                  'Could not process screenshot. Please try again or paste text manually.';
              _isExtractingImage = false;
            });
          }
          return;
        }
      }
    } on ApiException catch (e) {
      setState(() {
        _isExtractingImage = false;
      });

      if (_isCreditError(e)) {
        await _handleCreditError(e);
      } else {
        setState(() {
          _errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Could not process screenshot. Please try again or paste text manually.';
        });
      }
    } catch (e) {
      setState(() {
        _isExtractingImage = false;
        _errorMessage =
            'Could not process screenshot. Please try again or paste text manually.';
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;
      HapticFeedback.selectionClick();

      setState(() {
        _isAnalyzingProfile = true;
        _errorMessage = null;
      });

      final file = File(image.path);
      if (!await file.exists()) {
        throw Exception('Selected file does not exist');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Selected file is empty');
      }

      if (fileSize > 10 * 1024 * 1024) {
        throw Exception(
          'File size too large. Please select an image under 10MB.',
        );
      }

      AppLogger.debug('Analyzing profile image: ${image.path}');

      final buffer = StringBuffer();
      await for (final event in _apiClient.analyzeProfileStream(file)) {
        if (!mounted) return;
        final type = event['type']?.toString();

        if (type == 'delta') {
          buffer.write(event['text']?.toString() ?? '');
          _herInfoCtrl.text = buffer.toString();
          _herInfoCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _herInfoCtrl.text.length),
          );
        } else if (type == 'done') {
          final profileInfo =
              event['profile_info']?.toString() ?? buffer.toString();
          setState(() {
            _herInfoCtrl.text = profileInfo;
            _isAnalyzingProfile = false;
            _suggestions = [];
          });

          _animationController.reset();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profile analyzed successfully!'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        } else if (type == 'error') {
          setState(() {
            _isAnalyzingProfile = false;
            _errorMessage =
                event['message']?.toString() ??
                'Could not analyze profile. Please try again or add details manually.';
          });
          return;
        }
      }
    } on ApiException catch (e) {
      setState(() {
        _isAnalyzingProfile = false;
        _errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Could not analyze profile. Please try again or add details manually.';
      });
    } catch (e) {
      setState(() {
        _isAnalyzingProfile = false;
        _errorMessage =
            'Could not analyze profile. Please try again or add details manually.';
      });
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  bool _isCreditError(ApiException error) {
    return error.code == ApiErrorCode.insufficientCredits ||
        error.code == ApiErrorCode.trialExpired;
  }

  Future<void> _handleCreditError(ApiException error) async {
    setState(() {
      _isTrialExpired = error.code == ApiErrorCode.trialExpired;
    });

    final isLoggedIn = AppStateScope.of(context).isLoggedIn;
    if (isLoggedIn) {
      await _navigateToPricing();
    } else {
      await _showAuthDialog();
    }
  }

  Future<void> _copySuggestion(String message) async {
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Copied to clipboard!'),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateScope.of(context);
    final isLoggedIn = appState.isLoggedIn;
    final credits = appState.credits;
    final username = appState.user?.username ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _ConversationsAppBar(
        isLoggedIn: isLoggedIn,
        credits: credits,
        username: username,
        onLogin: _navigateToAuth,
        onBuyCredits: _navigateToPricing,
        onReportIssue: _navigateToReport,
        onLogout: _handleLogout,
        onTapCredits: _navigateToPricing,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trial warning banner
              if (!isLoggedIn && _isTrialExpired) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Free trial expired',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            Text(
                              'Sign up to get 3 more free credits',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _navigateToAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Out of credits banner for logged-in users
              if (isLoggedIn && credits == 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Out of credits',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                            Text(
                              'Purchase credits to continue',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _navigateToPricing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Buy Now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Low credits warning (only show for 1-2 credits, not 0)
              if (isLoggedIn && credits > 0 && credits <= 2) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.battery_2_bar, color: Colors.amber[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low credits',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                            Text(
                              'You have $credits credits remaining',
                              style: TextStyle(color: Colors.amber[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Rest of the UI remains the same as in the original ConversationsScreen
              // Situation Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: theme.primaryColor,
                    selectedForegroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    side: BorderSide.none,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'just_matched',
                      label: Text(
                        'New Match',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(Icons.favorite_border, size: 18),
                    ),
                    ButtonSegment(
                      value: 'stuck_after_reply',
                      label: Text(
                        'Need Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(Icons.chat_bubble_outline, size: 18),
                    ),
                    ButtonSegment(
                      value: 'left_on_read',
                      label: Text(
                        'Left on Read',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: Icon(Icons.visibility_off, size: 18),
                    ),
                  ],
                  selected: {_situation},
                  onSelectionChanged: (s) => setState(() {
                    _situation = s.first;
                    _suggestions = [];
                    _errorMessage = null;
                    _animationController.reset();
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // Alternative: Dropdown style tone selector
              if (_situation == 'stuck_after_reply') ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTone,
                    decoration: InputDecoration(
                      labelText: 'Tone',
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: theme.primaryColor,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Natural',
                        child: Text('Natural'),
                      ),
                      DropdownMenuItem(value: 'Flirty', child: Text('Flirty')),
                      DropdownMenuItem(value: 'Funny', child: Text('Funny')),
                      DropdownMenuItem(
                        value: 'Serious',
                        child: Text('Serious'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTone = value;
                          _suggestions = [];
                          _errorMessage = null;
                          _animationController.reset();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Input Section
              if (_situation == 'just_matched') ...[
                _buildSectionTitle('Tell us about them', Icons.person),
                const SizedBox(height: 16),

                // Upload profile image button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: GestureDetector(
                    onTap: _isAnalyzingProfile ? null : _uploadProfileImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _isAnalyzingProfile
                            ? Colors.grey[100]
                            : theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isAnalyzingProfile
                              ? Colors.grey[300]!
                              : theme.primaryColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isAnalyzingProfile) ...[
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Analyzing profile...',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ] else ...[
                            Icon(Icons.photo_camera, color: theme.primaryColor),
                            const SizedBox(width: 12),
                            Text(
                              'Upload Profile Screenshot',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _herInfoCtrl,
                    minLines: 3,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText:
                          'Loves hiking, has 2 dogs, studies medicine...\n\nOr upload a profile screenshot above!',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(20),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.person, color: theme.primaryColor),
                      ),
                      suffixIcon: _herInfoCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: () {
                                setState(() {
                                  _herInfoCtrl.clear();
                                  _suggestions = [];
                                  _animationController.reset();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ] else ...[
                _buildSectionTitle('Your conversation', Icons.forum),
                const SizedBox(height: 16),

                // Upload or paste options
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isExtractingImage ? null : _uploadScreenshot,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: _isExtractingImage
                                  ? Colors.grey[100]
                                  : theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isExtractingImage
                                    ? Colors.grey[300]!
                                    : theme.primaryColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isExtractingImage) ...[
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.photo_library,
                                    color: theme.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Upload Screenshot',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _conversationCtrl,
                    minLines: 6,
                    maxLines: 10,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: _situation == 'stuck_after_reply'
                          ? "You: How was your weekend?\nThem: Pretty good, went hiking!\nYou: That sounds amazing! Where did you go?"
                          : "You: Want to grab coffee this Thursday?\nThem: (seen 2 hours ago)",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(20),
                      suffixIcon: _conversationCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: () {
                                setState(() {
                                  _conversationCtrl.clear();
                                  _suggestions = [];
                                  _animationController.reset();
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isExtractingImage)
                      ? null
                      : _generateSuggestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Crafting replies...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.auto_awesome, size: 22),
                        const SizedBox(width: 12),
                        const Text(
                          'Get Smart Replies',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Results Section
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_isLoading) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          color: theme.primaryColor,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing your conversation...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This might take a few seconds',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ] else if (_suggestions.isEmpty && _errorMessage == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 40,
                          color: Colors.blue[400],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ready to help you connect!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share your conversation details and we\'ll suggest the perfect replies',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_suggestions.length} Smart Replies',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ..._suggestions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final suggestion = entry.value;

                        return _SuggestionCard(
                          index: index,
                          suggestion: suggestion,
                          onTap: () => _copySuggestion(suggestion.message),
                          getConfidenceColor: _getConfidenceColor,
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green[600]!;
    if (confidence >= 0.6) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  @override
  void dispose() {
    _conversationCtrl.dispose();
    _herInfoCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class _ConversationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isLoggedIn;
  final int credits;
  final String username;
  final VoidCallback onLogin;
  final VoidCallback onBuyCredits;
  final VoidCallback onReportIssue;
  final VoidCallback onLogout;
  final VoidCallback onTapCredits;

  const _ConversationsAppBar({
    required this.isLoggedIn,
    required this.credits,
    required this.username,
    required this.onLogin,
    required this.onBuyCredits,
    required this.onReportIssue,
    required this.onLogout,
    required this.onTapCredits,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FlirtFix',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Your dating conversation wingman',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isLoggedIn) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTapCredits();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.credit_card, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '$credits',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'login':
                onLogin();
                break;
              case 'buy_credits':
                onBuyCredits();
                break;
              case 'report':
                onReportIssue();
                break;
              case 'logout':
                onLogout();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isLoggedIn)
              const PopupMenuItem(
                value: 'login',
                child: Row(
                  children: [
                    Icon(Icons.login),
                    SizedBox(width: 8),
                    Text('Sign In'),
                  ],
                ),
              ),
            if (isLoggedIn) ...[
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$credits credits',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'buy_credits',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart),
                    SizedBox(width: 8),
                    Text('Buy Credits'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_outlined),
                    SizedBox(width: 8),
                    Text('Report an Issue'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
            if (!isLoggedIn)
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_outlined),
                    SizedBox(width: 8),
                    Text('Report an Issue'),
                  ],
                ),
              ),
          ],
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isLoggedIn ? Icons.person : Icons.person_outline,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final int index;
  final Suggestion suggestion;
  final VoidCallback onTap;
  final Color Function(double) getConfidenceColor;

  const _SuggestionCard({
    required this.index,
    required this.suggestion,
    required this.onTap,
    required this.getConfidenceColor,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceColor = getConfidenceColor(suggestion.confidence);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: confidenceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: confidenceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: confidenceColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(suggestion.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: confidenceColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  suggestion.message,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.touch_app, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to copy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
