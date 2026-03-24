import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../models/pricing_plan.dart';
import '../../services/api_client.dart';
import '../../services/local_notification_service.dart';
import '../../state/app_state.dart';
import '../../utils/app_logger.dart';
import 'signup_screen.dart';
import '../widgets/premium_gradient_button.dart';
import '../widgets/thinking_indicator.dart';

class PricingScreen extends StatefulWidget {
  final bool showCloseButton;
  final bool guestConversionMode;

  const PricingScreen({
    super.key,
    this.showCloseButton = true,
    this.guestConversionMode = false,
  });

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen>
    with WidgetsBindingObserver {
  PricingPlan? _selectedPlan;
  bool _isProcessing = false;
  bool _isBillingAvailable = true;
  bool _isLoadingProducts = true;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final Map<String, ProductDetails> _productsById = {};
  final ApiClient _apiClient = ApiClient();
  final Set<String> _handledPurchaseTokens = {};
  bool _didCompletePurchase = false;
  bool _isRefreshingPurchases = false;

  static const String _handledTokensKey = 'handled_purchase_tokens';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHandledTokens().then((_) async {
      await _initializeBilling();
      // Refresh subscription status on entry
      await _apiClient.refreshSubscriptionStatus();
      if (mounted) {
        await AppStateScope.of(context).reloadFromStorage();
      }
    });
  }

  Future<void> _loadHandledTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokens = prefs.getStringList(_handledTokensKey) ?? [];
      _handledPurchaseTokens.addAll(tokens);
    } catch (e) {
      // Ignore errors loading tokens
    }
  }

  Future<void> _saveHandledToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _handledPurchaseTokens.add(token);
      await prefs.setStringList(
        _handledTokensKey,
        _handledPurchaseTokens.toList(),
      );
      AppLogger.debug(
        'Saved handled purchase token (total=${_handledPurchaseTokens.length})',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to save purchase token',
        e is Exception ? e : null,
      );
    }
  }

  Future<void> _initializeBilling() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      if (mounted) {
        setState(() {
          _isBillingAvailable = false;
          _isLoadingProducts = false;
        });
      }
      return;
    }

    final productIds = PricingPlan.allPlans.map((plan) => plan.id).toSet();
    final response = await _inAppPurchase.queryProductDetails(productIds);

    // Set up purchase stream listener FIRST before any other operations
    // This listener will automatically receive any pending purchases from Google Play
    AppLogger.debug('Setting up purchase stream listener...');
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      (purchases) {
        AppLogger.debug(
          'Purchase stream fired with ${purchases.length} purchases',
        );
        _handlePurchaseUpdates(purchases);
      },
      onError: (error) {
        AppLogger.error('Purchase stream error: $error');
        if (mounted) {
          final l10n = context.l10n;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.pricingPurchaseError(error.toString())),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
          );
        }
      },
    );
    AppLogger.debug('Purchase stream listener active');

    if (mounted) {
      setState(() {
        _isBillingAvailable = available;
        _isLoadingProducts = false;
        _productsById.clear();
        for (final product in response.productDetails) {
          _productsById[product.id] = product;
        }
      });
    }

    // Now check for any pending purchases
    await _refreshPendingPurchases();
  }

  Future<void> _refreshPendingPurchases() async {
    if (mounted) {
      setState(() {
        _isRefreshingPurchases = true;
      });
    }
    try {
      AppLogger.debug('Checking for pending purchases...');

      // The purchase stream should automatically deliver pending purchases
      // when we first subscribe to it. Calling restorePurchases() will
      // re-trigger delivery of any unacknowledged purchases.
      await _inAppPurchase.restorePurchases();
      AppLogger.debug('Restore purchases call completed');

      // Give time for the purchase stream to process any pending purchases
      await Future.delayed(const Duration(milliseconds: 1000));

      AppLogger.debug('Pending purchase check completed');
    } catch (e) {
      AppLogger.error(
        'Failed to check pending purchases',
        e is Exception ? e : null,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingPurchases = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPendingPurchases();
    }
  }

  Future<void> _handlePurchase(PricingPlan plan) async {
    final l10n = context.l10n;
    if (!_isBillingAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pricingBillingUnavailable),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }

    if (_isLoadingProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pricingLoadingProductsTryAgain),
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        ),
      );
      return;
    }

    if (!_productsById.containsKey(plan.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pricingProductUnavailable),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }

    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      final loginResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const SignupScreen()),
      );

      if (loginResult == true && mounted) {
        await appState.reloadFromStorage();
        _processPurchase(plan);
      }
      return;
    }

    _processPurchase(plan);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    AppLogger.debug('Purchase update received: ${purchases.length} purchases');

    for (final purchase in purchases) {
      AppLogger.debug(
        'Processing purchase: ${purchase.productID}, '
        'status: ${purchase.status}, '
        'pending: ${purchase.pendingCompletePurchase}',
      );

      switch (purchase.status) {
        case PurchaseStatus.pending:
          AppLogger.debug('Purchase pending: ${purchase.productID}');
          if (mounted) {
            setState(() {
              _isProcessing = true;
            });
          }
          break;
        case PurchaseStatus.error:
          if (mounted) {
            HapticFeedback.heavyImpact();
            final l10n = context.l10n;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.pricingPaymentDeclinedToast),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
              ),
            );
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(l10n.pricingPaymentDeclinedTitle),
                content: Text(l10n.pricingPaymentDeclinedMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.commonClose),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _refreshPendingPurchases();
                    },
                    child: Text(l10n.pricingTryAnotherCard),
                  ),
                ],
              ),
            );
            setState(() {
              _isProcessing = false;
              _selectedPlan = null;
            });
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          AppLogger.debug('Purchase ${purchase.status}: ${purchase.productID}');

          // CRITICAL FIX: Always complete purchase IMMEDIATELY to prevent Google Play account lock
          // This must happen FIRST, before any async operations that could fail or timeout
          // Google Play requires acknowledgement within 3 days or auto-refunds
          if (purchase.pendingCompletePurchase) {
            AppLogger.debug(
              'Immediately completing purchase to unlock Google Play account: ${purchase.productID}',
            );
            await _inAppPurchase.completePurchase(purchase);
            AppLogger.debug(
              'Purchase completed with Google Play: ${purchase.productID}',
            );
          }

          // Now verify and deliver credits (can be done after completion)
          await _verifyAndDeliverPurchase(
            purchase,
            showFailure: purchase.status == PurchaseStatus.purchased,
          );
          break;
        case PurchaseStatus.canceled:
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _selectedPlan = null;
            });
          }
          break;
      }
    }
  }

  Future<bool> _verifyAndDeliverPurchase(
    PurchaseDetails purchase, {
    required bool showFailure,
  }) async {
    if (!mounted) return false;

    final tokenKey = purchase.verificationData.serverVerificationData;
    final wasProcessing = _isProcessing;

    AppLogger.debug('Verifying purchase: ${purchase.productID}');

    // Check if we've already handled this purchase token
    if (_handledPurchaseTokens.contains(tokenKey)) {
      AppLogger.debug(
        'Purchase token already handled, skipping verification: ${purchase.productID}',
      );
      // Purchase already handled, don't process again
      // But we should still complete it if needed to remove from Google Play queue
      return true;
    }

    final success = await _apiClient.confirmGooglePlaySubscription(
      productId: purchase.productID,
      purchaseToken: purchase.verificationData.serverVerificationData,
    );

    if (!mounted) return false;
    await AppStateScope.of(context).reloadFromStorage();

    if (success) {
      await _saveHandledToken(tokenKey);
      await LocalNotificationService.cancelUpgradeNudge();
      await LocalNotificationService.cancelDailyRefillReminder();
      _handleSuccessfulPurchase(isDelayed: !wasProcessing);

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedPlan = null;
        });
      }
      return true;
    }

    if (showFailure && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pricingVerificationFailed),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _selectedPlan = null;
      });
    }
    return false;
  }

  void _handleSuccessfulPurchase({bool isDelayed = false}) {
    if (_didCompletePurchase) {
      return;
    }
    _didCompletePurchase = true;

    HapticFeedback.lightImpact();

    // If this is a delayed purchase (not actively processing), just show snackbar
    if (isDelayed) {
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
                Expanded(
                  child: Text(context.l10n.pricingPreviousPurchaseApproved),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      // Active purchase - pop the screen with success
      Navigator.pop(context, true);
    }
  }

  Future<void> _processPurchase(PricingPlan plan) async {
    setState(() {
      _selectedPlan = plan;
      _isProcessing = true;
    });

    try {
      final product = _productsById[plan.id];
      if (product == null) {
        throw Exception('product_not_found');
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!started && mounted) {
        throw Exception('purchase_flow_not_started');
      }
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        final raw = e.toString().replaceAll('Exception: ', '');
        final reason = switch (raw) {
          'product_not_found' => l10n.pricingProductNotFound,
          'purchase_flow_not_started' => l10n.pricingCouldNotStartPurchaseFlow,
          _ => raw,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pricingPurchaseFailed(reason)),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedPlan = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final isLight = theme.brightness == Brightness.light;
    final appState = AppStateScope.of(context);
    final plans = PricingPlan.allPlans;
    final plan = plans.isNotEmpty ? plans.first : null;
    final isSelected = plan != null && _selectedPlan?.id == plan.id;
    final isProcessing = _isProcessing && isSelected;
    final baseBackground = isLight
        ? colorScheme.surfaceDim
        : colorScheme.surfaceContainerLowest;
    final cardBackground = isLight
        ? colorScheme.surface
        : colorScheme.surfaceContainer;
    final cardBorderColor = isLight
        ? colorScheme.secondary.withValues(alpha: 0.2)
        : colorScheme.secondary.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: widget.showCloseButton
            ? IconButton(
                icon: Icon(Icons.close_outlined, color: colorScheme.onSurface),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
              )
            : null,
        actions: [
          if (appState.isLoggedIn)
            IconButton(
              tooltip: _isRefreshingPurchases
                  ? l10n.pricingRefreshing
                  : l10n.pricingRefreshPurchases,
              onPressed: _isProcessing
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _refreshPendingPurchases();
                    },
              icon: AnimatedRotation(
                turns: _isRefreshingPurchases ? 1 : 0,
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeInOut,
                child: Icon(
                  Icons.refresh_outlined,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color.lerp(baseBackground, colorScheme.surface, 0.06) ??
                        baseBackground,
                    baseBackground,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.28),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer.withValues(
                        alpha: isLight ? 0.56 : 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(
                            alpha: isLight ? 0.14 : 0.35,
                          ),
                          blurRadius: isLight ? 28 : 34,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: isLight ? 0.16 : 0.2,
                          ),
                          blurRadius: isLight ? 44 : 50,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.pricingHeroLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.pricingHeroTitle,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 42,
                            height: 0.9,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildPremiumFeature(
                          icon: Icons.diamond_outlined,
                          title: l10n.pricingFeatureReasoningTitle,
                          subtitle: l10n.pricingFeatureReasoningSubtitle,
                          colorScheme: colorScheme,
                        ),
                        _buildPremiumFeature(
                          icon: Icons.bolt_outlined,
                          title: l10n.pricingFeatureFlowTitle,
                          subtitle: l10n.pricingFeatureFlowSubtitle,
                          colorScheme: colorScheme,
                        ),
                        _buildPremiumFeature(
                          icon: Icons.psychology_outlined,
                          title: l10n.pricingFeatureTonalityTitle,
                          subtitle: l10n.pricingFeatureTonalitySubtitle,
                          colorScheme: colorScheme,
                        ),
                        _buildPremiumFeature(
                          icon: Icons.visibility_outlined,
                          title: l10n.pricingFeatureContextTitle,
                          subtitle: l10n.pricingFeatureContextSubtitle,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isLight
                                ? colorScheme.surfaceContainerHighest
                                : colorScheme.surfaceContainerLow.withValues(
                                    alpha: 0.72,
                                  ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.22,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                plan != null
                                    ? _weeklyPriceLabel(plan)
                                    : l10n.pricingWeeklyFallback,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.pricingCoffeeLine,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: PremiumGradientButton(
                            onPressed: (plan == null || isProcessing)
                                ? null
                                : () => _handlePurchase(plan),
                            height: 54,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(999),
                            ),
                            colors: isLight
                                ? [colorScheme.primary, colorScheme.primary]
                                : [colorScheme.primary, colorScheme.tertiary],
                            child: isProcessing
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: BreathingPulseIndicator(
                                      size: 18,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.lock_open_outlined,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.pricingUnlockEliteAccess,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSocialProofBadge(colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    String? badgeText,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.secondaryContainer.withValues(alpha: 0.65),
            ),
            child: Icon(icon, size: 18, color: colorScheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProofBadge(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 34,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatarIcon(
                  Icons.person_outline,
                  const Offset(0, 0),
                  colorScheme,
                ),
                _buildAvatarIcon(
                  Icons.person_outline,
                  const Offset(22, 0),
                  colorScheme,
                ),
                _buildAvatarIcon(
                  Icons.person_outline,
                  const Offset(44, 0),
                  colorScheme,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (_) => Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.pricingSocialProof,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarIcon(
    IconData icon,
    Offset offset,
    ColorScheme colorScheme,
  ) {
    final secondaryBlend =
        Color.lerp(colorScheme.secondary, colorScheme.primary, 0.35) ??
        colorScheme.secondary;
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, secondaryBlend],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.surface, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: colorScheme.onPrimary),
      ),
    );
  }

  String _weeklyPriceLabel(PricingPlan plan) {
    return context.l10n.pricingWeeklyPrice(plan.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
