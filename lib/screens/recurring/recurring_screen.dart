import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/recurring.dart';
import '../../core/utils/formatters.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  List<Recurring> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/recurring');
      final data = res.data;
      final list =
          data is List ? data : (data['recurring'] ?? data['data'] ?? []);
      _items = (list as List).map((r) => Recurring.fromJson(r)).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(Recurring r) async {
    try {
      await ApiClient.delete('/recurring/${r.id}');
      _load();
    } catch (_) {}
  }

  Future<void> _addNew() async {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final currencyCtrl = TextEditingController(text: 'EGP');
    String interval = 'monthly';
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
              Text('Add Recurring',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Amount'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: currencyCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Currency'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: interval,
                decoration:
                    const InputDecoration(labelText: 'Interval'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(
                      value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(
                      value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(
                      value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (v) => setS(() => interval = v!),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (descCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await ApiClient.post('/recurring', data: {
                      'description': descCtrl.text.trim(),
                      'amount': double.parse(amountCtrl.text),
                      'currency':
                          currencyCtrl.text.trim().toUpperCase(),
                      'interval': interval,
                      'nextDue': DateTime.now()
                          .add(const Duration(days: 1))
                          .toIso8601String(),
                    });
                    _load();
                  } catch (_) {}
                },
                child: const Text('Add'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static const _intervalIcons = {
    'daily': Icons.repeat,
    'weekly': Icons.view_week,
    'monthly': Icons.calendar_month,
    'yearly': Icons.calendar_today,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Expenses')),
      floatingActionButton:
          FloatingActionButton(onPressed: _addNew, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No recurring expenses'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Theme.of(ctx).colorScheme.error,
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(item),
                      child: Card(
                        child: ListTile(
                          leading: Icon(_intervalIcons[item.interval] ??
                              Icons.repeat),
                          title: Text(item.description),
                          subtitle: Text(
                              '${item.interval.toUpperCase()} • Next: ${formatDate(item.nextDue)}'),
                          trailing: Text(
                            formatCurrency(item.amount, item.currency),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
