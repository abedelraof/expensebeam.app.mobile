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
        id: (j['_id'] ?? j['id'] ?? j['recurring_id'] ?? '').toString(),
        description: j['description']?.toString() ?? '',
        amount: j['amount'] is num
            ? (j['amount'] as num).toDouble()
            : double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
        currency: j['currency']?.toString() ?? 'EGP',
        interval: j['interval']?.toString() ?? j['frequency']?.toString() ?? 'monthly',
        nextDue: j['next_due'] != null
            ? (DateTime.tryParse(j['next_due'].toString()) ?? DateTime.now())
            : j['nextDue'] != null
                ? (DateTime.tryParse(j['nextDue'].toString()) ?? DateTime.now())
                : DateTime.now(),
        category: (j['category_name'] ?? j['category'])?.toString(),
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
