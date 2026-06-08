class Recurring {
  final String id;
  final String description;
  final double amount;
  final String currency;
  final String interval;
  final DateTime nextDue;
  final String? category;

  Recurring({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    required this.interval,
    required this.nextDue,
    this.category,
  });

  factory Recurring.fromJson(Map<String, dynamic> j) => Recurring(
        id: j['_id'] ?? j['id'] ?? '',
        description: j['description'] ?? '',
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] ?? 'EGP',
        interval: j['interval'] ?? 'monthly',
        nextDue: DateTime.parse(j['nextDue']),
        category: j['category'],
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'amount': amount,
        'currency': currency,
        'interval': interval,
        'nextDue': nextDue.toIso8601String(),
        if (category != null) 'category': category,
      };
}
