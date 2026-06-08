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
        id: j['_id'] ?? j['id'] ?? '',
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] ?? 'EGP',
        description: j['description'] ?? '',
        source: j['source'] ?? 'Other',
        date: DateTime.parse(j['date']),
        notes: j['notes'],
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
