class Expense {
  final String id;
  final double amount;
  final String currency;
  final String description;
  final String? category;
  final String? subcategory;
  final DateTime date;
  final List<String> tags;
  final String? notes;

  Expense({
    required this.id,
    required this.amount,
    required this.currency,
    required this.description,
    this.category,
    this.subcategory,
    required this.date,
    this.tags = const [],
    this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['_id'] ?? j['id'] ?? '',
        amount: (j['amount'] as num).toDouble(),
        currency: j['currency'] ?? 'EGP',
        description: j['description'] ?? '',
        category: j['category'],
        subcategory: j['subcategory'],
        date: DateTime.parse(j['date']),
        tags: List<String>.from(j['tags'] ?? []),
        notes: j['notes'],
      );

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currency': currency,
        'description': description,
        'category': category,
        'subcategory': subcategory,
        'date': date.toIso8601String(),
        'tags': tags,
        'notes': notes,
      };
}
