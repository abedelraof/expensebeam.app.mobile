class Account {
  final String id;
  final String name;
  final String type;
  final String currency;
  final double balance;
  final bool isLiability;
  final double? quantity;
  final double? pricePerUnit;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    required this.isLiability,
    this.quantity,
    this.pricePerUnit,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['_id'] ?? j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'cash',
        currency: j['currency'] ?? 'EGP',
        balance: (j['balance'] as num? ?? 0).toDouble(),
        isLiability: j['isLiability'] ?? false,
        quantity: j['quantity'] != null
            ? (j['quantity'] as num).toDouble()
            : null,
        pricePerUnit: j['pricePerUnit'] != null
            ? (j['pricePerUnit'] as num).toDouble()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'currency': currency,
        'balance': balance,
        'isLiability': isLiability,
        if (quantity != null) 'quantity': quantity,
        if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
      };
}
