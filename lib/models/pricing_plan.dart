class PricingPlan {
  final String id;
  final String name;
  final double price;
  final String priceString;
  final bool isPopular;
  final List<String> features;
  final String? savingsText;
  final bool isSubscription;
  final String? billingPeriod;
  final String? tagline;

  PricingPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.priceString,
    this.isPopular = false,
    required this.features,
    this.savingsText,
    this.isSubscription = false,
    this.billingPeriod,
    this.tagline,
  });

  double? get pricePerCredit => null;

  // Predefined plans
  static List<PricingPlan> get allPlans => [
    PricingPlan(
      id: 'flirtfix_unlimited_weekly_v1',
      name: 'FlirtFix Unlimited Weekly',
      price: 6.99,
      priceString: '\$6.99/week',
      billingPeriod: 'Billed weekly · Cancel anytime',
      isSubscription: true,
      tagline: 'Unlimited AI help for dating chats',
      features: [
        'Unlimited AI replies & regens (fair use)',
        'Fast OCR from screenshots',
        'Tailored openers from images',
        'Priority access during peak hours',
      ],
    ),
  ];
}
