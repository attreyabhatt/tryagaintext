import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/pricing_plan.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../utils/app_logger.dart';
import 'login_screen.dart';

class PricingScreen extends StatefulWidget {
  final bool showCloseButton;

  const PricingScreen({super.key, this.showCloseButton = true});

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
      AppLogger.debug('Saved purchase token: ${token.substring(0, 20)}... (Total: ${_handledPurchaseTokens.length})');
    } catch (e) {
      AppLogger.error('Failed to save purchase token', e is Exception ? e : null);
    }
  }

  // For debugging: Clear all handled purchase tokens
  Future<void> _clearHandledTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_handledTokensKey);
      _handledPurchaseTokens.clear();
      AppLogger.debug('Cleared all handled purchase tokens');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cleared purchase cache. Old purchases will be reprocessed.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to clear tokens', e is Exception ? e : null);
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
        AppLogger.debug('Purchase stream fired with ${purchases.length} purchases');
        _handlePurchaseUpdates(purchases);
      },
      onError: (error) {
        AppLogger.error('Purchase stream error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase error: ${error.toString()}'),
              backgroundColor: Colors.red[600],
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
      AppLogger.error('Failed to check pending purchases', e is Exception ? e : null);
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
    HapticFeedback.mediumImpact();
    if (!_isBillingAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Billing is not available on this device.'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    if (_isLoadingProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Loading products. Please try again.'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    if (!_productsById.containsKey(plan.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product not available. Please try again later.'),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    final appState = AppStateScope.of(context);
    if (!appState.isLoggedIn) {
      // Show login dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Sign In Required'),
          content: const Text(
            'Please sign in to start your subscription and link it to your account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        final loginResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );

        if (loginResult == true) {
          await appState.reloadFromStorage();
          // Proceed with purchase after login
          _processPurchase(plan);
        }
      }
      return;
    }

    _processPurchase(plan);
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    AppLogger.debug('Purchase update received: ${purchases.length} purchases');

    for (final purchase in purchases) {
      AppLogger.debug(
        'Processing purchase: ${purchase.productID}, '
        'status: ${purchase.status}, '
        'pending: ${purchase.pendingCompletePurchase}, '
        'token: ${purchase.verificationData.serverVerificationData.substring(0, 20)}...'
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment declined. Please try another card.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Payment declined'),
                content: const Text(
                  'Your payment was declined. Please try another card or payment method.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _refreshPendingPurchases();
                    },
                    child: const Text('Try another card'),
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
            AppLogger.debug('Immediately completing purchase to unlock Google Play account: ${purchase.productID}');
            await _inAppPurchase.completePurchase(purchase);
            AppLogger.debug('Purchase completed with Google Play: ${purchase.productID}');
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
    PurchaseDetails purchase,
    {required bool showFailure}
  ) async {
    if (!mounted) return false;

    final tokenKey = purchase.verificationData.serverVerificationData;
    final wasProcessing = _isProcessing;

    AppLogger.debug('Verifying purchase: ${purchase.productID}, token: ${tokenKey.substring(0, 20)}...');

    // Check if we've already handled this purchase token
    if (_handledPurchaseTokens.contains(tokenKey)) {
      AppLogger.debug('Purchase token already handled, skipping verification: ${purchase.productID}');
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
          content: const Text('Purchase verification failed.'),
          backgroundColor: Colors.red[600],
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
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your previous purchase was approved and your subscription is active.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
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
        throw Exception('Product not found');
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!started && mounted) {
        throw Exception('Could not start purchase flow');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red[600],
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
    final plans = PricingPlan.allPlans;
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.showCloseButton
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Go Unlimited',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.all_inclusive, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Unlock FlirtFix Unlimited',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (appState.isLoggedIn) ...[
                      GestureDetector(
                        onLongPress: _clearHandledTokens,
                        child: TextButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  _refreshPendingPurchases();
                                },
                          icon: AnimatedRotation(
                            turns: _isRefreshingPurchases ? 1 : 0,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            child: const Icon(Icons.refresh, size: 18),
                          ),
                          label: const Text('Refresh purchases'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Sign in to manage your subscription',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Features List
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What You Get',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      Icons.flash_on,
                      'Unlimited AI replies & regens',
                    ),
                    _buildFeatureItem(
                      Icons.image_search,
                      'Fast OCR from screenshots',
                    ),
                    _buildFeatureItem(
                      Icons.chat_bubble_outline,
                      'Tailored openers from images',
                    ),
                    _buildFeatureItem(Icons.verified, 'Priority access & updates'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Pricing Plans
              ...plans.asMap().entries.map((entry) {
                final plan = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPricingCard(plan, theme),
                );
              }),

              const SizedBox(height: 24),

              // Disclaimer
              Text(
                'Weekly subscription · Cancel anytime in Google Play · Fair-use applies',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(PricingPlan plan, ThemeData theme) {
    final isSelected = _selectedPlan?.id == plan.id;
    final isProcessing = _isProcessing && isSelected;

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      scale: isSelected ? 1.01 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: plan.isPopular ? theme.primaryColor : Colors.grey[200]!,
            width: plan.isPopular ? 2 : 1,
          ),
          boxShadow: [
            if (plan.isPopular)
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
          // Popular Badge
          if (plan.isPopular)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Name and Savings
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (plan.savingsText != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                plan.savingsText!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.priceString,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        if (plan.billingPeriod != null)
                          Text(
                            plan.billingPeriod!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (plan.tagline != null) ...[
                  Text(
                    plan.tagline!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Features
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Purchase Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _handlePurchase(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          plan.isPopular ? theme.primaryColor : Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Subscribe to ${plan.name}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
