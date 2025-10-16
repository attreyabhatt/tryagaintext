import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../models/suggestion.dart';
import '../../models/user.dart';
import 'login_screen.dart';
import 'package:flirtfix/views/screens/pricing_screen.dart';

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

  // Authentication state
  User? _currentUser;
  int _chatCredits = 0;
  bool _isLoggedIn = false;
  bool _isTrialExpired = false;

  // Initialize API client
  final _apiClient = ApiClient('https://tryagaintext.com');

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      final user = await AuthService.getStoredUser();
      final credits = await AuthService.getStoredCredits();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _chatCredits = credits;
          _isLoggedIn = true;
        });
      }

      // Refresh user data from server
      await AuthService.refreshUserData();
      final updatedCredits = await AuthService.getStoredCredits();

      if (mounted) {
        setState(() {
          _chatCredits = updatedCredits;
        });
      }
    }
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
                  ? 'Your free trial has expired. Sign up to get 6 free credits and continue using FlirtFix!'
                  : 'You need credits to generate replies. Sign up now to get 6 free credits!',
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

    if (result == true) {
      _navigateToAuth();
    }
  }

  Future<void> _navigateToAuth() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (result == true) {
      // User successfully logged in, refresh data
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Welcome back! You have $_chatCredits credits'),
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PricingScreen()),
    );

    // Refresh credits after returning from pricing
    if (mounted) {
      await _loadUserData();
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

    if (confirm == true) {
      await AuthService.logout();
      setState(() {
        _currentUser = null;
        _chatCredits = 0;
        _isLoggedIn = false;
        _isTrialExpired = false;
        _suggestions = [];
      });
    }
  }

  Future<void> _generateSuggestions() async {
    if (_situation != 'just_matched' && _conversationCtrl.text.trim().isEmpty) {
      _showError('Please add your conversation first');
      return;
    }

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

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });

      // Update credits if logged in
      if (_isLoggedIn) {
        final updatedCredits = await AuthService.getStoredCredits();
        setState(() {
          _chatCredits = updatedCredits;
        });
      }

      if (suggestions.isNotEmpty) {
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (e is InsufficientCreditsException || e is TrialExpiredException) {
        setState(() {
          _isTrialExpired = true;
        });

        // Check if user is logged in to determine which flow
        if (_isLoggedIn) {
          // Logged-in user out of credits - go to pricing
          await _navigateToPricing();
        } else {
          // Guest user trial expired - show signup dialog
          await _showAuthDialog();
        }
      } else {
        setState(() {
          _errorMessage = 'Oops! Something went wrong. Please try again.';
        });
      }
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

      final extractedConversation = await _apiClient.extractFromImage(file);

      if (extractedConversation.isEmpty ||
          extractedConversation.toLowerCase().contains('failed to extract')) {
        throw Exception(
          'Could not extract conversation from image. Please try a clearer screenshot.',
        );
      }

      setState(() {
        _conversationCtrl.text = extractedConversation;
        _isExtractingImage = false;
        _suggestions = [];
      });

      // Update credits if logged in
      if (_isLoggedIn) {
        final updatedCredits = await AuthService.getStoredCredits();
        setState(() {
          _chatCredits = updatedCredits;
        });
      }

      _animationController.reset();

      if (mounted) {
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
      }
    } catch (e) {
      setState(() {
        _isExtractingImage = false;
      });

      if (e is InsufficientCreditsException || e is TrialExpiredException) {
        setState(() {
          _isTrialExpired = true;
        });

        // Check if user is logged in to determine which flow
        if (_isLoggedIn) {
          // Logged-in user out of credits - go to pricing
          await _navigateToPricing();
        } else {
          // Guest user trial expired - show signup dialog
          await _showAuthDialog();
        }
      } else {
        setState(() {
          _errorMessage = e.toString().contains('Exception: ')
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Could not process screenshot. Please try again or paste text manually.';
        });
      }
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

      print('Analyzing profile image: ${image.path}');

      final profileInfo = await _apiClient.analyzeProfile(file);

      if (profileInfo.isEmpty ||
          profileInfo.toLowerCase().contains('failed') ||
          profileInfo.toLowerCase().contains('unable')) {
        throw Exception(
          'Could not analyze the image. Please try a clearer screenshot or photo.',
        );
      }

      setState(() {
        _herInfoCtrl.text = profileInfo;
        _isAnalyzingProfile = false;
        _suggestions = [];
      });

      _animationController.reset();

      if (mounted) {
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
      }
    } catch (e) {
      print('Profile analysis error: $e');
      setState(() {
        _isAnalyzingProfile = false;
        _errorMessage = e.toString().contains('Exception: ')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Could not analyze profile. Please try again or add details manually.';
      });
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  Future<void> _copySuggestion(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
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
          // Credits display
          if (_isLoggedIn) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.credit_card, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '$_chatCredits',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Settings/Profile menu
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'login':
                  _navigateToAuth();
                  break;
                case 'buy_credits':
                  _navigateToPricing();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (!_isLoggedIn)
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
              if (_isLoggedIn) ...[
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.username ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_chatCredits credits',
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
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isLoggedIn ? Icons.person : Icons.person_outline,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trial warning banner
              if (!_isLoggedIn && _isTrialExpired) ...[
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
              if (_isLoggedIn && _chatCredits == 0) ...[
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
              if (_isLoggedIn && _chatCredits > 0 && _chatCredits <= 2) ...[
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
                              'You have $_chatCredits credits remaining',
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
                      color: Colors.black.withOpacity(0.08),
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

              // Tone Selector - Only show for "Need Reply" situation
              if (_situation == 'stuck_after_reply') ...[
                Row(
                  children: [
                    Text(
                      'Tone:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCompactToneChip('Natural', '😊'),
                            const SizedBox(width: 8),
                            _buildCompactToneChip('Flirty', '😏'),
                            const SizedBox(width: 8),
                            _buildCompactToneChip('Funny', '😂'),
                            const SizedBox(width: 8),
                            _buildCompactToneChip('Serious', '🤔'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Input Section
              if (_situation == 'just_matched') ...[
                _buildSectionTitle('Tell us about them', '💕'),
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
                            : theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isAnalyzingProfile
                              ? Colors.grey[300]!
                              : theme.primaryColor.withOpacity(0.3),
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
                        color: Colors.black.withOpacity(0.05),
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
                          color: theme.primaryColor.withOpacity(0.1),
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
                _buildSectionTitle('Your conversation', '💬'),
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
                                  : theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isExtractingImage
                                    ? Colors.grey[300]!
                                    : theme.primaryColor.withOpacity(0.3),
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
                        color: Colors.black.withOpacity(0.05),
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
                        .withOpacity(0.12),
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
                        color: Colors.black.withOpacity(0.05),
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
                          color: theme.primaryColor.withOpacity(0.1),
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
                        color: Colors.black.withOpacity(0.05),
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _copySuggestion(suggestion.message),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getConfidenceColor(
                                              suggestion.confidence,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '#${index + 1}',
                                            style: TextStyle(
                                              color: _getConfidenceColor(
                                                suggestion.confidence,
                                              ),
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
                                            color: _getConfidenceColor(
                                              suggestion.confidence,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.trending_up,
                                                size: 14,
                                                color: _getConfidenceColor(
                                                  suggestion.confidence,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${(suggestion.confidence * 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  color: _getConfidenceColor(
                                                    suggestion.confidence,
                                                  ),
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
                                        Icon(
                                          Icons.touch_app,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
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
                      }).toList(),
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

  Widget _buildSectionTitle(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
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

  Widget _buildCompactToneChip(String tone, String emoji) {
    final isSelected = _selectedTone == tone;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTone = tone;
          _suggestions = [];
          _errorMessage = null;
          _animationController.reset();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              tone,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
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
