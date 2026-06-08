import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/goal.dart';
import '../../core/utils/formatters.dart';
import 'edit_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/goals');
      final data = res.data;
      final list =
          data is List ? data : (data['goals'] ?? data['data'] ?? []);
      _goals = (list as List).map((g) => Goal.fromJson(g)).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(Goal goal) async {
    try {
      await ApiClient.delete('/goals/${goal.id}');
      _load();
    } catch (_) {}
  }

  Color _daysColor(int? days) {
    if (days == null) return Colors.grey;
    if (days < 0) return Colors.red;
    if (days < 30) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditGoalScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? const Center(child: Text('No savings goals'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (ctx, i) {
                    final goal = _goals[i];
                    final days = goal.daysRemaining;
                    return Dismissible(
                      key: Key(goal.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Theme.of(ctx).colorScheme.error,
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(goal),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(goal.name,
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.bold)),
                                  ),
                                  if (days != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _daysColor(days),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        days < 0
                                            ? 'Overdue'
                                            : '$days days',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatCurrency(
                                      goal.currentAmount, goal.targetCurrency)),
                                  Text(formatCurrency(
                                      goal.targetAmount, goal.targetCurrency)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: goal.progress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      '${(goal.progress * 100).toStringAsFixed(0)}% complete',
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .labelSmall),
                                  if (goal.targetDate != null)
                                    Text(
                                        'Target: ${DateFormat('MMM d, yyyy').format(goal.targetDate!)}',
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .labelSmall),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                        ctx,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                EditGoalScreen(
                                                    goal: goal)));
                                    _load();
                                  },
                                  child: const Text('Edit'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
