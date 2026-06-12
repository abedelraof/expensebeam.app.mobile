class Income {
  final String id;
  final double amount;
  final String currency;
  final String description;
  final String source;
  final DateTime date;
  final String? notes;

  Income({
    required this.id,
    required this.amount,
    required this.currency,
    required this.description,
    required this.source,
    required this.date,
    this.notes,
  });

  factory Income.fromJson(Map<String, dynamic> j) => Income(
        id: (j['_id'] ?? j['id'] ?? j['income_id'] ?? '').toString(),
        amount: j['amount'] is num
            ? (j['amount'] as num).toDouble()
            : double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
        currency: j['currency']?.toString() ?? 'EGP',
        description: j['description']?.toString() ?? '',
        source: j['source']?.toString() ?? 'Other',
        date: j['date'] != null
            ? (DateTime.tryParse(j['date'].toString()) ?? DateTime.now())
            : DateTime.now(),
        notes: j['notes']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currency': currency,
        'description': description,
        'source': source,
        'date': date.toIso8601String(),
        'notes': notes,
      };
}
