import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/expense.dart';
import '../../core/theme/app_theme.dart';

class _Category {
  final String name;
  final List<String> subcategories;
  const _Category({required this.name, required this.subcategories});
}

class EditExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const EditExpenseScreen({super.key, this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  DateTime _date   = DateTime.now();
  bool _saving     = false;

  // Category state
  List<_Category> _categories      = [];
  bool _catsLoading                = true;
  String? _selectedCategory;
  String? _selectedSubcategory;

  @override
  void initState() {
    super.initState();
    final e      = widget.expense;
    _descCtrl    = TextEditingController(text: e?.description ?? '');
    _amountCtrl  = TextEditingController(text: e != null ? e.amount.toString() : '');
    _notesCtrl   = TextEditingController(text: e?.notes ?? '');
    _date        = e?.date ?? DateTime.now();
    _selectedCategory    = e?.category;
    _selectedSubcategory = e?.subcategory;
    _loadCategories();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res  = await ApiClient.get('/categories');
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) list = data;
      else if (data is Map) {
        for (final key in ['categories', 'data', 'items']) {
          if (data[key] is List) { list = data[key]; break; }
        }
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
    } catch (_) {}
    finally {
      if (mounted) setState(() => _catsLoading = false);
    }
  }

  _Category? get _selectedCat {
    if (_selectedCategory == null) return null;
    try { return _categories.firstWhere((c) => c.name == _selectedCategory); }
    catch (_) { return null; }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'description': _descCtrl.text.trim(),
        'amount':      double.parse(_amountCtrl.text.trim()),
        'currency':    widget.expense?.currency ?? 'EGP',
        'category':    _selectedCategory,
        'subcategory': _selectedSubcategory,
        'date':        _date.toIso8601String(),
        'notes':       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };
      dynamic res;
      if (widget.expense == null) {
        res = await ApiClient.post('/expenses', data: data);
      } else {
        res = await ApiClient.put('/expenses/${widget.expense!.id}', data: data);
      }
      if (mounted) {
        // Return the saved ID so the list can highlight it
        final savedId = widget.expense?.id ??
            (res?.data is Map
                ? (res.data['id'] ?? res.data['_id'])?.toString()
                : null);
        Navigator.pop(context, savedId ?? true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isNew  = widget.expense == null;
    final selCat = _selectedCat;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Add Expense' : 'Edit Expense',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isNew ? 'Add' : 'Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [

            // ── Description ─────────────────────────────────────────────
            _label('Description'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDec(
                hint: 'e.g. Coffee, Uber, Groceries',
                icon: Icons.edit_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // ── Amount ──────────────────────────────────────────────────
            _label('Amount'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDec(
                hint: '0.00',
                icon: Icons.attach_money,
                suffix: Text(
                  widget.expense?.currency ?? 'EGP',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Date ────────────────────────────────────────────────────
            _label('Date'),
            const SizedBox(height: 4),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _inputDec(
                  hint: '',
                  icon: Icons.calendar_today_outlined,
                  suffix: const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary, size: 18),
                ),
                child: Text(
                  DateFormat('EEE, MMM d yyyy').format(_date),
                  style: const TextStyle(fontSize: 14, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Category ────────────────────────────────────────────────
            _label('Category'),
            const SizedBox(height: 4),
            _catsLoading
                ? _loadingField('Loading categories...')
                : DropdownButtonFormField<String>(
                    value: _categories.any((c) => c.name == _selectedCategory)
                        ? _selectedCategory
                        : null,
                    decoration: _inputDec(
                        hint: 'Select a category',
                        icon: Icons.category_outlined),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                          value: null,
                          child: Text('— None —',
                              style: TextStyle(color: AppTheme.textSecondary))),
                      ..._categories.map((c) => DropdownMenuItem(
                          value: c.name, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() {
                      _selectedCategory    = v;
                      _selectedSubcategory = null;
                    }),
                  ),
            const SizedBox(height: 14),

            // ── Subcategory ─────────────────────────────────────────────
            if (!_catsLoading) ...[
              _label('Subcategory'),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: selCat != null &&
                        selCat.subcategories.contains(_selectedSubcategory)
                    ? _selectedSubcategory
                    : null,
                decoration: _inputDec(
                    hint: selCat == null
                        ? 'Select a category first'
                        : selCat.subcategories.isEmpty
                            ? 'No subcategories'
                            : 'Select a subcategory',
                    icon: Icons.subdirectory_arrow_right),
                isExpanded: true,
                items: selCat == null || selCat.subcategories.isEmpty
                    ? [
                        const DropdownMenuItem(
                            value: null,
                            child: Text('— None —',
                                style:
                                    TextStyle(color: AppTheme.textSecondary)))
                      ]
                    : [
                        const DropdownMenuItem(
                            value: null,
                            child: Text('— None —',
                                style:
                                    TextStyle(color: AppTheme.textSecondary))),
                        ...selCat.subcategories.map((s) =>
                            DropdownMenuItem(value: s, child: Text(s))),
                      ],
                onChanged: selCat == null || selCat.subcategories.isEmpty
                    ? null
                    : (v) => setState(() => _selectedSubcategory = v),
              ),
              const SizedBox(height: 14),
            ],

            // ── Notes ───────────────────────────────────────────────────
            _label('Notes'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDec(
                hint: 'Optional notes...',
                icon: Icons.notes_outlined,
              ),
            ),
            const SizedBox(height: 24),

            // ── Save button (bottom) ─────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(isNew ? 'Add Expense' : 'Save Changes'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary),
      );

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffix,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      );

  Widget _loadingField(String hint) => InputDecorator(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.category_outlined,
              size: 18, color: AppTheme.textSecondary),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent)),
          ),
        ),
        child: Text(hint,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14)),
      );
}
