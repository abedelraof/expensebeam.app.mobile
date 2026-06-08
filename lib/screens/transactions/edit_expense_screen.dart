import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/expense.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const EditExpenseScreen({super.key, this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _categoryCtrl;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _amountCtrl = TextEditingController(text: e?.amount.toString() ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _currencyCtrl = TextEditingController(text: e?.currency ?? 'EGP');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _currencyCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'description': _descCtrl.text.trim(),
        'amount': double.parse(_amountCtrl.text),
        'currency': _currencyCtrl.text.trim().toUpperCase(),
        'category': _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        'date': _date.toIso8601String(),
        'notes': _notesCtrl.text.trim(),
      };
      if (widget.expense == null) {
        await ApiClient.post('/expenses', data: data);
      } else {
        await ApiClient.put('/expenses/${widget.expense!.id}', data: data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _currencyCtrl,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration:
                  const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.expense == null
                      ? 'Add Expense'
                      : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
