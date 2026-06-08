import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

// ── Local category model ──────────────────────────────────────────────────────
class _Category {
  final String name;
  final List<String> subcategories;
  const _Category({required this.name, required this.subcategories});
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ConfirmExpensesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> expenses;
  const ConfirmExpensesScreen({super.key, required this.expenses});

  @override
  State<ConfirmExpensesScreen> createState() => _ConfirmExpensesScreenState();
}

class _ConfirmExpensesScreenState extends State<ConfirmExpensesScreen> {
  late List<_ExpenseForm> _forms;
  bool _submitting      = false;
  List<_Category> _categories = [];
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _forms = widget.expenses.map((e) => _ExpenseForm.fromParsed(e)).toList();
    _loadCategories();
  }

  @override
  void dispose() {
    for (final f in _forms) f.dispose();
    super.dispose();
  }

  // ── Load categories from API ──────────────────────────────────────────
  Future<void> _loadCategories() async {
    try {
      final res  = await ApiClient.get('/categories');
      final data = res.data;

      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        final val = data['categories'] ?? data['data'] ?? data['items'];
        if (val is List) list = val;
      }

      final parsed = <_Category>[];
      for (final item in list) {
        if (item is! Map) continue;
        final name = item['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final subs = (item['subcategories'] as List? ?? [])
            .map((s) => (s is Map ? s['name'] : s).toString())
            .where((s) => s.isNotEmpty)
            .toList();
        parsed.add(_Category(name: name, subcategories: subs));
      }

      if (mounted) setState(() => _categories = parsed);
    } catch (_) {
      // Non-fatal — dropdowns will be empty but form still works
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  // ── Submit all ────────────────────────────────────────────────────────
  Future<void> _submitAll() async {
    // Validate all forms — skip if formKey has no state yet
    bool allValid = true;
    for (final f in _forms) {
      final state = f.formKey.currentState;
      if (state != null && !state.validate()) allValid = false;
    }
    if (!allValid) return;

    setState(() => _submitting = true);

    // Build the expenses array
    final expensesList = <Map<String, dynamic>>[];
    for (final f in _forms) {
      final amount = double.tryParse(f.amountCtrl.text.trim());
      if (amount == null) continue;
      expensesList.add({
        'description': f.descCtrl.text.trim(),
        'amount':      amount,
        'currency':    f.currency.toUpperCase(),
        'category':    (f.category?.trim().isEmpty ?? true) ? null : f.category,
        'date':        f.date.toIso8601String(),
        'notes':       '',
        if (f.subcategory != null && f.subcategory!.isNotEmpty)
          'subcategory': f.subcategory,
      });
    }

    try {
      await ApiClient.post('/expenses', data: {'expenses': expensesList});
      setState(() => _submitting = false);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      String msg;
      if (e is DioException && e.response != null) {
        final body = e.response!.data;
        msg = body is Map
            ? (body['message'] ?? body['error'] ?? body.toString())
            : body.toString();
      } else {
        msg = e.toString();
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Failed to add expenses'),
          content: Text(msg),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('Review Expenses (${_forms.length})'),
        actions: [
          if (_forms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _submitting ? null : _submitAll,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Add All'),
              ),
            ),
        ],
      ),
      body: _forms.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('All expenses removed.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: _forms.length,
              itemBuilder: (_, i) => _ExpenseCard(
                key: ValueKey(i),
                form: _forms[i],
                index: i,
                categories: _categories,
                categoriesLoading: _categoriesLoading,
                onDelete: () => setState(() {
                  _forms[i].dispose();
                  _forms.removeAt(i);
                }),
                onChanged: () => setState(() {}),
              ),
            ),
      bottomNavigationBar: _forms.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submitAll,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_submitting
                      ? 'Adding ${_forms.length} expenses...'
                      : 'Add ${_forms.length} Expense${_forms.length > 1 ? 's' : ''}'),
                ),
              ),
            ),
    );
  }
}

// ── Expense form state ────────────────────────────────────────────────────────
class _ExpenseForm {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController amountCtrl;
  final TextEditingController descCtrl;
  String  currency;
  String? category;
  String? subcategory;
  DateTime date;

  _ExpenseForm({
    required String amount,
    required String description,
    required this.currency,
    this.category,
    this.subcategory,
    required this.date,
  })  : amountCtrl = TextEditingController(text: amount),
        descCtrl   = TextEditingController(text: description);

  factory _ExpenseForm.fromParsed(Map<String, dynamic> data) {
    DateTime date = DateTime.now();
    final rawDate = data['date'];
    if (rawDate != null) date = DateTime.tryParse(rawDate.toString()) ?? date;

    return _ExpenseForm(
      amount:      (data['amount'] ?? data['total'] ?? '').toString(),
      description: (data['description'] ?? data['name'] ?? data['title'] ?? '').toString(),
      currency:    (data['currency'] ?? 'EGP').toString(),
      category:    data['category']?.toString(),
      subcategory: data['subcategory']?.toString(),
      date:        date,
    );
  }

  void dispose() {
    amountCtrl.dispose();
    descCtrl.dispose();
  }
}

// ── Individual expense card ───────────────────────────────────────────────────
class _ExpenseCard extends StatefulWidget {
  final _ExpenseForm form;
  final int index;
  final List<_Category> categories;
  final bool categoriesLoading;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _ExpenseCard({
    super.key,
    required this.form,
    required this.index,
    required this.categories,
    required this.categoriesLoading,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<_ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<_ExpenseCard> {
  bool _expanded = true;
  static const _currencies = ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED'];

  _Category? get _selectedCategory {
    if (widget.form.category == null) return null;
    try {
      return widget.categories
          .firstWhere((c) => c.name == widget.form.category);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.form.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => widget.form.date = picked);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final f    = widget.form;
    final selC = _selectedCategory;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.fieldBorder),
      ),
      elevation: 0,
      child: Form(
        key: f.formKey,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            InkWell(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('${widget.index + 1}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.descCtrl.text.isEmpty
                                ? 'Expense ${widget.index + 1}'
                                : f.descCtrl.text,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              if (f.amountCtrl.text.isNotEmpty)
                                '${f.amountCtrl.text} ${f.currency}',
                              if (f.category != null) f.category!,
                              if (f.subcategory != null) f.subcategory!,
                            ].join(' · '),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.danger, size: 20),
                      onPressed: widget.onDelete,
                      tooltip: 'Remove',
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // ── Form body ────────────────────────────────────────────────
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Amount
                    TextFormField(
                      controller: f.amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money, size: 18),
                      ),
                      onChanged: (_) => widget.onChanged(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Category dropdown
                    widget.categoriesLoading
                        ? const _LoadingField(label: 'Category')
                        : DropdownButtonFormField<String>(
                            value: widget.categories
                                    .any((c) => c.name == f.category)
                                ? f.category
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(
                                  Icons.category_outlined,
                                  size: 18),
                            ),
                            hint: const Text('Select category'),
                            items: [
                              const DropdownMenuItem(
                                  value: null,
                                  child: Text('— None —',
                                      style: TextStyle(
                                          color:
                                              AppTheme.textSecondary))),
                              ...widget.categories.map((c) =>
                                  DropdownMenuItem(
                                      value: c.name,
                                      child: Text(c.name))),
                            ],
                            onChanged: (v) {
                              setState(() {
                                f.category   = v;
                                f.subcategory = null; // reset
                              });
                              widget.onChanged();
                            },
                          ),
                    const SizedBox(height: 12),

                    // Subcategory dropdown — only if selected category has subs
                    if (!widget.categoriesLoading &&
                        selC != null &&
                        selC.subcategories.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: selC.subcategories.contains(f.subcategory)
                            ? f.subcategory
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Subcategory',
                          prefixIcon: Icon(Icons.subdirectory_arrow_right,
                              size: 18),
                        ),
                        hint: const Text('Select subcategory'),
                        items: [
                          const DropdownMenuItem(
                              value: null,
                              child: Text('— None —',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary))),
                          ...selC.subcategories.map((s) =>
                              DropdownMenuItem(
                                  value: s, child: Text(s))),
                        ],
                        onChanged: (v) {
                          setState(() => f.subcategory = v);
                          widget.onChanged();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Date picker
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(
                              Icons.calendar_today_outlined,
                              size: 18),
                        ),
                        child: Text(
                          '${f.date.day}/${f.date.month}/${f.date.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description — multiline textarea
                    TextFormField(
                      controller: f.descCtrl,
                      maxLines: 3,
                      minLines: 2,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.edit_outlined, size: 18),
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) => widget.onChanged(),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading placeholder field ─────────────────────────────────────────────────
class _LoadingField extends StatelessWidget {
  final String label;
  const _LoadingField({required this.label});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.category_outlined, size: 18),
        suffixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.accent),
          ),
        ),
      ),
      child: const Text('Loading...',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
    );
  }
}
