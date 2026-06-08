import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/account.dart';
import '../../core/utils/formatters.dart';

class AccountHistoryScreen extends StatefulWidget {
  final Account account;
  const AccountHistoryScreen({super.key, required this.account});

  @override
  State<AccountHistoryScreen> createState() => _AccountHistoryScreenState();
}

class _AccountHistoryScreenState extends State<AccountHistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res =
          await ApiClient.get('/accounts/${widget.account.id}/history');
      final data = res.data;
      _history =
          data is List ? data : (data['history'] ?? data['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _addSnapshot() async {
    final balCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Balance Snapshot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: balCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Balance'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration:
                  const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiClient.post('/accounts/balances', data: {
                  'accountId': widget.account.id,
                  'balance': double.parse(balCtrl.text),
                  'date': DateTime.now().toIso8601String(),
                  if (noteCtrl.text.isNotEmpty) 'note': noteCtrl.text,
                });
                _load();
              } catch (_) {}
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSnapshot,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No balance history'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (ctx, i) {
                    final snap = _history[i];
                    final balance =
                        (snap['balance'] as num?)?.toDouble() ?? 0;
                    final date = snap['date'] != null
                        ? DateTime.tryParse(snap['date'].toString())
                        : null;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(formatCurrency(
                            balance, widget.account.currency)),
                        subtitle: Text(date != null
                            ? DateFormat('MMM d, yyyy HH:mm').format(date)
                            : ''),
                        trailing: snap['note'] != null
                            ? Text(snap['note'].toString(),
                                style: const TextStyle(fontSize: 12))
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
