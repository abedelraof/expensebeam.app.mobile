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
        id: (j['_id'] ?? j['id'] ?? j['expenseId'] ?? j['expense_id'] ?? '').toString(),
        amount: j['amount'] is num
            ? (j['amount'] as num).toDouble()
            : double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
        currency: j['currency']?.toString() ?? 'EGP',
        description: j['description']?.toString() ?? '',
        category: j['category_name']?.toString() ??
            (j['category'] is Map
                ? j['category']['name']?.toString()
                : j['category']?.toString()),
        subcategory: j['subcategory_name']?.toString() ??
            (j['subcategory'] is Map
                ? j['subcategory']['name']?.toString()
                : j['subcategory']?.toString()),
        date: j['date'] != null
            ? (DateTime.tryParse(j['date'].toString()) ?? DateTime.now())
            : DateTime.now(),
        tags: j['tags'] is List
            ? (j['tags'] as List).map((t) => t.toString()).toList()
            : [],
        notes: j['notes']?.toString(),
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
