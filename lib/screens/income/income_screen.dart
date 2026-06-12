import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/income.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'edit_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  List<Income> _incomes    = [];
  bool  _loading           = false;
  String? _highlightedId;
  DateTimeRange? _dateRange;
  String? _selectedSource;

  static const _sources = [
    'Salary', 'Business', 'Freelance', 'Investment', 'Rental', 'Gift', 'Other',
  ];

  static const _sourceColors = {
    'Salary':     Color(0xFF2B7BE0),
    'Business':   Color(0xFF10B981),
    'Freelance':  Color(0xFFF59E0B),
    'Investment': Color(0xFF8B5CF6),
    'Rental':     Color(0xFF14B8A6),
    'Gift':       Color(0xFFEC4899),
    'Other':      Color(0xFF8A8D9A),
  };

  static const _sourceIcons = {
    'Salary':     Icons.work_outline,
    'Business':   Icons.store_outlined,
    'Freelance':  Icons.laptop_outlined,
    'Investment': Icons.trending_up_outlined,
    'Rental':     Icons.home_outlined,
    'Gift':       Icons.card_giftcard_outlined,
    'Other':      Icons.attach_money,
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
      final params = <String, String>{
        'sort': 'date_desc',
        if (_selectedSource != null) 'source': _selectedSource!,
        if (_dateRange != null)
          'startDate': DateFormat('yyyy-MM-dd').format(_dateRange!.start),
        if (_dateRange != null)
          'endDate': DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      };
      final res  = await ApiClient.get('/income', params: params);
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        for (final key in ['income', 'incomes', 'data', 'items', 'results']) {
          if (data[key] is List) { list = data[key]; break; }
        }
      }
      final fetched = <Income>[];
      for (final e in list) {
        try { fetched.add(Income.fromJson(Map<String, dynamic>.from(e))); }
        catch (_) {}
      }
      if (mounted) setState(() => _incomes = fetched);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load income: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(Income inc) async {
    try {
      await ApiClient.delete('/income/${inc.id}');
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
          Text(isNew ? 'Income added successfully' : 'Income updated successfully'),
        ]),
        backgroundColor: AppTheme.success,
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

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.success,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditIncomeScreen()));
          if (result != null) {
            _showSavedSnackbar(isNew: true);
            await _load();
            if (result is String) _flashHighlight(result);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Search bar / filter row ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showFilterSheet,
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
                          const Icon(Icons.filter_list,
                              color: AppTheme.textSecondary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedSource != null
                                  ? 'Source: $_selectedSource'
                                  : 'Filter by source or date...',
                              style: TextStyle(
                                color: _selectedSource != null
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_selectedSource != null || _dateRange != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSource = null;
                                  _dateRange = null;
                                });
                                _load();
                              },
                              child: const Icon(Icons.close,
                                  size: 18, color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active filters chips
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(children: [
                Chip(
                  label: Text(
                      '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}'),
                  onDeleted: () {
                    setState(() => _dateRange = null);
                    _load();
                  },
                ),
              ]),
            ),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _incomes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.savings_outlined,
                                size: 64,
                                color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            const Text('No income entries',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary)),
                            const SizedBox(height: 6),
                            const Text('Tap + to log your first income',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _incomes.length,
                          itemBuilder: (ctx, i) {
                            final inc     = _incomes[i];
                            final color   = _sourceColors[inc.source] ?? const Color(0xFF8A8D9A);
                            final icon    = _sourceIcons[inc.source] ?? Icons.attach_money;
                            final isHigh  = _highlightedId == inc.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Dismissible(
                                key: Key(inc.id.isNotEmpty
                                    ? inc.id
                                    : inc.hashCode.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async =>
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete income?'),
                                    content: Text(
                                        'Remove "${inc.description}" permanently?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel')),
                                      FilledButton(
                                          style: FilledButton.styleFrom(
                                              backgroundColor: AppTheme.danger),
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('Delete')),
                                    ],
                                  ),
                                ),
                                onDismissed: (_) => _delete(inc),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isHigh
                                          ? AppTheme.success.withValues(alpha: 0.4)
                                          : AppTheme.fieldBorder,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  EditIncomeScreen(income: inc)));
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(icon,
                                                size: 22, color: color),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(inc.description,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppTheme.primary),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Row(children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 7,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(
                                                          alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      inc.source,
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: color,
                                                          letterSpacing: 0.3),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      formatDate(inc.date),
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme
                                                              .textSecondary),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ]),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            formatCurrency(
                                                inc.amount, inc.currency),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.success),
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
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    String? tmpSource = _selectedSource;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                  if (tmpSource != null || _dateRange != null)
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedSource = null;
                            _dateRange      = null;
                          });
                          _load();
                        },
                        child: const Text('Clear all')),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: tmpSource,
                decoration: const InputDecoration(
                    labelText: 'Source',
                    prefixIcon: Icon(Icons.category_outlined, size: 18)),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Sources')),
                  ..._sources.map((s) => DropdownMenuItem(
                      value: s, child: Text(s))),
                ],
                onChanged: (v) => setS(() => tmpSource = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_dateRange == null
                    ? 'Pick Date Range'
                    : '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(ctx);
                  _pickDateRange();
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() => _selectedSource = tmpSource);
                  Navigator.pop(ctx);
                  _load();
                },
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
