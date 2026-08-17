class UserPlan {
  final String plan;
  final int aiUsed;
  final int aiLimit;
  final String resetDate;

  const UserPlan({
    required this.plan,
    required this.aiUsed,
    required this.aiLimit,
    required this.resetDate,
  });

  factory UserPlan.fromJson(Map<String, dynamic> json) => UserPlan(
        plan: json['plan'] as String? ?? 'free',
        aiUsed: json['ai_used'] as int? ?? 0,
        aiLimit: json['ai_limit'] as int? ?? 0,
        resetDate: json['reset_date'] as String? ?? '',
      );

  bool get isPro => plan == 'pro';
  bool get isAiFull => aiUsed >= aiLimit;

  static UserPlan get freeFallback =>
      const UserPlan(plan: 'free', aiUsed: 0, aiLimit: 0, resetDate: '');
}
