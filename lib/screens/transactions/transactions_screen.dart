import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/expense.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/expense_tile.dart';
import 'edit_expense_screen.dart';
import 'search_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Expense> _expenses = [];
  bool _loading = false;
  int _page = 1;
  bool _hasMore = true;
  final _searchCtrl = TextEditingController();
  String _sort = 'date_desc';
  DateTimeRange? _dateRange;
  final _scrollCtrl = ScrollController();
  String? _highlightedId;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _page = 1;
      _hasMore = true;
      _expenses = [];
    }
    setState(() => _loading = true);
    try {
      final params = <String, String>{
        'page': '$_page',
        'limit': '20',
        'sort': _sort,
        if (_searchCtrl.text.isNotEmpty) 'search': _searchCtrl.text,
        if (_dateRange != null)
          'startDate': DateFormat('yyyy-MM-dd').format(_dateRange!.start),
        if (_dateRange != null)
          'endDate': DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      };
      final res = await ApiClient.get('/expenses', params: params);
      final data = res.data;

      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        for (final key in ['expenses', 'data', 'items', 'results']) {
          if (data[key] is List) { list = data[key]; break; }
        }
      }

      final fetched = <Expense>[];
      for (final e in list) {
        try { fetched.add(Expense.fromJson(Map<String, dynamic>.from(e))); }
        catch (_) {}
      }

      setState(() {
        _expenses.addAll(fetched);
        _hasMore = fetched.length == 20;
        _page++;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load transactions: $e')),
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      _dateRange = range;
      _load(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditExpenseScreen()));
          if (result != null) {
            _showSavedSnackbar(isNew: true);
            await _load(reset: true);
            if (result is String) _flashHighlight(result);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SearchScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                );
                _load(reset: true);
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.fieldBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search,
                        color: AppTheme.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Search expenses...',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14)),
                    ),
                    const Icon(Icons.tune,
                        color: AppTheme.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
          ),
          if (_dateRange != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(children: [
                Chip(
                  label: Text(
                      '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}'),
                  onDeleted: () {
                    _dateRange = null;
                    _load(reset: true);
                  },
                ),
              ]),
            ),
          Expanded(
            child: _expenses.isEmpty && !_loading
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _expenses.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _expenses.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return ExpenseTile(
                        expense: _expenses[i],
                        highlighted: _highlightedId == _expenses[i].id,
                        onDeleted: () => _load(reset: true),
                        onTap: () async {
                          final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EditExpenseScreen(
                                      expense: _expenses[i])));
                          if (result != null) {
                            _showSavedSnackbar(isNew: false);
                            await _load(reset: true);
                            if (result is String) _flashHighlight(result);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showSavedSnackbar({required bool isNew}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(isNew ? 'Expense added successfully' : 'Expense updated successfully'),
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter & Sort',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sort,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: const [
                DropdownMenuItem(
                    value: 'date_desc', child: Text('Date (Newest)')),
                DropdownMenuItem(
                    value: 'date_asc', child: Text('Date (Oldest)')),
                DropdownMenuItem(
                    value: 'amount_desc', child: Text('Amount (High)')),
                DropdownMenuItem(
                    value: 'amount_asc', child: Text('Amount (Low)')),
              ],
              onChanged: (v) => setState(() => _sort = v!),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_dateRange == null
                  ? 'Pick Date Range'
                  : '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}'),
              onPressed: () {
                Navigator.pop(ctx);
                _pickDateRange();
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _load(reset: true);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
