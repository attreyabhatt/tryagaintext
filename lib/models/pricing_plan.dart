class PricingPlan {
  final String id;
  final String name;
  final int credits;
  final double price;
  final String priceString;
  final bool isPopular;
  final List<String> features;
  final String? savingsText;

  PricingPlan({
    required this.id,
    required this.name,
    required this.credits,
    required this.price,
    required this.priceString,
    this.isPopular = false,
    required this.features,
    this.savingsText,
  });

  double get pricePerCredit => price / credits;

  // Predefined plans
  static List<PricingPlan> get allPlans => [
    PricingPlan(
      id: 'starter_pack_v1',
      name: 'Starter Pack',
      credits: 25,
      price: 4.99,
      priceString: '\$4.99',
      features: [
        '25 Smart Replies',
        'All conversation types',
        'Image text extraction',
        'No expiration',
      ],
    ),
    PricingPlan(
      id: 'pro_pack_v1',
      name: 'Pro Pack',
      credits: 75,
      price: 9.99,
      priceString: '\$9.99',
      isPopular: true,
      savingsText: 'Save 33%',
      features: [
        '75 Smart Replies',
        'All conversation types',
        'Image text extraction',
        'Priority support',
        'No expiration',
      ],
    ),
    PricingPlan(
      id: 'ultimate_pack_v1',
      name: 'Ultimate Pack',
      credits: 200,
      price: 19.99,
      priceString: '\$19.99',
      savingsText: 'Save 50%',
      features: [
        '200 Smart Replies',
        'All conversation types',
        'Image text extraction',
        'Priority support',
        'Premium features first',
        'No expiration',
      ],
    ),
  ];
}
