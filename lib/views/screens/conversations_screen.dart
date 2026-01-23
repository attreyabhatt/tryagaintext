import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../state/app_state.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../models/suggestion.dart';
import '../../utils/app_logger.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'package:flirtfix/views/screens/pricing_screen.dart';
import 'package:flirtfix/views/screens/profile_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with TickerProviderStateMixin {
  static const TextStyle _primaryButtonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  String _situation = 'stuck_after_reply';
  final String _selectedTone = 'Natural';
  final _conversationCtrl = TextEditingController();
  final _customInstructionsCtrl = TextEditingController();
  final _newMatchCustomInstructionsCtrl = TextEditingController();
  List<Suggestion> _suggestions = [];
  bool _isLoading = false;
  bool _isExtractingImage = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  bool _isTrialExpired = false;
  final _apiClient = ApiClient();
  File? _uploadedConversationImage;
  File? _uploadedProfileImage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    HapticFeedback.selectionClick();
    setState(() {
      _situation = _tabController.index == 0 ? 'just_matched' : 'stuck_after_reply';
      _suggestions = [];
      _errorMessage = null;
      _animationController.reset();
      final controller = _situation == 'just_matched'
          ? _newMatchCustomInstructionsCtrl
          : _customInstructionsCtrl;
      _refreshSelectedTags(controller);
    });
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
      if (mounted) {
        final justSignedUp = await AuthService.consumeJustSignedUp();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  justSignedUp
                      ? 'Account created. You have been signed in'
                      : 'Welcome back!',
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
    await AppStateScope.of(context).reloadFromStorage();
    if (!mounted) return;
    if (purchased == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscription activated!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  Future<void> _generateSuggestions() async {
    // For New Match tab, require a profile image
    if (_situation == 'just_matched' && _uploadedProfileImage == null) {
      _showError('Please upload a profile screenshot first');
      return;
    }

    // For Need Reply tab, require conversation text
    if (_situation != 'just_matched' && _conversationCtrl.text.trim().isEmpty) {
      _showError('Please add your conversation first');
      return;
    }

    await _logDebugState();
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestions = [];
      _isTrialExpired = false; // reset flag on new attempt
    });

    try {
      List<Suggestion> suggestions;

      if (_situation == 'just_matched') {
        // Use the new image-based opener generation endpoint
        suggestions = await _apiClient.generateOpenersFromImage(
          _uploadedProfileImage!,
          customInstructions: _newMatchCustomInstructionsCtrl.text,
        );
      } else {
        // Use the regular text-based generation endpoint
        suggestions = await _apiClient.generate(
          lastText: _conversationCtrl.text,
          situation: _situation,
          herInfo: '',
          tone: _selectedTone,
          customInstructions: _customInstructionsCtrl.text,
        );
      }

      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
        _isTrialExpired = false; // clear any prior trial-expired banner on success
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
      );

      if (image == null) return;

      setState(() {
        _isExtractingImage = true;
        _uploadedConversationImage = File(image.path);
      });

      final extractedText = await _apiClient.extractFromImage(File(image.path));

      if (!mounted) return;
      setState(() {
        _conversationCtrl.text = extractedText;
        _isExtractingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExtractingImage = false;
        _uploadedConversationImage = null;
      });
      _showError('Failed to extract text from image. Please try again.');
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _uploadedProfileImage = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to select image. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  bool _isCreditError(ApiException e) {
    return e.code == ApiErrorCode.insufficientCredits ||
        e.code == ApiErrorCode.trialExpired;
  }

  Future<void> _logDebugState() async {
    final token = await AuthService.getToken();
    final guestId = await AuthService.getOrCreateGuestId();
    final appState = AppStateScope.of(context);
    AppLogger.debug(
      'Generate tapped | isLoggedIn=${appState.isLoggedIn} | isSubscribed=${appState.isSubscribed} '
      '| tokenPresent=${token != null && token.isNotEmpty} | tokenLen=${token?.length ?? 0} '
      '| guestId=$guestId | baseUrl=${_apiClient.baseUrl}',
    );
  }

  Future<void> _handleCreditError(ApiException e) async {
    if (e.code == ApiErrorCode.trialExpired) {
      if (mounted) {
        setState(() {
          _isTrialExpired = true;
        });
      }
    }
  }

  Future<void> _navigateToSignup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );

    if (!mounted) return;
    if (result == true) {
      final appState = AppStateScope.of(context);
      await appState.reloadFromStorage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Account created. You have been signed in'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  void _copySuggestion(String message) {
    Clipboard.setData(ClipboardData(text: message));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Copied to clipboard!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = AppStateScope.of(context);
    final isLoggedIn = appState.isLoggedIn;
    final credits = appState.credits;
    final isSubscribed = appState.isSubscribed;
    final username = appState.user?.username ?? '';
    const double sectionSpacing = 20;

    return Scaffold(
      appBar: _buildAppBar(colorScheme, isLoggedIn, credits, isSubscribed, username),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banners
            _buildWarningBanners(colorScheme, isLoggedIn, credits, isSubscribed),

            const SizedBox(height: 8),

            // Tab bar for situation selection
            _buildTabBar(colorScheme),

            SizedBox(height: sectionSpacing),

            // Input section
            _buildInputSection(colorScheme),

            SizedBox(height: sectionSpacing),

            // Custom instructions section
            _buildCustomInstructionsSection(colorScheme),

            SizedBox(height: sectionSpacing),

            // Generate button
            _buildGenerateButton(colorScheme),

            SizedBox(height: sectionSpacing),

            // Results section
            _buildResultsSection(colorScheme),

            SizedBox(height: sectionSpacing),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    bool isLoggedIn,
    int credits,
    bool isSubscribed,
    String username,
  ) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/images/icons/appstore_transparent.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FlirtFix',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Your dating wingman',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (isLoggedIn && !isSubscribed) ...[
          // Credits badge
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _navigateToPricing();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$credits',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Profile button
        IconButton(
          onPressed: () {
            if (isLoggedIn) {
              _navigateToProfile();
            } else {
              _navigateToAuth();
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLoggedIn ? Icons.person : Icons.person_outline,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWarningBanners(
    ColorScheme colorScheme,
    bool isLoggedIn,
    int credits,
    bool isSubscribed,
  ) {
    if (isSubscribed) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        // Trial expired banner
        if (!isLoggedIn && _isTrialExpired)
          _buildBanner(
            colorScheme: colorScheme,
            icon: Icons.timer_off_outlined,
            title: 'Limit reached',
            subtitle: 'Sign up to keep using FlirtFix',
            buttonText: 'Sign Up',
            onPressed: _navigateToSignup,
            type: BannerType.warning,
          ),

        // Out of credits banner
        if (isLoggedIn && credits == 0)
          _buildBanner(
            colorScheme: colorScheme,
            icon: Icons.credit_card_off_outlined,
            title: 'Start your subscription',
            subtitle: 'Unlimited replies with FlirtFix Unlimited',
            buttonText: 'Subscribe',
            onPressed: _navigateToPricing,
            type: BannerType.error,
          ),

      ],
    );
  }

  Widget _buildBanner({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onPressed,
    required BannerType type,
  }) {
    final Color backgroundColor;
    final Color foregroundColor;

    switch (type) {
      case BannerType.error:
        backgroundColor = colorScheme.errorContainer;
        foregroundColor = colorScheme.onErrorContainer;
        break;
      case BannerType.warning:
        backgroundColor = colorScheme.tertiaryContainer;
        foregroundColor = colorScheme.onTertiaryContainer;
        break;
      case BannerType.info:
        backgroundColor = colorScheme.secondaryContainer;
        foregroundColor = colorScheme.onSecondaryContainer;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: foregroundColor.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (buttonText != null && onPressed != null)
            FilledButton.tonal(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: foregroundColor.withValues(alpha: 0.15),
                foregroundColor: foregroundColor,
              ),
              child: Text(buttonText),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_outline, size: 20),
                const SizedBox(width: 8),
                const Text('New Match'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                const Text('Need Reply'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme) {
    if (_situation == 'just_matched') {
      return _buildProfileInputSection(colorScheme);
    } else {
      return _buildConversationInputSection(colorScheme);
    }
  }

  // Suggestion tags for custom instructions
  static const List<String> _instructionTags = [
    'Ask her out',
    'She left me on read',
    'Change topics',
    'Make it romantic',
    'Make her laugh',
    'Get her number',
    'Flirt with her',
    'Be vulnerable',
  ];

  final Set<String> _selectedInstructionTags = {};

  List<String> _splitInstructionTokens(String text) {
    return text
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  void _refreshSelectedTags(TextEditingController controller) {
    final tokens = _splitInstructionTokens(controller.text);
    _selectedInstructionTags
      ..clear()
      ..addAll(tokens.where(_instructionTags.contains));
  }

  void _toggleTagInInstructions(String tag) {
    final controller = _situation == 'just_matched'
        ? _newMatchCustomInstructionsCtrl
        : _customInstructionsCtrl;

    final tokens = _splitInstructionTokens(controller.text);
    if (tokens.contains(tag)) {
      tokens.removeWhere((entry) => entry == tag);
    } else {
      tokens.add(tag);
    }

    final updated = tokens.join(', ');
    controller.value = controller.value.copyWith(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );

    setState(() {
      _refreshSelectedTags(controller);
    });
  }

  Widget _buildCustomInstructionsSection(ColorScheme colorScheme) {
    final controller = _situation == 'just_matched'
        ? _newMatchCustomInstructionsCtrl
        : _customInstructionsCtrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_note,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Custom Instructions',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 2,
          minLines: 2,
          decoration: InputDecoration(
            hintText: _situation == 'just_matched'
                ? 'e.g., "mention her dog", "write a poem", "comment on her bio"'
                : 'e.g., "roast her", "talk like a pirate", "she is a writer"',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        controller.clear();
                      });
                    },
                  )
                : null,
          ),
          onChanged: (_) {
            setState(() {
              _refreshSelectedTags(controller);
            });
          },
        ),
        // Only show tags on Need Reply tab
        if (_situation != 'just_matched') ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _instructionTags.map((tag) {
              final isSelected = _selectedInstructionTags.contains(tag);
              return InputChip(
                label: Text(tag),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) => _toggleTagInInstructions(tag),
                onDeleted: isSelected ? () => _toggleTagInInstructions(tag) : null,
                deleteIcon: const Icon(Icons.close, size: 16),
                deleteIconColor: colorScheme.onPrimary,
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileInputSection(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Their profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Upload button (only show if no image uploaded)
            if (_uploadedProfileImage == null)
              FilledButton(
                onPressed: _uploadProfileImage,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Upload Profile Screenshot'),
                  ],
                ),
              ),

            // Image preview (show when image is uploaded)
            if (_uploadedProfileImage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _uploadedProfileImage!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Profile screenshot ready',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Get Smart Openers" to generate personalized first messages',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _uploadedProfileImage = null;
                          _suggestions = [];
                          _animationController.reset();
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversationInputSection(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your conversation',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Upload button
            FilledButton(
              onPressed: _isExtractingImage ? null : _uploadScreenshot,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_camera_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text('Upload Conversation Screenshot'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Image preview - horizontal row layout
            if (_isExtractingImage && _uploadedConversationImage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _uploadedConversationImage!,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Extracting conversation...',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_uploadedConversationImage != null &&
                _conversationCtrl.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _uploadedConversationImage!,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Conversation extracted',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _conversationCtrl.text.length > 80
                                ? '${_conversationCtrl.text.substring(0, 80)}...'
                                : _conversationCtrl.text,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _uploadedConversationImage = null;
                          _conversationCtrl.clear();
                          _suggestions = [];
                          _animationController.reset();
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(ColorScheme colorScheme) {
    return FilledButton(
      onPressed: (_isLoading || _isExtractingImage) ? null : _generateSuggestions,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: _primaryButtonTextStyle,
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Crafting replies...', style: _primaryButtonTextStyle),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 22),
                const SizedBox(width: 12),
                Text(
                  _suggestions.isNotEmpty
                      ? 'Regenerate'
                      : (_situation == 'just_matched' ? 'Get Smart Openers' : 'Get Smart Replies'),
                  style: _primaryButtonTextStyle,
                ),
              ],
            ),
    );
  }

  Widget _buildResultsSection(ColorScheme colorScheme) {
    // Error state
    if (_errorMessage != null) {
      return Card(
        elevation: 0,
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isLoading) {
      return SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimaryContainer,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Analyzing your conversation...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This might take a few seconds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Empty state
    if (_suggestions.isEmpty) {
      return Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 40,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ready to help you connect!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your conversation details and we\'ll suggest the perfect replies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Results
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_suggestions.length} Smart Replies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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
              colorScheme: colorScheme,
              onTap: () => _copySuggestion(suggestion.message),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _conversationCtrl.dispose();
    _customInstructionsCtrl.dispose();
    _newMatchCustomInstructionsCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

enum BannerType { error, warning, info }

class _SuggestionCard extends StatelessWidget {
  final int index;
  final Suggestion suggestion;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.index,
    required this.suggestion,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.copy_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                suggestion.message,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
