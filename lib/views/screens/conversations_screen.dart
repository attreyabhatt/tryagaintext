import 'dart:ui';
import 'package:flutter/cupertino.dart';
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
import '../../services/review_prompt_service.dart';
import '../../models/suggestion.dart';
import '../../utils/app_logger.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'package:flirtfix/views/screens/pricing_screen.dart';
import 'package:flirtfix/views/screens/profile_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/gradient_icon.dart';
import '../widgets/thinking_indicator.dart';

const _smartReplyCardShadow = Color(0x0D000000); // Black at 5% opacity

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
  static const String _newMatchModeKey = 'new_match_mode';
  static const String _handledTokensKey = 'handled_purchase_tokens';
  static const String _keepItShortKey = 'keep_it_short_need_reply';
  static const List<String> _toneOptions = <String>[
    'Default',
    'Flirty',
    'Witty',
    'Romantic',
    'Cocky Funny',
  ];
  static const List<String> _characterOptions = <String>[
    'None',
    'Tommy Shelby',
    'Sherlock Holmes',
    'Logan Roy',
    'Lawyer',
    'Doctor',
  ];
  static const String _defaultTone = 'Default';
  static const String _defaultCharacter = 'None';
  String _situation = 'stuck_after_reply';
  String _selectedTone = _defaultTone;
  String _selectedCharacter = _defaultCharacter;
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

  bool _isOpenerLimitExceeded = false;
  bool _isReplyLimitExceeded = false;
  final _apiClient = ApiClient();
  final ReviewPromptService _reviewPromptService = ReviewPromptService();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  File? _uploadedConversationImage;
  File? _uploadedProfileImage;
  NewMatchMode _newMatchMode = NewMatchMode.ai;
  int _generateRequestId = 0;
  int _conversationExtractionRequestId = 0;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _purchaseListenerReady = false;
  bool _isRefreshingPurchases = false;
  bool _suppressActivationSnackbar = false;
  bool _hasShownSubscriptionActivated = false;
  bool _isShowingReviewPrompt = false;
  final Set<String> _handledPurchaseTokens = {};
  final Set<String> _processingPurchaseTokens = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
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
        HapticFeedback.heavyImpact();
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
      final appState = AppStateScope.of(context);
      await appState.reloadFromStorage();
      if (mounted) {
        final justSignedUp = await AuthService.consumeJustSignedUp();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outlined,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  justSignedUp
                      ? 'Account created. You have been signed in'
                      : 'Welcome back!',
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
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
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
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

  String _composeInstructions({
    required String baseInstructions,
    required bool includeCommandSettings,
  }) {
    const hiddenInstructions =
        "dont use em dashes or dashes. Do not put single quotes around words unless necessary.";
    final parts = <String>[
      if (baseInstructions.trim().isNotEmpty) baseInstructions.trim(),
      if (includeCommandSettings && !_isDefaultCharacterSelection)
        'Write with a $_selectedCharacter persona.',
      if (includeCommandSettings && !_isDefaultToneSelection)
        'Use a ${_selectedTone.toLowerCase()} tone.',
      if (includeCommandSettings && _keepItShort) 'Keep it short.',
      hiddenInstructions,
    ];
    return parts.join(' ');
  }

  bool get _isDefaultToneSelection {
    final normalized = _selectedTone.trim().toLowerCase();
    return normalized == _defaultTone.toLowerCase() || normalized == 'natural';
  }

  bool get _isDefaultCharacterSelection {
    final normalized = _selectedCharacter.trim().toLowerCase();
    return normalized == _defaultCharacter.toLowerCase() ||
        normalized == 'standard';
  }

  String _toneForBackend() {
    if (_isDefaultToneSelection) {
      return 'Natural';
    }
    return _selectedTone;
  }

  String _getCombinedCustomInstructions() {
    return _composeInstructions(
      baseInstructions: _customInstructionsCtrl.text,
      includeCommandSettings: true,
    );
  }

  String _getCombinedCustomInstructionsForOpeners() {
    final openersCustomInstructions = _enableNewMatchCustomInstructions
        ? _newMatchCustomInstructionsCtrl.text
        : '';
    return _composeInstructions(
      baseInstructions: openersCustomInstructions,
      includeCommandSettings: _enableNewMatchCustomInstructions,
    );
  }

  Future<void> _generateSuggestions() async {
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
    final requestStartedAt = DateTime.now();
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestions = [];
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
          final combinedInstructionsForOpeners =
              _getCombinedCustomInstructionsForOpeners();
          suggestions = await _apiClient.generateOpenersFromImage(
            _uploadedProfileImage!,
            customInstructions: combinedInstructionsForOpeners,
          );
        }
      } else {
        // Use the regular text-based generation endpoint
        final combinedInstructions = _getCombinedCustomInstructions();
        suggestions = await _apiClient.generate(
          lastText: _conversationCtrl.text,
          situation: _situation,
          herInfo: '',
          tone: _toneForBackend(),
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
        _isOpenerLimitExceeded = false;
        _isReplyLimitExceeded = false;
      });

      final appState = AppStateScope.of(context);
      await appState.reloadFromStorage();
      await _recordZeroCreditsDayIfNeeded();
      if (!mounted) return;

      if (suggestions.isNotEmpty) {
        HapticFeedback.heavyImpact();
        _animationController.forward();
        if (requestSituation != 'just_matched') {
          await _handleNeedReplySuccessReviewSignal();
        }
      }
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.trialExpired) {
        await _handleCreditError(
          e,
          requestStartedAt: requestStartedAt,
          requestId: requestId,
          requestSituation: requestSituation,
          requestMode: requestMode,
        );
        return;
      }
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
    HapticFeedback.selectionClick();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;
      final extractionRequestId = ++_conversationExtractionRequestId;

      setState(() {
        _isExtractingImage = true;
        _uploadedConversationImage = File(image.path);
      });

      final extractedText = await _apiClient.extractFromImage(File(image.path));

      if (!mounted ||
          extractionRequestId != _conversationExtractionRequestId ||
          _uploadedConversationImage == null) {
        return;
      }
      setState(() {
        _conversationCtrl.text = extractedText;
        _isExtractingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!_isExtractingImage) {
        return;
      }
      setState(() {
        _isExtractingImage = false;
        _uploadedConversationImage = null;
      });
      _showError('Failed to extract text from image. Please try again.');
    }
  }

  void _cancelConversationImageUpload() {
    HapticFeedback.selectionClick();
    setState(() {
      _conversationExtractionRequestId++;
      _isExtractingImage = false;
      _uploadedConversationImage = null;
      _conversationCtrl.clear();
      _suggestions = [];
      _errorMessage = null;
      _animationController.reset();
    });
  }

  Future<void> _uploadProfileImage() async {
    HapticFeedback.selectionClick();
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
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }

  bool _isCreditError(ApiException e) {
    return e.code == ApiErrorCode.insufficientCredits ||
        e.code == ApiErrorCode.trialExpired ||
        e.code == ApiErrorCode.fairUseExceeded ||
        e.code == ApiErrorCode.hasPendingUnlock;
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
    HapticFeedback.selectionClick();
    setState(() {
      _suggestions = [];
      _errorMessage = null;
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
        final screenSize = MediaQuery.of(context).size;
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: SizedBox(
                  width: screenSize.width * 0.5,
                  height: screenSize.height * 0.5,
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(imageFile, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _logDebugState() async {
    final token = await AuthService.getToken();
    if (!mounted) return;
    final appState = AppStateScope.of(context);
    AppLogger.debug(
      'Generate tapped | isLoggedIn=${appState.isLoggedIn} | isSubscribed=${appState.isSubscribed} '
      '| tokenPresent=${token != null && token.isNotEmpty} '
      '| baseUrl=${_apiClient.baseUrl}',
    );
  }

  bool _isCurrentGenerateRequest({
    required int requestId,
    required String requestSituation,
    required NewMatchMode requestMode,
  }) {
    return mounted &&
        requestId == _generateRequestId &&
        _situation == requestSituation &&
        (requestSituation != 'just_matched' || _newMatchMode == requestMode);
  }

  Future<void> _handleCreditError(
    ApiException e, {
    DateTime? requestStartedAt,
    int? requestId,
    String? requestSituation,
    NewMatchMode? requestMode,
  }) async {
    if (e.code == ApiErrorCode.hasPendingUnlock) {
      final previews = e.lockedPreview ?? const <String>[];
      if (mounted) {
        setState(() {
          _errorMessage = previews.isEmpty ? e.message : null;
          if (previews.isNotEmpty) {
            _suggestions = List.generate(
              previews.length,
              (index) => Suggestion(
                message: previews[index],
                confidence: 0.8,
                isLocked: true,
                blurPreview: previews[index],
                lockedReplyId: e.lockedReplyId,
              ),
            );
          }
        });
        if (previews.isNotEmpty) {
          _animationController.reset();
          _animationController.forward();
        }
      }
      return;
    }
    if (e.code == ApiErrorCode.trialExpired) {
      if (!mounted) return;
      final appState = AppStateScope.of(context);
      if (appState.isLoggedIn) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message.isNotEmpty
              ? e.message
              : 'Please create your free account to continue.';
        });
        return;
      }

      if (requestStartedAt != null) {
        const minimumLoading = Duration(milliseconds: 1500);
        final elapsed = DateTime.now().difference(requestStartedAt);
        final remaining = minimumLoading - elapsed;
        if (remaining > Duration.zero) {
          await Future.delayed(remaining);
        }
      }

      if (!mounted) return;
      if (requestId != null &&
          requestSituation != null &&
          requestMode != null &&
          !_isCurrentGenerateRequest(
            requestId: requestId,
            requestSituation: requestSituation,
            requestMode: requestMode,
          )) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
      _showGuestAccessCompleteSheet();
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
      if (mounted) {
        await AppStateScope.of(context).reloadFromStorage();
      }
      await _recordZeroCreditsDayIfNeeded();
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
      await _recordZeroCreditsDayIfNeeded();
    }
  }

  void _showLuxuryAccessSheet({
    required String headline,
    required String body,
    required String supportText,
    required String primaryLabel,
    required Future<void> Function() onPrimary,
    String? secondaryLabel,
    Future<void> Function()? onSecondary,
    Color? secondaryForegroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final gradientEnd =
        Color.lerp(colorScheme.primary, colorScheme.tertiary, 0.55) ??
        colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      isScrollControlled: true,
      builder: (ctx) {
        final bottomSafe = MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomSafe),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: isDark ? 0.62 : 0.72),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colorScheme.secondary.withValues(alpha: 0.42),
                            colorScheme.secondary.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.secondary.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.8,
                              ),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 28,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      headline,
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      body,
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      supportText,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: colorScheme.secondary.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.38,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await onPrimary();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            foregroundColor: colorScheme.onPrimary,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(primaryLabel),
                        ),
                      ),
                    ),
                    if (secondaryLabel != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (onSecondary != null) {
                            await onSecondary();
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              secondaryForegroundColor ??
                              colorScheme.secondary.withValues(alpha: 0.9),
                          textStyle: Theme.of(ctx).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        child: Text(secondaryLabel),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGuestAccessCompleteSheet() {
    _showLuxuryAccessSheet(
      headline: 'Join the Inner Circle.',
      body:
          'Create your free account to reveal this response and continue with FlirtFix.',
      supportText: 'Takes less than 30 seconds.',
      primaryLabel: 'Continue',
      onPrimary: _navigateToSignup,
      secondaryLabel: 'Login to existing account',
      onSecondary: _navigateToAuth,
    );
  }

  Future<void> _navigateToPricingAndUnlockLockedReply(
    int? lockedReplyId,
  ) async {
    await _navigateToPricing();
    if (!mounted) return;
    final appState = AppStateScope.of(context);
    await appState.reloadFromStorage();
    if (appState.isSubscribed && lockedReplyId != null) {
      try {
        final unlocked = await _apiClient.unlockReply(lockedReplyId);
        if (mounted) {
          setState(() {
            _suggestions = unlocked;
          });
          _animationController.reset();
          _animationController.forward();
        }
      } catch (e) {
        AppLogger.error('Unlock reply failed', e is Exception ? e : null);
      }
    }
  }

  void _showUpgradePopup(int? lockedReplyId) {
    final appState = AppStateScope.of(context);
    final freeDailyLimit = appState.freeDailyCreditsLimit;
    final limitLabel = freeDailyLimit != null
        ? '$freeDailyLimit/$freeDailyLimit'
        : '3/3';
    final resetTime = _getTimeUntilMidnightUtc();

    _showLuxuryAccessSheet(
      headline: 'Unlock this reply.',
      body:
          'Your daily limit of $limitLabel reached. Resets in $resetTime. Continue to Premium to reveal the full response.',
      supportText: 'Instant unlock after checkout.',
      primaryLabel: 'Continue',
      onPrimary: () => _navigateToPricingAndUnlockLockedReply(lockedReplyId),
      secondaryLabel: 'Maybe later',
      secondaryForegroundColor: Colors.white.withValues(alpha: 0.7),
    );
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
                Icon(
                  Icons.check_circle_outlined,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                const Text('Account created. You have been signed in'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
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
        content: Row(
          children: [
            Icon(
              Icons.check_outlined,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Copied to clipboard!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        duration: const Duration(seconds: 2),
      ),
    );
    await _handleCopyReviewSignal();
  }

  bool get _supportsAndroidReviewFlow =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _handleCopyReviewSignal() async {
    if (!_supportsAndroidReviewFlow || !mounted) {
      return;
    }
    final decision = await _reviewPromptService.recordCopyAndGetDecision();
    await _maybeShowPulseCheck(decision);
  }

  Future<void> _maybeShowPulseCheck(ReviewPromptDecision decision) async {
    if (!mounted || !decision.shouldShow || _isShowingReviewPrompt) {
      return;
    }

    _isShowingReviewPrompt = true;
    try {
      await _showPulseCheck(decision);
    } finally {
      _isShowingReviewPrompt = false;
    }
  }

  Future<void> _showPulseCheck(ReviewPromptDecision decision) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final action = await showModalBottomSheet<_PulseCheckAction>(
      context: context,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.secondary, size: 28),
                const SizedBox(height: 14),
                Text(
                  decision.headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  decision.subtext,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final useVerticalButtons =
                        constraints.maxWidth < 360 || textScale > 1.05;

                    final negativeButton = OutlinedButton(
                      onPressed: () async {
                        Navigator.of(
                          sheetContext,
                        ).pop(_PulseCheckAction.negative);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        side: BorderSide(color: colorScheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Needs Calibration',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    );

                    final positiveButton = DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFFFF2D6D), const Color(0xFFB95A7B)]
                              : [const Color(0xFF991B38), const Color(0xFFC22E53)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(
                            sheetContext,
                          ).pop(_PulseCheckAction.positive);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          decision.positiveLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );

                    if (useVerticalButtons) {
                      return Column(
                        children: [
                          SizedBox(width: double.infinity, child: negativeButton),
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: positiveButton),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: negativeButton),
                        const SizedBox(width: 12),
                        Expanded(child: positiveButton),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == _PulseCheckAction.negative) {
      try {
        final messenger = ScaffoldMessenger.of(context);
        final secondaryContainer =
            Theme.of(context).colorScheme.secondaryContainer;
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (!mounted) return;
        final submitted = await _showFeedbackForm(decision);
        if (!submitted) {
          return;
        }
        await _reviewPromptService.markNegativeFeedbackSubmitted();
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Feedback received. We are calibrating.',
            ),
            backgroundColor: secondaryContainer,
          ),
        );
      } catch (_) {
        // Ignore transient UI/state errors in feedback branch.
      }
    } else if (action == _PulseCheckAction.positive) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await _handlePositiveReviewPath();
    }
  }

  Future<void> _handlePositiveReviewPath() async {
    if (!_supportsAndroidReviewFlow) {
      return;
    }
    final review = InAppReview.instance;
    try {
      final isAvailable = await review.isAvailable();
      if (!isAvailable) {
        return;
      }
      await review.requestReview();
      await _reviewPromptService.markGoogleReviewLaunched();
    } catch (_) {
      // Swallow errors; caller should remain uninterrupted.
    }
  }

  Future<bool> _showFeedbackForm(ReviewPromptDecision decision) async {
    final appState = AppStateScope.of(context);
    final emailController = TextEditingController(
      text: appState.user?.email ?? '',
    );
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? errorMessage;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomInset),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refine Strategy',
                          style: Theme.of(sheetContext).textTheme.headlineSmall
                              ?.copyWith(color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tell us what went wrong. Your feedback calibrates the model.',
                          style: Theme.of(sheetContext).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: messageController,
                          minLines: 5,
                          maxLines: 7,
                          decoration: InputDecoration(
                            hintText: 'The reply was too aggressive...',
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please share what went wrong.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'you@example.com',
                            labelText: 'Email',
                          ),
                          validator: (value) {
                            final email = (value ?? '').trim();
                            if (email.isEmpty) {
                              return 'Please enter your email.';
                            }
                            if (!_isValidEmail(email)) {
                              return 'Please enter a valid email.';
                            }
                            return null;
                          },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorMessage!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    try {
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      setSheetState(() {
                                        isSubmitting = true;
                                        errorMessage = null;
                                      });

                                      final ok = await _apiClient.reportIssue(
                                        reason: 'feedback',
                                        title:
                                            'Pulse Feedback - ${_reviewReasonTag(decision.reason)}',
                                        subject: messageController.text.trim(),
                                        email: emailController.text.trim(),
                                      );

                                      if (!sheetContext.mounted) {
                                        return;
                                      }
                                      if (ok) {
                                        final navigator = Navigator.of(
                                          sheetContext,
                                        );
                                        if (navigator.canPop()) {
                                          navigator.pop(true);
                                        }
                                        return;
                                      }
                                      setSheetState(() {
                                        isSubmitting = false;
                                        errorMessage =
                                            'Could not send feedback. Please try again.';
                                      });
                                    } catch (_) {
                                      if (!sheetContext.mounted) {
                                        return;
                                      }
                                      setSheetState(() {
                                        isSubmitting = false;
                                        errorMessage =
                                            'Could not send feedback. Please try again.';
                                      });
                                    }
                                  },
                            child: isSubmitting
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.secondary,
                                    ),
                                  )
                                : Text(
                                    'Transmit Feedback',
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    return submitted ?? false;
  }

  String _reviewReasonTag(ReviewTriggerReason? reason) {
    switch (reason) {
      case ReviewTriggerReason.milestone3:
        return 'milestone_3';
      case ReviewTriggerReason.milestone50:
        return 'milestone_50';
      case ReviewTriggerReason.comeback:
        return 'comeback';
      case null:
        return 'unknown';
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }

  Future<void> _recordZeroCreditsDayIfNeeded() async {
    if (!_supportsAndroidReviewFlow || !mounted) {
      return;
    }
    final appState = AppStateScope.of(context);
    await _reviewPromptService.recordZeroCreditsDayIfNeeded(
      isSubscribed: appState.isSubscribed,
      freeDailyCreditsRemaining: appState.freeDailyCreditsRemaining,
    );
  }

  Future<void> _handleNeedReplySuccessReviewSignal() async {
    if (!_supportsAndroidReviewFlow || !mounted) {
      return;
    }
    final appState = AppStateScope.of(context);
    final decision = await _reviewPromptService.recordNeedReplySuccessAndGetDecision(
      isSubscribed: appState.isSubscribed,
    );
    await _maybeShowPulseCheck(decision);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = AppStateScope.of(context);
    final isLoggedIn = appState.isLoggedIn;
    final dailyCreditsRemaining = appState.freeDailyCreditsRemaining;
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
    final shouldShowGenerateRow = isRecommendedNewMatch
        ? !_isLoading && !_isExtractingImage
        : showGenerateRow;

    return Scaffold(
      appBar: _buildAppBar(
        colorScheme,
        isLoggedIn,
        dailyCreditsRemaining,
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
                  _buildWarningBanners(colorScheme, isSubscribed),

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
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 18,
                              color: colorScheme.brightness == Brightness.light
                                  ? const Color(
                                      0xFF991B38,
                                    ) // Merlot for light mode
                                  : colorScheme
                                        .onSecondaryContainer, // Original color for dark mode
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Expertly formulated to maximize engagement and intrigue.',
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

                  if (shouldShowGenerateRow) ...[
                    _buildGenerateRow(colorScheme),
                    SizedBox(height: sectionSpacing),
                  ],
                  _buildResultsSection(colorScheme),

                  const SizedBox(height: 40),
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
    int? dailyCreditsRemaining,
    bool isSubscribed,
    String username,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 16),
          Image.asset(
            'assets/images/icons/appstore_transparent.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FlirtFix',
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Your Conversation Architect',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (!isLoggedIn) ...[
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.crown,
              color: colorScheme.secondary,
              size: 20,
            ),
            onPressed: () {
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
          ),
          const SizedBox(width: 8),
        ],
        if (isLoggedIn && !isSubscribed && dailyCreditsRemaining != null) ...[
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
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_outlined,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$dailyCreditsRemaining',
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
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
              color: Colors.transparent,
            ),
            child: Icon(
              isLoggedIn ? Icons.person_outline_outlined : Icons.person_outline,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWarningBanners(ColorScheme colorScheme, bool isSubscribed) {
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
            ? 'Resets in $resetTime\n\nPlease use Recommended openers. Expertly formulated to maximize engagement and intrigue.'
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

    return const SizedBox.shrink();
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
        borderRadius: BorderRadius.circular(12),
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
    final isDark = colorScheme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? colorScheme.surfaceContainerHigh
        : const Color(0xFFE5E5EA);
    final borderColor = isDark
        ? colorScheme.outlineVariant
        : const Color(0xFFE5E5EA);
    final activeGradient = LinearGradient(
      colors: isDark
          ? [colorScheme.primary, colorScheme.tertiary]
          : [const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final glowColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.35)
        : const Color(0xFF9E9E9E).withValues(alpha: 0.25);
    final activeShadow = isDark
        ? [
            BoxShadow(
              color: glowColor,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
        : [
            BoxShadow(
              color: glowColor,
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ];

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
      child: AnimatedBuilder(
        animation: _tabController.animation ?? _tabController,
        builder: (context, child) {
          final animationValue =
              _tabController.animation?.value ??
              _tabController.index.toDouble();
          final t = animationValue.clamp(0.0, 1.0).toDouble();
          final isNeedReplySelected = t >= 0.5;

          return Container(
            height: 54,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pillWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    Align(
                      alignment: Alignment.lerp(
                        Alignment.centerLeft,
                        Alignment.centerRight,
                        t,
                      )!,
                      child: Container(
                        width: pillWidth,
                        decoration: BoxDecoration(
                          gradient: activeGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: activeShadow,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildTabPillItem(
                          icon: Icons.favorite_outline,
                          label: 'Open',
                          isActive: !isNeedReplySelected,
                          onTap: () => _handleTabTap(0),
                          colorScheme: colorScheme,
                        ),
                        _buildTabPillItem(
                          icon: Icons.chat_bubble_outline,
                          label: 'Respond',
                          isActive: isNeedReplySelected,
                          onTap: () => _handleTabTap(1),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleTabTap(int index) {
    if (_tabController.index == index) return;
    HapticFeedback.selectionClick();
    _tabController.animateTo(index);
  }

  Widget _buildTabPillItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final activeColor = isDark ? colorScheme.onPrimary : colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? activeColor : inactiveColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? activeColor : inactiveColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
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

  TextEditingController _activeInstructionsController() {
    return _situation == 'just_matched'
        ? _newMatchCustomInstructionsCtrl
        : _customInstructionsCtrl;
  }

  String _buildCommandHintText() {
    final activeSettings = <String>[
      if (!_isDefaultCharacterSelection) _selectedCharacter,
      if (!_isDefaultToneSelection) _selectedTone,
      if (_keepItShort) 'Short',
    ];
    if (activeSettings.isEmpty) {
      return 'Any specific instructions?';
    }
    return '(${activeSettings.join(' | ')}) Add details...';
  }

  Future<void> _setKeepItShort(bool value) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _keepItShort = value;
    });
    await _saveKeepItShortPreference(value);
  }

  Future<void> _showTonePicker(ColorScheme colorScheme) async {
    final selectedTone = await _showCommandOptionSheet(
      colorScheme: colorScheme,
      title: 'Select Tone',
      helperText: 'Select a style or type your own above.',
      options: _toneOptions,
      selectedValue: _selectedTone,
    );
    if (selectedTone == null || selectedTone == _selectedTone) {
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedTone = selectedTone;
    });
  }

  Future<void> _showCharacterPicker(ColorScheme colorScheme) async {
    final selectedCharacter = await _showCommandOptionSheet(
      colorScheme: colorScheme,
      title: 'Select Character',
      helperText: 'Select a persona or type your own above.',
      options: _characterOptions,
      selectedValue: _selectedCharacter,
    );
    if (selectedCharacter == null || selectedCharacter == _selectedCharacter) {
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedCharacter = selectedCharacter;
    });
  }

  Future<String?> _showCommandOptionSheet({
    required ColorScheme colorScheme,
    required String title,
    String? helperText,
    required List<String> options,
    required String selectedValue,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final selectedChipBackground = isDark
        ? colorScheme.secondary.withValues(alpha: 0.16)
        : colorScheme.secondary.withValues(alpha: 0.14);
    final selectedChipBorder = isDark
        ? colorScheme.secondary.withValues(alpha: 0.92)
        : colorScheme.secondary.withValues(alpha: 0.86);
    final unselectedChipBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : colorScheme.outlineVariant.withValues(alpha: 0.62);
    final chipBackground = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : colorScheme.surface.withValues(alpha: 0.86);
    final sheetBackgroundColor = isDark
        ? Colors.black.withValues(alpha: 0.62)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.94);
    final sheetBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : colorScheme.outlineVariant.withValues(alpha: 0.52);
    final titleColor = isDark ? Colors.white : colorScheme.onSurface;
    final helperColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : colorScheme.onSurfaceVariant;
    final chipLabelColor = isDark
        ? Colors.white.withValues(alpha: 0.96)
        : colorScheme.onSurface;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomSafe = MediaQuery.of(sheetContext).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomSafe),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBackgroundColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: sheetBorderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                      blurRadius: isDark ? 26 : 20,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (helperText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            helperText,
                            style: TextStyle(
                              color: helperColor,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.map((option) {
                            final isSelected = selectedValue == option;
                            return ChoiceChip(
                              label: Text(option),
                              selected: isSelected,
                              onSelected: (_) =>
                                  Navigator.of(sheetContext).pop(option),
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: chipLabelColor,
                              ),
                              backgroundColor: chipBackground,
                              selectedColor: selectedChipBackground,
                              side: BorderSide(
                                color: isSelected
                                    ? selectedChipBorder
                                    : unselectedChipBorder,
                                width: isSelected ? 1.2 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommandIconButton({
    required ColorScheme colorScheme,
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final iconColor = isActive
        ? colorScheme.secondary
        : colorScheme.onSurfaceVariant;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 20, color: iconColor),
            tooltip: tooltip,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          if (isActive)
            Positioned(
              bottom: 2,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

  }

  Widget _buildCustomInstructionsSection(ColorScheme colorScheme) {
    final controller = _activeInstructionsController();
    final isDark = colorScheme.brightness == Brightness.dark;
    final containerColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerHighest;
    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.9)
        : colorScheme.outlineVariant.withValues(alpha: 0.95);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: containerColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.surfaceContainer,
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
                ]
              : [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainer.withValues(alpha: 0.75),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: isDark ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 2,
            maxLength: 250,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: _buildCommandHintText(),
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
              filled: false,
              isDense: true,
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 8,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.7),
          ),
          Row(
            children: [
              _buildCommandIconButton(
                colorScheme: colorScheme,
                icon: Icons.theater_comedy_outlined,
                isActive: !_isDefaultCharacterSelection,
                onPressed: () {
                  _showCharacterPicker(colorScheme);
                },
                tooltip: 'Character',
              ),
              _buildCommandIconButton(
                colorScheme: colorScheme,
                icon: Icons.tune_outlined,
                isActive: !_isDefaultToneSelection,
                onPressed: () {
                  _showTonePicker(colorScheme);
                },
                tooltip: 'Tone',
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Keep it short',
                    style: TextStyle(
                      color: _keepItShort
                          ? colorScheme.secondary
                          : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.82,
                    child: Switch(
                      value: _keepItShort,
                      onChanged: _setKeepItShort,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
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
        HapticFeedback.selectionClick();
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
              OutlinedButton(
                onPressed: _uploadProfileImage,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(color: colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Analyze Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Image preview (show when image is uploaded)
            if (_uploadedProfileImage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
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
                                Icons.check_circle_outlined,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Uploaded',
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
                            'Tap "Craft Opening" to generate personalized first messages',
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
                        Icons.close_outlined,
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
    final hasConversationPreview =
        (_isExtractingImage && _uploadedConversationImage != null) ||
        (_uploadedConversationImage != null &&
            _conversationCtrl.text.isNotEmpty);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
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

            // Upload button (only show if no image uploaded)
            if (_uploadedConversationImage == null)
              OutlinedButton(
                onPressed: _isExtractingImage ? null : _uploadScreenshot,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(color: colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_camera_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Analyze Chat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            if (hasConversationPreview) const SizedBox(height: 16),

            // Image preview - horizontal row layout
            if (_isExtractingImage && _uploadedConversationImage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
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
                    IconButton(
                      onPressed: _cancelConversationImageUpload,
                      icon: Icon(
                        Icons.close_outlined,
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
              const SizedBox(height: 16),
            ] else if (_uploadedConversationImage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
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
                                Icons.check_circle_outlined,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Uploaded',
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
                            _conversationCtrl.text.isEmpty
                                ? 'Tap "Craft Response" to generate suggestions'
                                : (_conversationCtrl.text.length > 80
                                      ? '${_conversationCtrl.text.substring(0, 80)}...'
                                      : _conversationCtrl.text),
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
                        Icons.close_outlined,
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

  Widget _buildPrimaryGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
    double height = 50,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = colorScheme.brightness == Brightness.light;
    final borderRadius = BorderRadius.circular(14);

    // Light mode: Merlot gradient (matching Access button)
    // Dark mode: Standard theme gradient
    final List<Color> gradientColors;
    final Color shadowColor;

    if (isLight) {
      gradientColors = [
        const Color(0xFF991B38), // Merlot
        const Color(0xFFC22E53), // Lighter Merlot
      ];
      shadowColor = gradientColors.first.withValues(alpha: 0.3);
    } else {
      final blended =
          Color.lerp(colorScheme.primary, colorScheme.secondary, 0.35) ??
          colorScheme.primary;
      gradientColors = [colorScheme.primary, blended];
      shadowColor = colorScheme.primary.withValues(alpha: 0.35);
    }

    final button = SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: colorScheme.onPrimary,
            disabledForegroundColor: colorScheme.onPrimary.withValues(
              alpha: 0.6,
            ),
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            textStyle: _primaryButtonTextStyle,
          ),
          child: child,
        ),
      ),
    );

    if (onPressed == null) {
      return Opacity(opacity: 0.5, child: button);
    }
    return button;
  }

  Widget _buildGenerateButton(ColorScheme colorScheme) {
    final isRecommended =
        _situation == 'just_matched' &&
        _newMatchMode == NewMatchMode.recommended;
    final label = (isRecommended || _suggestions.isNotEmpty)
        ? 'Regenerate'
        : (_situation == 'just_matched' ? 'Craft Opening' : 'Craft Response');
    return _buildPrimaryGradientButton(
      onPressed: (_isLoading || _isExtractingImage)
          ? null
          : _generateSuggestions,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GradientIcon(
            icon: Icons.auto_awesome_outlined,
            size: 20,
            gradient: LinearGradient(
              colors: [
                colorScheme.secondary,
                Color.lerp(colorScheme.secondary, colorScheme.primary, 0.45) ??
                    colorScheme.secondary,
              ],
            ),
          ),
          const SizedBox(width: 10),
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
            icon: const Icon(Icons.add_outlined, size: 18),
            label: const Text('New chat'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultsSection(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: BreathingLogoIndicator(
                    assetPath: 'assets/images/icons/appstore_transparent.png',
                    size: 84,
                    glowColor: colorScheme.secondary,
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
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surfaceContainerLow,
              colorScheme.surfaceContainerLow.withValues(alpha: 0.9),
              colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.35),
                  ),
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.pen,
                  size: 32,
                  color: colorScheme.secondary.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Workspace Ready',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a screenshot or provide context to begin crafting your next move.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Results
    final resultsLabel = _situation == 'just_matched'
        ? 'Your Approach'
        : 'Curated Responses';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle_outlined,
                  color: colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                resultsLabel,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;
          final start = (index * 0.12).clamp(0.0, 0.6);
          final end = (start + 0.5).clamp(0.0, 1.0);
          final animation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(animation),
              child: _SuggestionCard(
                index: index,
                suggestion: suggestion,
                colorScheme: colorScheme,
                onTap: suggestion.isLocked
                    ? () => _showUpgradePopup(suggestion.lockedReplyId)
                    : () => _copySuggestion(suggestion.message),
              ),
            ),
          );
        }),
        const SizedBox(height: 32),
      ],
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

enum _PulseCheckAction { negative, positive }

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
    final textTheme = Theme.of(context).textTheme;
    final badgeLabel = (index + 1).toString().padLeft(2, '0');
    final isDark = colorScheme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(isDark ? 18 : 14);
    final cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.secondary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isDark
                      ? null
                      : Border.all(
                          color: const Color(0xFFC4A462), // Champagne Gold
                          width: 1.5,
                        ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: colorScheme.secondary.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? colorScheme.onSecondary
                        : const Color(0xFFC4A462),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: Icon(
                  suggestion.isLocked
                      ? Icons.lock_outline
                      : (isDark ? Icons.copy_outlined : Icons.copy),
                  size: 20,
                  color: isDark
                      ? colorScheme.onSurfaceVariant
                      : const Color(0xFFC4A462),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (suggestion.isLocked) ...[
            // Locked state: show preview text + fake blurred block
            Text(
              suggestion.blurPreview ?? '',
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to unlock',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
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
                      Icons.lightbulb_outlined,
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
        ],
      ),
    );

    if (!isDark) {
      return Card(
        elevation: 1,
        shadowColor: _smartReplyCardShadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        color: colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: borderRadius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: cardContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}




