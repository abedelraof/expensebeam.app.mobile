import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<dynamic> _budgets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/budgets');
      final data = res.data;
      _budgets =
          data is List ? data : (data['budgets'] ?? data['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final categoryCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    String period = 'monthly';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Budget',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: categoryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: limitCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Limit Amount'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: period,
                decoration: const InputDecoration(labelText: 'Period'),
                items: const [
                  DropdownMenuItem(
                      value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(
                      value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (v) => setS(() => period = v!),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (categoryCtrl.text.isEmpty || limitCtrl.text.isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ApiClient.post('/budgets', data: {
                      'category': categoryCtrl.text.trim(),
                      'limit': double.parse(limitCtrl.text),
                      'period': period,
                    });
                    _load();
                  } catch (_) {}
                },
                child: const Text('Add Budget'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(dynamic budget) async {
    final id = budget['_id'] ?? budget['id'];
    try {
      await ApiClient.delete('/budgets/$id');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton:
          FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
              ? const Center(child: Text('No budgets set'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _budgets.length,
                  itemBuilder: (ctx, i) {
                    final b = _budgets[i];
                    final limit =
                        (b['limit'] as num?)?.toDouble() ?? 0;
                    final spent =
                        (b['spent'] as num?)?.toDouble() ?? 0;
                    final pct =
                        limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                    return Dismissible(
                      key: Key(b['_id']?.toString() ?? i.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Theme.of(ctx).colorScheme.error,
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(b),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      b['category']?.toString() ??
                                          'Unknown',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(b['period']?.toString() ?? '',
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .labelSmall),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: pct,
                                color: pct >= 1
                                    ? Theme.of(ctx).colorScheme.error
                                    : pct >= 0.8
                                        ? AppTheme.warning
                                        : null,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Spent: ${formatCurrency(spent, b['currency']?.toString() ?? 'EGP')}'),
                                  Text(
                                      'Limit: ${formatCurrency(limit, b['currency']?.toString() ?? 'EGP')}'),
                                ],
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
