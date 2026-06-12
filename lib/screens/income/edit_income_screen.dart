import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/income.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shake_widget.dart';

class EditIncomeScreen extends StatefulWidget {
  final Income? income;
  const EditIncomeScreen({super.key, this.income});

  @override
  State<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
  final _formKey    = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _notesCtrl;
  String   _source = 'Salary';
  DateTime _date   = DateTime.now();
  bool     _saving = false;

  final _amountShake = ShakeController();
  final _descShake   = ShakeController();

  static const _sources = [
    'Salary', 'Business', 'Freelance', 'Investment', 'Rental', 'Gift', 'Other',
  ];

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
    final inc   = widget.income;
    _amountCtrl = TextEditingController(text: inc != null ? inc.amount.toString() : '');
    _descCtrl   = TextEditingController(text: inc?.description ?? '');
    _notesCtrl  = TextEditingController(text: inc?.notes ?? '');
    _source     = inc?.source ?? 'Salary';
    _date       = inc?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) {
      if (_amountCtrl.text.trim().isEmpty ||
          double.tryParse(_amountCtrl.text.trim()) == null) {
        _amountShake.shake();
      }
      if (_descCtrl.text.trim().isEmpty) _descShake.shake();
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'amount':      double.parse(_amountCtrl.text.trim()),
        'currency':    widget.income?.currency ?? 'EGP',
        'source':      _source,
        'description': _descCtrl.text.trim(),
        'date':        DateFormat('yyyy-MM-dd').format(_date),
        'notes':       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };
      dynamic res;
      if (widget.income == null) {
        res = await ApiClient.post('/income', data: {'incomes': [data]});
      } else {
        res = await ApiClient.put('/income/${widget.income!.id}', data: data);
      }
      if (mounted) {
        final savedId = widget.income?.id ??
            (res?.data is Map
                ? (res.data['id'] ?? res.data['_id'])?.toString()
                : null);
        Navigator.pop(context, savedId ?? true);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        try {
          final dio = e as dynamic;
          final body = dio.response?.data;
          if (body is Map) {
            msg = body['message'] ?? body['error'] ?? body.toString();
          } else if (body != null) {
            msg = body.toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.income == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Add Income' : 'Edit Income',
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

            // ── Amount ───────────────────────────────────────────────────
            _label('Amount'),
            const SizedBox(height: 4),
            ShakeWidget(
              controller: _amountShake,
              child: TextFormField(
                controller: _amountCtrl,
                autofocus: false,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDec(
                  hint: '0.00',
                  icon: Icons.attach_money,
                  suffix: Text(
                    widget.income?.currency ?? 'EGP',
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

            // ── Date ─────────────────────────────────────────────────────
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

            // ── Source ───────────────────────────────────────────────────
            _label('Source'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _source,
              decoration: _inputDec(
                  hint: 'Select source',
                  icon: _sourceIcons[_source] ?? Icons.attach_money),
              isExpanded: true,
              items: _sources.map((s) => DropdownMenuItem(
                value: s,
                child: Row(
                  children: [
                    Icon(_sourceIcons[s] ?? Icons.attach_money,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(s),
                  ],
                ),
              )).toList(),
              onChanged: (v) => setState(() => _source = v!),
            ),
            const SizedBox(height: 14),

            // ── Description ──────────────────────────────────────────────
            _label('Description'),
            const SizedBox(height: 4),
            ShakeWidget(
              controller: _descShake,
              child: TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDec(
                    hint: 'e.g. Monthly salary, Freelance project',
                    icon: Icons.edit_outlined),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
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
                  hint: 'Optional notes...', icon: Icons.notes_outlined),
            ),
            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppTheme.success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(isNew ? 'Add Income' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
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
