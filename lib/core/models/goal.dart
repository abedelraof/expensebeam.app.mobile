class Goal {
  final String id;
  final String name;
  final String? icon;
  final double targetAmount;
  final String targetCurrency;
  final double currentAmount;   // manual goals
  final DateTime? targetDate;
  final String? accountId;      // linked account (null = manual)
  final String? accountName;
  final double? latestBalance;  // linked account balance

  Goal({
    required this.id,
    required this.name,
    this.icon,
    required this.targetAmount,
    required this.targetCurrency,
    required this.currentAmount,
    this.targetDate,
    this.accountId,
    this.accountName,
    this.latestBalance,
  });

  /// If linked to an account → use latest_balance, else current_amount
  double get effectiveAmount =>
      accountId != null ? (latestBalance ?? 0) : currentAmount;

  double get progress =>
      targetAmount > 0 ? (effectiveAmount / targetAmount).clamp(0.0, 1.0) : 0;

  int? get daysRemaining =>
      targetDate?.difference(DateTime.now()).inDays;

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        name: j['name'] ?? '',
        icon: j['icon']?.toString(),
        targetAmount: _toDouble(j['target_amount'] ?? j['targetAmount']),
        targetCurrency: j['target_currency']?.toString() ??
            j['currency']?.toString() ??
            'EGP',
        currentAmount: _toDouble(j['current_amount'] ?? j['currentAmount']),
        targetDate: j['target_date'] != null
            ? DateTime.tryParse(j['target_date'].toString())
            : j['targetDate'] != null
                ? DateTime.tryParse(j['targetDate'].toString())
                : null,
        accountId: j['account_id']?.toString() ?? j['accountId']?.toString(),
        accountName: j['account_name']?.toString() ?? j['accountName']?.toString(),
        latestBalance: j['latest_balance'] != null
            ? _toDouble(j['latest_balance'])
            : j['latestBalance'] != null
                ? _toDouble(j['latestBalance'])
                : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (icon != null) 'icon': icon,
        'target_amount': targetAmount,
        'target_currency': targetCurrency,
        'current_amount': currentAmount,
        if (targetDate != null)
          'target_date': targetDate!.toIso8601String(),
        if (accountId != null) 'account_id': accountId,
      };
}
