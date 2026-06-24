import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/goal.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../goals/edit_goal_screen.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  List<Goal> _goals = [];
  List<dynamic> _budgets = [];
  List<String> _categoryNames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/goals'),
        ApiClient.get('/budgets'),
        ApiClient.get('/categories'),
      ]);

      final gData = results[0].data;
      final gList = gData is List ? gData : (gData['goals'] ?? gData['data'] ?? []);
      _goals = (gList as List).map((g) => Goal.fromJson(Map<String, dynamic>.from(g))).toList();

      final bData = results[1].data;
      _budgets = bData is List ? bData : (bData['budgets'] ?? bData['data'] ?? []);

      final cData = results[2].data;
      final cList = cData is List ? cData : (cData['categories'] ?? cData['data'] ?? []);
      _categoryNames = (cList as List)
          .map((c) => (c is Map ? c['name'] : c)?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ── Goals ──────────────────────────────────────────────────────────────────

  Future<void> _deleteGoal(Goal goal) async {
    try {
      await ApiClient.delete('/goals/${goal.id}');
      _load();
    } catch (_) {}
  }

  void _confirmDeleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?', style: TextStyle(fontSize: 15)),
        content: Text('Remove "${goal.name}" permanently?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                  onPressed: () { Navigator.pop(ctx); _deleteGoal(goal); },
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Budgets ────────────────────────────────────────────────────────────────

  Future<void> _deleteBudget(dynamic budget) async {
    final id = budget['_id'] ?? budget['id'];
    try {
      await ApiClient.delete('/budgets/$id');
      _load();
    } catch (_) {}
  }

  void _confirmDeleteBudget(dynamic budget) {
    final name = budget['category']?.toString() ?? 'this budget';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete budget?', style: TextStyle(fontSize: 15)),
        content: Text('Remove "$name" permanently?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                  onPressed: () { Navigator.pop(ctx); _deleteBudget(budget); },
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showBudgetSheet({dynamic budget}) async {
    String? selectedCategory = budget?['category']?.toString();
    final limitCtrl = TextEditingController(text: budget?['limit']?.toString() ?? '');
    String period = budget?['period']?.toString() ?? 'monthly';
    final isNew = budget == null;

    // Ensure selectedCategory is valid within the list
    if (selectedCategory != null && !_categoryNames.contains(selectedCategory)) {
      selectedCategory = null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(isNew ? 'Add Budget' : 'Edit Budget',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined, size: 18),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('— Select category —',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  ..._categoryNames.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) => setS(() => selectedCategory = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Limit Amount',
                  prefixIcon: Icon(Icons.attach_money, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: period,
                decoration: const InputDecoration(labelText: 'Period'),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (v) => setS(() => period = v!),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (selectedCategory == null || limitCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final data = {
                      'category': selectedCategory,
                      'limit': double.parse(limitCtrl.text),
                      'period': period,
                    };
                    if (isNew) {
                      await ApiClient.post('/budgets', data: data);
                    } else {
                      final id = budget!['_id'] ?? budget['id'];
                      await ApiClient.put('/budgets/$id', data: data);
                    }
                    _load();
                  } catch (_) {}
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isNew ? 'Add Budget' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // ── Savings Goals ──────────────────────────────────────────
                _sectionHeader(
                  'Savings Goals',
                  onAdd: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const EditGoalScreen()));
                    _load();
                  },
                ),
                const SizedBox(height: 12),
                if (_goals.isEmpty)
                  _emptyState(
                    icon: Icons.savings_outlined,
                    message: 'No savings goals found.',
                    cta: 'Create Goal',
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EditGoalScreen()));
                      _load();
                    },
                  )
                else
                  ..._goals.map((g) => _goalCard(g)),

                const SizedBox(height: 24),

                // ── Monthly Budgets ────────────────────────────────────────
                _sectionHeader(
                  'Monthly Budgets',
                  onAdd: () => _showBudgetSheet(),
                ),
                const SizedBox(height: 12),
                if (_budgets.isEmpty)
                  _emptyState(
                    icon: Icons.pie_chart_outline,
                    message: 'No budgets found.',
                    cta: 'Create Budget',
                    onTap: () => _showBudgetSheet(),
                  )
                else
                  ..._budgets.map((b) => _budgetCard(b)),
              ],
            ),
          );
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, {required VoidCallback onAdd}) => Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const Spacer(),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accent,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      );

  // ── Goal card ──────────────────────────────────────────────────────────────
  Widget _goalCard(Goal goal) {
    final pct = goal.progress;
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';
    final days = goal.daysRemaining;
    final effectiveAmount = goal.effectiveAmount;

    Color progressColor;
    if (pct >= 1.0) {
      progressColor = AppTheme.success;
    } else if (days != null && days < 0) {
      progressColor = AppTheme.danger;
    } else if (days != null && days < 30) {
      progressColor = AppTheme.warning;
    } else {
      progressColor = AppTheme.accent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: icon + name + overflow menu
            Row(
              children: [
                if (goal.icon != null) ...[
                  Text(goal.icon!, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(goal.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textSecondary),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => EditGoalScreen(goal: goal)));
                      _load();
                    } else {
                      _confirmDeleteGoal(goal);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit'),
                    ])),
                    PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppTheme.danger)),
                    ])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar (full width)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: AppTheme.fieldBorder,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),

            // Amounts + percentage
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatCurrency(effectiveAmount, goal.targetCurrency)} / ${formatCurrency(goal.targetAmount, goal.targetCurrency)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(pctLabel,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: progressColor)),
              ],
            ),

            // Days left + linked account
            const SizedBox(height: 4),
            Row(
              children: [
                if (days != null) ...[
                  Icon(
                    days < 0 ? Icons.warning_amber_rounded : Icons.schedule,
                    size: 12,
                    color: days < 0 ? AppTheme.danger : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    days < 0 ? 'Overdue by ${days.abs()} days' : '$days days left',
                    style: TextStyle(
                        fontSize: 11,
                        color: days < 0 ? AppTheme.danger : AppTheme.textSecondary),
                  ),
                ],
                if (goal.accountName != null) ...[
                  if (days != null) const SizedBox(width: 10),
                  const Icon(Icons.link, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      goal.accountName!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Budget card ────────────────────────────────────────────────────────────
  Widget _budgetCard(dynamic b) {
    final map = b is Map ? b : {};
    final limit = (map['limit'] as num?)?.toDouble() ?? 0;
    final spent = (map['spent'] as num?)?.toDouble() ?? 0;
    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';
    final currency = map['currency']?.toString() ?? 'EGP';
    final category = map['category']?.toString() ??
        map['name']?.toString() ??
        map['categoryName']?.toString() ??
        map['category_name']?.toString() ??
        '';
    final period = map['period']?.toString() ?? '';

    Color progressColor;
    if (pct >= 1.0) {
      progressColor = AppTheme.danger;
    } else if (pct >= 0.8) {
      progressColor = AppTheme.warning;
    } else {
      progressColor = AppTheme.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: icon + category + period + overflow
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.category_outlined, size: 18, color: progressColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (period.isNotEmpty)
                        Text(period[0].toUpperCase() + period.substring(1),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textSecondary),
                  onSelected: (v) {
                    if (v == 'edit') {
                      _showBudgetSheet(budget: b);
                    } else {
                      _confirmDeleteBudget(b);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit'),
                    ])),
                    PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppTheme.danger)),
                    ])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: AppTheme.fieldBorder,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),

            // Amounts + percentage
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatCurrency(spent, currency)} / ${formatCurrency(limit, currency)} spent',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(pctLabel,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: progressColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String message,
    required String cta,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.fieldBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 44, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(cta, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
}
