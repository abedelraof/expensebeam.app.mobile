import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/recurring.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'edit_recurring_screen.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  List<Recurring> _items    = [];
  bool  _loading            = false;
  String? _highlightedId;

  static const _intervalIcons = {
    'daily':   Icons.repeat,
    'weekly':  Icons.view_week,
    'monthly': Icons.calendar_month,
    'yearly':  Icons.calendar_today,
  };

  static const _intervalColors = {
    'daily':   Color(0xFF10B981),
    'weekly':  Color(0xFF2B7BE0),
    'monthly': Color(0xFFF59E0B),
    'yearly':  Color(0xFF8B5CF6),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res  = await ApiClient.get('/recurring');
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        for (final key in ['recurring', 'data', 'items', 'results']) {
          if (data[key] is List) { list = data[key]; break; }
        }
      }
      final fetched = <Recurring>[];
      for (final r in list) {
        try { fetched.add(Recurring.fromJson(Map<String, dynamic>.from(r))); }
        catch (_) {}
      }
      if (mounted) setState(() => _items = fetched);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(Recurring r) async {
    try {
      await ApiClient.delete('/recurring/${r.id}');
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete')),
        );
      }
    }
  }

  void _showSavedSnackbar({required bool isNew}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(isNew ? 'Recurring expense added' : 'Recurring expense updated'),
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _flashHighlight(String id) {
    setState(() => _highlightedId = id);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditRecurringScreen()));
          if (result != null) {
            _showSavedSnackbar(isNew: true);
            await _load();
            if (result is String) _flashHighlight(result);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_outlined,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text('No recurring expenses',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary)),
                      const SizedBox(height: 6),
                      const Text('Tap + to add your first recurring expense',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      final color = _intervalColors[item.interval] ?? AppTheme.accent;
                      final icon  = _intervalIcons[item.interval] ?? Icons.repeat;
                      final isHighlighted = _highlightedId == item.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: Key(item.id.isNotEmpty
                              ? item.id
                              : item.hashCode.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async => await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete recurring expense?'),
                              content: Text(
                                  'This will remove "${item.description}" permanently.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.danger),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          ),
                          onDismissed: (_) => _delete(item),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isHighlighted
                                    ? color.withValues(alpha: 0.4)
                                    : AppTheme.fieldBorder,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => EditRecurringScreen(
                                            recurring: item)));
                                if (result != null) {
                                  _showSavedSnackbar(isNew: false);
                                  await _load();
                                  if (result is String) _flashHighlight(result);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(icon, size: 22, color: color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.description,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Row(children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.interval.toUpperCase(),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: color,
                                                    letterSpacing: 0.5),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Next: ${formatDate(item.nextDue)}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textSecondary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formatCurrency(item.amount, item.currency),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.danger),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
