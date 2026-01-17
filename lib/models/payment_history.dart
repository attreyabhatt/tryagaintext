class PaymentHistory {
  final int id;
  final int creditsPurchased;
  final String amountPaid;
  final DateTime timestamp;
  final String transactionId;
  final PaymentStatus status;
  final String paymentProvider;

  PaymentHistory({
    required this.id,
    required this.creditsPurchased,
    required this.amountPaid,
    required this.timestamp,
    required this.transactionId,
    required this.status,
    required this.paymentProvider,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'] as int,
      creditsPurchased: json['credits_purchased'] as int,
      amountPaid: json['amount_paid'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      transactionId: json['transaction_id'] as String? ?? '',
      status: PaymentStatus.fromString(json['payment_status'] as String),
      paymentProvider: json['payment_provider'] as String? ?? '',
    );
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed;

  static PaymentStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'COMPLETED':
        return PaymentStatus.completed;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'PENDING':
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }
}
