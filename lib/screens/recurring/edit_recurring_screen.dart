import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/recurring.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shake_widget.dart';

class _Category {
  final String name;
  final List<String> subcategories;
  const _Category({required this.name, required this.subcategories});
}

class EditRecurringScreen extends StatefulWidget {
  final Recurring? recurring;
  const EditRecurringScreen({super.key, this.recurring});

  @override
  State<EditRecurringScreen> createState() => _EditRecurringScreenState();
}

class _EditRecurringScreenState extends State<EditRecurringScreen> {
  final _formKey    = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  String   _interval = 'monthly';
  DateTime _nextDue  = DateTime.now().add(const Duration(days: 30));
  bool     _saving   = false;

  // Category state
  List<_Category> _categories     = [];
  bool _catsLoading               = true;
  String? _selectedCategory;
  String? _selectedSubcategory;

  final _descShake   = ShakeController();
  final _amountShake = ShakeController();

  @override
  void initState() {
    super.initState();
    final r     = widget.recurring;
    _descCtrl   = TextEditingController(text: r?.description ?? '');
    _amountCtrl = TextEditingController(text: r != null ? r.amount.toString() : '');
    _notesCtrl  = TextEditingController();
    _interval           = r?.interval ?? 'monthly';
    _nextDue            = r?.nextDue ?? DateTime.now().add(const Duration(days: 30));
    _selectedCategory   = r?.category;
    _loadCategories();
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

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _nextDue,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d != null) setState(() => _nextDue = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      if (_descCtrl.text.trim().isEmpty) _descShake.shake();
      if (_amountCtrl.text.trim().isEmpty ||
          double.tryParse(_amountCtrl.text.trim()) == null) {
        _amountShake.shake();
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'description': _descCtrl.text.trim(),
        'amount':      double.parse(_amountCtrl.text.trim()),
        'currency':    widget.recurring?.currency ?? 'EGP',
        'interval':    _interval,
        'nextDue':     _nextDue.toIso8601String(),
        'category':    _selectedCategory,
        'subcategory': _selectedSubcategory,
        'notes':       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };
      dynamic res;
      if (widget.recurring == null) {
        res = await ApiClient.post('/recurring', data: data);
      } else {
        res = await ApiClient.put('/recurring/${widget.recurring!.id}', data: data);
      }
      if (mounted) {
        final savedId = widget.recurring?.id ??
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
    final isNew = widget.recurring == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Add Recurring' : 'Edit Recurring',
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
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

            // ── Description ──────────────────────────────────────────────
            _label('Description'),
            const SizedBox(height: 4),
            ShakeWidget(
              controller: _descShake,
              child: TextFormField(
                controller: _descCtrl,
                autofocus: false,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDec(
                    hint: 'e.g. Netflix, Rent, Gym',
                    icon: Icons.edit_outlined),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 14),

            // ── Amount ───────────────────────────────────────────────────
            _label('Amount'),
            const SizedBox(height: 4),
            ShakeWidget(
              controller: _amountShake,
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDec(
                  hint: '0.00',
                  icon: Icons.attach_money,
                  suffix: Text(
                    widget.recurring?.currency ?? 'EGP',
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
            ),
            const SizedBox(height: 14),

            // ── Next Due Date ────────────────────────────────────────────
            _label('Next Due Date'),
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
                  DateFormat('EEE, MMM d yyyy').format(_nextDue),
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Repeat Interval ──────────────────────────────────────────
            _label('Repeat Interval'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _interval,
              decoration: _inputDec(
                  hint: 'Select interval', icon: Icons.repeat_outlined),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'daily',   child: Text('Daily')),
                DropdownMenuItem(value: 'weekly',  child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly',  child: Text('Yearly')),
              ],
              onChanged: (v) => setState(() => _interval = v!),
            ),
            const SizedBox(height: 14),

            // ── Category ─────────────────────────────────────────────────
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
                      ..._categories.map((c) =>
                          DropdownMenuItem(value: c.name, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() {
                      _selectedCategory    = v;
                      _selectedSubcategory = null;
                    }),
                  ),
            const SizedBox(height: 14),

            // ── Subcategory ───────────────────────────────────────────────
            _label('Subcategory'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _selectedCat != null &&
                      _selectedCat!.subcategories.contains(_selectedSubcategory)
                  ? _selectedSubcategory
                  : null,
              decoration: _inputDec(
                  hint: _selectedCat == null
                      ? 'Select a category first'
                      : _selectedCat!.subcategories.isEmpty
                          ? 'No subcategories'
                          : 'Select a subcategory',
                  icon: Icons.subdirectory_arrow_right),
              isExpanded: true,
              items: _selectedCat == null || _selectedCat!.subcategories.isEmpty
                  ? [const DropdownMenuItem(
                      value: null,
                      child: Text('— None —',
                          style: TextStyle(color: AppTheme.textSecondary)))]
                  : [
                      const DropdownMenuItem(
                          value: null,
                          child: Text('— None —',
                              style: TextStyle(color: AppTheme.textSecondary))),
                      ..._selectedCat!.subcategories.map((s) =>
                          DropdownMenuItem(value: s, child: Text(s))),
                    ],
              onChanged: _selectedCat == null || _selectedCat!.subcategories.isEmpty
                  ? null
                  : (v) => setState(() => _selectedSubcategory = v),
            ),
            const SizedBox(height: 14),

            // ── Notes ────────────────────────────────────────────────────
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

            // ── Save button ───────────────────────────────────────────────
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
                  : Text(isNew ? 'Add Recurring' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary),
      );

  Widget _loadingField(String hint) => InputDecorator(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.category_outlined,
              size: 18, color: AppTheme.textSecondary),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent)),
          ),
        ),
        child: Text(hint,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14)),
      );

  InputDecoration _inputDec(
          {required String hint, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
      );
}
