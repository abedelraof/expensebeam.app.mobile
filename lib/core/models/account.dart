class Account {
  final String id;
  final String name;
  final String type;
  final String currency;
  final String icon;
  final double balance;
  final bool isLiability;
  final int? groupId;
  final double? quantity;
  final double? pricePerUnit;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.icon,
    required this.balance,
    required this.isLiability,
    this.groupId,
    this.quantity,
    this.pricePerUnit,
  });

  factory Account.fromJson(Map<String, dynamic> j) {
    // Balance from latest_balance or balance field
    double parseAmount(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;

    final qty = j['latest_quantity'] ?? j['quantity'];
    final ppu = j['latest_price_per_unit'] ?? j['pricePerUnit'] ?? j['price_per_unit'];

    return Account(
      id:           (j['_id'] ?? j['id'] ?? '').toString(),
      name:         j['name']?.toString() ?? '',
      type:         (j['type'] ?? 'monetary').toString(),
      currency:     (j['currency'] ?? 'EGP').toString(),
      icon:         j['icon']?.toString() ?? '💳',
      balance:      parseAmount(j['latest_balance'] ?? j['balance']),
      isLiability:  j['isLiability'] == true || j['is_liability'] == true ||
                    j['isLiability'] == 1 || j['is_liability'] == 1,
      groupId:      j['group_id'] != null
                    ? int.tryParse(j['group_id'].toString())
                    : null,
      quantity:     qty != null ? double.tryParse(qty.toString()) : null,
      pricePerUnit: ppu != null ? double.tryParse(ppu.toString()) : null,
    );
  }

  double get displayBalance =>
      (quantity != null && pricePerUnit != null)
          ? quantity! * pricePerUnit!
          : balance;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'currency': currency,
        'icon': icon,
        if (groupId != null) 'group_id': groupId,
      };
}

// ── Group model ───────────────────────────────────────────────────────────────
class AccountGroup {
  final int id;
  final String name;
  final String icon;
  final int sortOrder;

  const AccountGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
  });

  factory AccountGroup.fromJson(Map<String, dynamic> j) => AccountGroup(
        id:        (j['id'] as num).toInt(),
        name:      j['name']?.toString() ?? '',
        icon:      j['icon']?.toString() ?? '📁',
        sortOrder: (j['sort_order'] as num? ?? 0).toInt(),
      );
}
