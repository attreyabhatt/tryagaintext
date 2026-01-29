import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
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
import '../widgets/thinking_indicator.dart';

const _smartReplyAccent = Color(0xFF4C9A4A);
const _smartReplyAccentSoft = Color(0xFFE6F4E7);
const _smartReplyCardShadow = Color(0x14000000);

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const TextStyle _primaryButtonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const bool _enableNewMatchCustomInstructions = false;
  static const String _ratingPromptShownKey = 'rating_prompt_shown';
  static const String _newMatchModeKey = 'new_match_mode';
  static const String _handledTokensKey = 'handled_purchase_tokens';
  static const String _trialExpiredKey = 'guest_trial_expired';
  static const String _keepItShortKey = 'keep_it_short_need_reply';
  String _situation = 'stuck_after_reply';
  final String _selectedTone = 'Natural';
  final _conversationCtrl = TextEditingController();
  final _customInstructionsCtrl = TextEditingController();
  final _newMatchCustomInstructionsCtrl = TextEditingController();
  bool _keepItShort = false;
  final ScrollController _scrollController = ScrollController();
  List<Suggestion> _suggestions = [];
  bool _isLoading = false;
  bool _isExtractingImage = false;
  bool _showBottomGradient = true;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  bool _isTrialExpired = false;
  bool _isOpenerLimitExceeded = false;
  bool _isReplyLimitExceeded = false;
  final _apiClient = ApiClient();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  File? _uploadedConversationImage;
  File? _uploadedProfileImage;
  NewMatchMode _newMatchMode = NewMatchMode.ai;
  int _generateRequestId = 0;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _purchaseListenerReady = false;
  bool _isRefreshingPurchases = false;
  bool _suppressActivationSnackbar = false;
  bool _hasShownSubscriptionActivated = false;
  final Set<String> _handledPurchaseTokens = {};
  final Set<String> _processingPurchaseTokens = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _scrollController.addListener(_onScroll);
    _loadNewMatchModePreference();
    _loadTrialExpiredState();
    _loadKeepItShortPreference();
    _setupPurchaseListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSubscriptionStatus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSubscriptionStatus();
      _refreshPendingPurchases();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Check if we're near the bottom (within 50 pixels)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isNearBottom = maxScroll - currentScroll <= 50;

    if (isNearBottom != !_showBottomGradient) {
      setState(() {
        _showBottomGradient = !isNearBottom;
      });
    }
  }

  Future<void> _refreshSubscriptionStatus() async {
    if (!mounted) return;
    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) return;
    await _apiClient.refreshSubscriptionStatus();
    await appState.reloadFromStorage();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadNewMatchModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_newMatchModeKey);
    if (!mounted) return;
    setState(() {
      _newMatchMode = saved == NewMatchMode.recommended.name
          ? NewMatchMode.recommended
          : NewMatchMode.ai;
    });
  }

  Future<void> _loadTrialExpiredState() async {
    final prefs = await SharedPreferences.getInstance();
    final isExpired = prefs.getBool(_trialExpiredKey) ?? false;
    if (!mounted) return;
    setState(() {
      _isTrialExpired = isExpired;
    });
  }

  Future<void> _loadKeepItShortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _keepItShort = prefs.getBool(_keepItShortKey) ?? false;
    });
  }

  Future<void> _setupPurchaseListener() async {
    if (_purchaseListenerReady || kIsWeb) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _purchaseListenerReady = true;
    await _loadHandledPurchaseTokens();

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      (purchases) {
        _handlePurchaseUpdates(purchases);
      },
      onError: (error) {
        AppLogger.error('Purchase stream error: $error');
      },
    );

    await _refreshPendingPurchases();
  }

  Future<void> _loadHandledPurchaseTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokens = prefs.getStringList(_handledTokensKey) ?? [];
      _handledPurchaseTokens
        ..clear()
        ..addAll(tokens);
    } catch (e) {
      AppLogger.error(
        'Failed to load handled purchase tokens',
        e is Exception ? e : null,
      );
    }
  }

  Future<void> _saveHandledPurchaseToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _handledPurchaseTokens.add(token);
      await prefs.setStringList(
        _handledTokensKey,
        _handledPurchaseTokens.toList(),
      );
    } catch (e) {
      AppLogger.error(
        'Failed to save handled purchase token',
        e is Exception ? e : null,
      );
    }
  }

  Future<void> _refreshPendingPurchases() async {
    if (!_purchaseListenerReady || _isRefreshingPurchases) {
      return;
    }
    if (!await _inAppPurchase.isAvailable()) {
      return;
    }
    _isRefreshingPurchases = true;
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      AppLogger.error('Failed to restore purchases', e is Exception ? e : null);
    } finally {
      _isRefreshingPurchases = false;
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    if (!mounted || purchases.isEmpty) {
      return;
    }
    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      return;
    }

    for (final purchase in purchases) {
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      final token = purchase.verificationData.serverVerificationData;
      if (token.isEmpty ||
          _handledPurchaseTokens.contains(token) ||
          _processingPurchaseTokens.contains(token)) {
        continue;
      }
      _processingPurchaseTokens.add(token);

      try {
        if (purchase.pendingCompletePurchase) {
          try {
            await _inAppPurchase.completePurchase(purchase);
          } catch (e) {
            AppLogger.error(
              'Failed to complete purchase',
              e is Exception ? e : null,
            );
          }
        }

        final success = await _apiClient.confirmGooglePlaySubscription(
          productId: purchase.productID,
          purchaseToken: token,
        );

        if (success) {
          await _saveHandledPurchaseToken(token);
          await appState.reloadFromStorage();
          if (mounted &&
              !_suppressActivationSnackbar &&
              !_hasShownSubscriptionActivated) {
            _hasShownSubscriptionActivated = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Subscription activated!'),
                backgroundColor: Colors.green[600],
              ),
            );
          }
        }
      } finally {
        _processingPurchaseTokens.remove(token);
      }
    }
  }

  Future<void> _saveNewMatchModePreference(NewMatchMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_newMatchModeKey, mode.name);
  }

  Future<void> _saveKeepItShortPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepItShortKey, value);
  }

  void _setNewMatchMode(NewMatchMode mode) {
    if (_newMatchMode == mode) return;
    setState(() {
      _newMatchMode = mode;
      _suggestions = [];
      _errorMessage = null;
      _isTrialExpired = false;
      _isOpenerLimitExceeded = false;
      _isReplyLimitExceeded = false;
      _isLoading = false;
      _animationController.reset();
      _generateRequestId++;
    });
    _saveNewMatchModePreference(mode);
    if (_situation == 'just_matched' && mode == NewMatchMode.recommended) {
      _loadRecommendedOpeners();
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    HapticFeedback.selectionClick();
    final previousSituation = _situation;
    setState(() {
      _situation = _tabController.index == 0
          ? 'just_matched'
          : 'stuck_after_reply';
      _suggestions = [];
      _errorMessage = null;
      _isLoading = false;
      _animationController.reset();
      _generateRequestId++;
      if (previousSituation == 'just_matched' && _situation != 'just_matched') {
        _uploadedProfileImage = null;
      }
      if (previousSituation != 'just_matched' && _situation == 'just_matched') {
        _uploadedConversationImage = null;
        _isExtractingImage = false;
      }
    });
    if (_situation == 'just_matched' &&
        _newMatchMode == NewMatchMode.recommended) {
      _loadRecommendedOpeners();
    }
  }

  Future<void> _loadRecommendedOpeners() async {
    final requestId = ++_generateRequestId;
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestions = [];
      _isTrialExpired = false;
      _isOpenerLimitExceeded = false;
      _isReplyLimitExceeded = false;
    });

    try {
      final suggestions = await _apiClient.getRecommendedOpeners(count: 3);
      if (!mounted ||
          requestId != _generateRequestId ||
          _situation != 'just_matched' ||
          _newMatchMode != NewMatchMode.recommended) {
        return;
      }
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

  Future<void> _navigateToAuth() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (!mounted) return;
    if (result == true) {
      // Clear trial expired state when user logs in
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trialExpiredKey);

      if (!mounted) return;
      final appState = AppStateScope.of(context);
      await appState.reloadFromStorage();
      if (mounted) {
        setState(() {
          _isTrialExpired = false;
        });
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
            backgroundColor: Colors.green[600],
          ),
        );
      }
    }
  }

  Future<void> _navigateToPricing() async {
    _suppressActivationSnackbar = true;
    final purchased = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PricingScreen()),
    );
    _suppressActivationSnackbar = false;

    if (!mounted) return;
    await AppStateScope.of(context).reloadFromStorage();
    if (!mounted) return;
    if (purchased == true) {
      _hasShownSubscriptionActivated = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscription activated!'),
          backgroundColor: Colors.green[600],
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

  String _getCombinedCustomInstructions() {
    String instructions = _customInstructionsCtrl.text.trim();

    // Add hidden instructions for Need Reply tab
    if (_situation != 'just_matched') {
      const hiddenInstructions =
          "dont use em dashes or dashes. Do not put single quotes around words unless necessary.";

      if (instructions.isEmpty) {
        instructions = hiddenInstructions;
      } else {
        instructions = "$instructions. $hiddenInstructions";
      }

      // Also add "Keep it Short" if toggle is enabled (currently hidden in UI)
      if (_keepItShort) {
        instructions = "$instructions Keep it Short";
      }
    }

    return instructions;
  }

  Future<void> _generateSuggestions() async {
    final appState = AppStateScope.of(context);
    if (_situation != 'just_matched' &&
        appState.isLoggedIn &&
        !appState.isSubscribed &&
        appState.credits == 0) {
      await _navigateToPricing();
      return;
    }
    // For New Match tab, require a profile image
    if (_situation == 'just_matched' &&
        _newMatchMode == NewMatchMode.ai &&
        _uploadedProfileImage == null) {
      _showError('Please upload a profile screenshot first');
      return;
    }

    // For Need Reply tab, require conversation text
    if (_situation != 'just_matched' && _conversationCtrl.text.trim().isEmpty) {
      _showError('Please add your conversation first');
      return;
    }

    await _logDebugState();
    final requestId = ++_generateRequestId;
    final requestSituation = _situation;
    final requestMode = _newMatchMode;
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestions = [];
      _isTrialExpired = false; // reset flag on new attempt
      _isOpenerLimitExceeded = false;
      _isReplyLimitExceeded = false;
    });

    try {
      List<Suggestion> suggestions;

      if (_situation == 'just_matched') {
        if (_newMatchMode == NewMatchMode.recommended) {
          suggestions = await _apiClient.getRecommendedOpeners(count: 3);
        } else {
          // Use the new image-based opener generation endpoint
          suggestions = await _apiClient.generateOpenersFromImage(
            _uploadedProfileImage!,
            customInstructions: _enableNewMatchCustomInstructions
                ? _newMatchCustomInstructionsCtrl.text
                : '',
          );
        }
      } else {
        // Use the regular text-based generation endpoint
        final combinedInstructions = _getCombinedCustomInstructions();
        print('DEBUG: Sending custom instructions: "$combinedInstructions"');
        suggestions = await _apiClient.generate(
          lastText: _conversationCtrl.text,
          situation: _situation,
          herInfo: '',
          tone: _selectedTone,
          customInstructions: combinedInstructions,
        );
      }

      if (!mounted ||
          requestId != _generateRequestId ||
          _situation != requestSituation ||
          (requestSituation == 'just_matched' &&
              _newMatchMode != requestMode)) {
        return;
      }
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
        _isTrialExpired =
            false; // clear any prior trial-expired banner on success
        _isOpenerLimitExceeded = false;
        _isReplyLimitExceeded = false;
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
        e.code == ApiErrorCode.trialExpired ||
        e.code == ApiErrorCode.fairUseExceeded;
  }

  String _getTimeUntilMidnightUtc() {
    final now = DateTime.now().toUtc();
    final midnight = DateTime.utc(now.year, now.month, now.day + 1);
    final difference = midnight.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  void _startNewSession() {
    setState(() {
      _suggestions = [];
      _errorMessage = null;
      _isTrialExpired = false;
      _isOpenerLimitExceeded = false;
      _isReplyLimitExceeded = false;
      _animationController.reset();
      if (_situation == 'just_matched') {
        _uploadedProfileImage = null;
      } else {
        _uploadedConversationImage = null;
        _conversationCtrl.clear();
      }
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(imageFile, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_trialExpiredKey, true);
      if (mounted) {
        setState(() {
          _isTrialExpired = true;
        });
      }
      return;
    }
    if (e.code == ApiErrorCode.fairUseExceeded) {
      if (mounted) {
        setState(() {
          // Set the appropriate limit flag based on current tab
          if (_situation == 'just_matched') {
            _isOpenerLimitExceeded = true;
          } else {
            _isReplyLimitExceeded = true;
          }
        });
      }
      return;
    }
    if (e.code == ApiErrorCode.insufficientCredits) {
      await _refreshSubscriptionStatus();
      if (mounted) {
        setState(() {
          _errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Subscription required. Please subscribe to continue.';
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
      // Clear trial expired state when user signs up
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trialExpiredKey);

      if (!mounted) return;
      final appState = AppStateScope.of(context);
      await appState.reloadFromStorage();
      if (mounted) {
        setState(() {
          _isTrialExpired = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Account created. You have been signed in'),
              ],
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    }
  }

  Future<void> _copySuggestion(String message) async {
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
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );
    await _maybeShowRatingPrompt();
  }

  Future<void> _maybeShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_ratingPromptShownKey) ?? false;
    if (hasShown) {
      return;
    }
    await prefs.setBool(_ratingPromptShownKey, true);
    if (!mounted) return;

    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (e) {
      await review.openStoreListing();
    }
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
    final showCustomInstructions =
        _situation != 'just_matched' ||
        (_enableNewMatchCustomInstructions && _newMatchMode == NewMatchMode.ai);
    final isRecommendedNewMatch =
        _situation == 'just_matched' &&
        _newMatchMode == NewMatchMode.recommended;
    final isAiNewMatch =
        _situation == 'just_matched' && _newMatchMode == NewMatchMode.ai;
    final showGenerateRow = !isAiNewMatch || _uploadedProfileImage != null;

    return Scaffold(
      appBar: _buildAppBar(
        colorScheme,
        isLoggedIn,
        credits,
        isSubscribed,
        username,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning banners
                _buildWarningBanners(
                  colorScheme,
                  isLoggedIn,
                  credits,
                  isSubscribed,
                ),

                const SizedBox(height: 8),

                // Tab bar for situation selection
                _buildTabBar(colorScheme),

                SizedBox(height: sectionSpacing),

                if (_situation == 'just_matched') ...[
                  _buildNewMatchToggle(colorScheme),
                  SizedBox(height: sectionSpacing),
                  if (isRecommendedNewMatch) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'These openers were hand-picked by dating coaches around the world',
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                ],

                // Input section
                _buildInputSection(colorScheme),

                SizedBox(height: sectionSpacing),

                // Custom instructions section
                if (showCustomInstructions) ...[
                  _buildCustomInstructionsSection(colorScheme),
                  SizedBox(height: sectionSpacing),
                ],

                if (isRecommendedNewMatch) ...[
                  if (!_isLoading && !_isExtractingImage) ...[
                    _buildGenerateRow(colorScheme),
                    SizedBox(height: sectionSpacing),
                  ],
                  _buildResultsSection(colorScheme),
                ] else ...[
                  if (showGenerateRow) ...[
                    _buildGenerateRow(colorScheme),
                    SizedBox(height: sectionSpacing),
                  ],
                  _buildResultsSection(colorScheme),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
          // Bottom gradient indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showBottomGradient ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface.withValues(alpha: 0.0),
                        colorScheme.surface.withValues(alpha: 0.9),
                        colorScheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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
        if (!isLoggedIn) ...[
          // "Go Pro" button for guest users
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PricingScreen(
                    showCloseButton: true,
                    guestConversionMode: true,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Go Pro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
    // Fair use exceeded banner for subscribers
    if (isSubscribed) {
      final isOpenerTab = _situation == 'just_matched';
      final isLimitExceeded = isOpenerTab
          ? _isOpenerLimitExceeded
          : _isReplyLimitExceeded;

      if (isLimitExceeded) {
        final limitType = isOpenerTab ? 'opener' : 'reply';
        final resetTime = _getTimeUntilMidnightUtc();
        final subtitle = isOpenerTab
            ? 'Resets in $resetTime\n\nPlease use Recommended openers. They have been carefully selected by dating coaches around the world'
            : 'Resets in $resetTime';
        return Column(
          children: [
            _buildBanner(
              colorScheme: colorScheme,
              icon: Icons.hourglass_empty_outlined,
              title: 'Daily $limitType limit reached',
              subtitle: subtitle,
              type: BannerType.warning,
            ),
          ],
        );
      }
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: foregroundColor),
          ),
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
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Minimum velocity threshold to detect intentional swipe (500px/s)
        const double minVelocity = 500.0;
        final velocity = details.primaryVelocity ?? 0;

        // Ignore slow drags
        if (velocity.abs() < minVelocity) return;

        // Prevent switching during tab animation
        if (_tabController.indexIsChanging) return;

        // Swipe right: go to previous tab (New Match)
        if (velocity > 0 && _tabController.index == 1) {
          HapticFeedback.selectionClick();
          _tabController.animateTo(0);
        }
        // Swipe left: go to next tab (Need Reply)
        else if (velocity < 0 && _tabController.index == 0) {
          HapticFeedback.selectionClick();
          _tabController.animateTo(1);
        }
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme) {
    if (_situation == 'just_matched') {
      if (_newMatchMode == NewMatchMode.recommended) {
        return const SizedBox.shrink();
      }
      return _buildProfileInputSection(colorScheme);
    } else {
      return _buildConversationInputSection(colorScheme);
    }
  }

  Widget _buildCustomInstructionsSection(ColorScheme colorScheme) {
    final controller = _situation == 'just_matched'
        ? _newMatchCustomInstructionsCtrl
        : _customInstructionsCtrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
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
              const SizedBox(width: 6),
              Text(
                '(optional)',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 2,
          minLines: 2,
          maxLength: 250,
          buildCounter:
              (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) {
                return null;
              },
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
          onChanged: (_) => setState(() {}),
        ),
        if (_situation != 'just_matched') _buildKeepItShortToggle(colorScheme),
      ],
    );
  }

  Widget _buildKeepItShortToggle(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.short_text,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Keep it short',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch(
            value: _keepItShort,
            onChanged: (value) {
              setState(() {
                _keepItShort = value;
              });
              _saveKeepItShortPreference(value);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildNewMatchToggle(ColorScheme colorScheme) {
    return SegmentedButton<NewMatchMode>(
      segments: const [
        ButtonSegment(value: NewMatchMode.ai, label: Text('Creative')),
        ButtonSegment(
          value: NewMatchMode.recommended,
          label: Text('Recommended'),
        ),
      ],
      selected: <NewMatchMode>{_newMatchMode},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        _setNewMatchMode(selection.first);
      },
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
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
            const SizedBox(height: 4),
            Text(
              'Pick the most interesting photo or bio section',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 12,
              ),
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
                      child: GestureDetector(
                        onTap: () => _showImagePreview(_uploadedProfileImage!),
                        child: Image.file(
                          _uploadedProfileImage!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
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
                          _errorMessage = null;
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
                      child: GestureDetector(
                        onTap: () =>
                            _showImagePreview(_uploadedConversationImage!),
                        child: Image.file(
                          _uploadedConversationImage!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ThinkingIndicatorCompact(
                        messages: extractionMessages,
                        color: colorScheme.onSurfaceVariant,
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
                      child: GestureDetector(
                        onTap: () =>
                            _showImagePreview(_uploadedConversationImage!),
                        child: Image.file(
                          _uploadedConversationImage!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
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
    final isRecommended =
        _situation == 'just_matched' &&
        _newMatchMode == NewMatchMode.recommended;
    final label = (isRecommended || _suggestions.isNotEmpty)
        ? 'Regenerate'
        : (_situation == 'just_matched'
              ? 'Get Smart Openers'
              : 'Get Smart Replies');
    return FilledButton(
      onPressed: (_isLoading || _isExtractingImage)
          ? null
          : _generateSuggestions,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: _primaryButtonTextStyle,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 22),
          const SizedBox(width: 12),
          Text(label, style: _primaryButtonTextStyle),
        ],
      ),
    );
  }

  Widget _buildGenerateRow(ColorScheme colorScheme) {
    final showNewButton =
        _suggestions.isNotEmpty && !_isLoading && !_isExtractingImage;
    final isRecommendedNewMatch =
        _situation == 'just_matched' &&
        _newMatchMode == NewMatchMode.recommended;
    final canShowNew = showNewButton && !isRecommendedNewMatch;
    return Row(
      children: [
        Expanded(child: _buildGenerateButton(colorScheme)),
        if (canShowNew) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _startNewSession,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsSection(ColorScheme colorScheme) {
    final isRecommendedNewMatch =
        _situation == 'just_matched' &&
        _newMatchMode == NewMatchMode.recommended;
    final isAiNewMatch =
        _situation == 'just_matched' && _newMatchMode == NewMatchMode.ai;
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
                AnimatedLoadingText(
                  messages: isRecommendedNewMatch
                      ? recommendedMessages
                      : (isAiNewMatch ? openerMessages : replyMessages),
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                  color: _smartReplyAccentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: _smartReplyAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_suggestions.length} ${_situation == 'just_matched' ? 'Smart Openers' : 'Smart Replies'}',
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _purchaseSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _conversationCtrl.dispose();
    _customInstructionsCtrl.dispose();
    _newMatchCustomInstructionsCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

enum BannerType { error, warning, info }

enum NewMatchMode { recommended, ai }

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
      elevation: 4,
      shadowColor: _smartReplyCardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
                      color: _smartReplyAccentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: _smartReplyAccent,
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
              if ((suggestion.whyItWorks ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          suggestion.whyItWorks!.trim(),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
