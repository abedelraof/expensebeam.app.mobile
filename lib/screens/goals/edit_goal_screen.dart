import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/goal.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal? goal;
  const EditGoalScreen({super.key, this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  late final TextEditingController _currencyCtrl;
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _targetCtrl =
        TextEditingController(text: g?.targetAmount.toString() ?? '');
    _currentCtrl =
        TextEditingController(text: g?.currentAmount.toString() ?? '0');
    _currencyCtrl = TextEditingController(text: g?.targetCurrency ?? 'EGP');
    _targetDate = g?.targetDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'targetAmount': double.parse(_targetCtrl.text),
        'currentAmount': double.tryParse(_currentCtrl.text) ?? 0,
        'currency': _currencyCtrl.text.trim().toUpperCase(),
        if (_targetDate != null)
          'targetDate': _targetDate!.toIso8601String(),
      };
      if (widget.goal == null) {
        await ApiClient.post('/goals', data: data);
      } else {
        await ApiClient.put('/goals/${widget.goal!.id}', data: data);
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
      initialDate: _targetDate ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _targetDate = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Add Goal' : 'Edit Goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Goal Name'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _targetCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Target Amount'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _currencyCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Currency'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Current Amount'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Target Date (optional)'),
              subtitle: Text(_targetDate != null
                  ? DateFormat('MMM d, yyyy').format(_targetDate!)
                  : 'Not set'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_targetDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _targetDate = null),
                  ),
                const Icon(Icons.calendar_today),
              ]),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.goal == null ? 'Add Goal' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
