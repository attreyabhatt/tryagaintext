import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../models/pricing_plan.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import 'login_screen.dart';

class PricingScreen extends StatefulWidget {
  final bool showCloseButton;

  const PricingScreen({super.key, this.showCloseButton = true});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  PricingPlan? _selectedPlan;
  bool _isProcessing = false;
  bool _isBillingAvailable = true;
  bool _isLoadingProducts = true;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final Map<String, ProductDetails> _productsById = {};
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _initializeBilling();
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

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
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
  }

  Future<void> _handlePurchase(PricingPlan plan) async {
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
            'Please sign in to purchase credits. Your credits will be saved to your account.',
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
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          if (mounted) {
            setState(() {
              _isProcessing = true;
            });
          }
          break;
        case PurchaseStatus.error:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  purchase.error?.message ?? 'Purchase failed. Please try again.',
                ),
                backgroundColor: Colors.red[600],
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
          final ok = await _verifyAndDeliverPurchase(purchase);
          if (ok && purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
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
  ) async {
    final product = _productsById[purchase.productID];
    final creditsRemaining = await _apiClient.confirmGooglePlayPurchase(
      productId: purchase.productID,
      purchaseToken: purchase.verificationData.serverVerificationData,
      orderId: purchase.purchaseID,
      purchaseTime: purchase.transactionDate,
      price: product?.rawPrice,
      currency: product?.currencyCode,
    );

    if (!mounted) {
      return false;
    }

    if (creditsRemaining != null) {
      await AuthService.updateStoredCredits(creditsRemaining);
      await AppStateScope.of(context).reloadFromStorage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Purchase successful. Credits added!'),
          backgroundColor: Colors.green[600],
        ),
      );
      setState(() {
        _isProcessing = false;
        _selectedPlan = null;
      });
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Purchase verification failed.'),
        backgroundColor: Colors.red[600],
      ),
    );
    setState(() {
      _isProcessing = false;
      _selectedPlan = null;
    });
    return false;
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
      final started = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
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
          'Get More Credits',
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
                    const Icon(Icons.favorite, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Never Run Out of Great Lines',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (appState.isLoggedIn) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Current: ${appState.credits} credits',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Sign in to save your credits',
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
                      Icons.auto_awesome,
                      'AI-powered smart replies',
                    ),
                    _buildFeatureItem(
                      Icons.image,
                      'Screenshot text extraction',
                    ),
                    _buildFeatureItem(
                      Icons.all_inclusive,
                      'Credits never expire',
                    ),
                    _buildFeatureItem(Icons.security, 'Secure & private'),
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
                'One-time purchase - Credits never expire - Secure payment via Google Play',
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

    return Container(
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
                        Text(
                          '${(plan.pricePerCredit * 100).toStringAsFixed(0)}c per credit',
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

                // Credits Count
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${plan.credits} Credits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
                                'Buy ${plan.name}',
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
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
