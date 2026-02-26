class PricingPlan {
  final String id;
  final double price;
  final bool isSubscription;

  PricingPlan({
    required this.id,
    required this.price,
    this.isSubscription = false,
  });

  double? get pricePerCredit => null;

  static List<PricingPlan> get allPlans => [
    PricingPlan(
      id: 'flirtfix_unlimited_weekly_v1',
      price: 6.99,
      isSubscription: true,
    ),
  ];
}
