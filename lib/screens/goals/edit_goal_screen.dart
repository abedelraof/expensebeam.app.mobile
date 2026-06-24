import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/goal.dart';
import '../../core/theme/app_theme.dart';

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
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameCtrl    = TextEditingController(text: g?.name ?? '');
    _targetCtrl  = TextEditingController(text: g != null ? g.targetAmount.toString() : '');
    _currentCtrl = TextEditingController(text: g != null ? g.currentAmount.toString() : '0');
    _targetDate  = g?.targetDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _targetDate = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'targetAmount': double.parse(_targetCtrl.text.trim()),
        'currentAmount': double.tryParse(_currentCtrl.text.trim()) ?? 0,
        if (_targetDate != null) 'targetDate': _targetDate!.toIso8601String(),
      };
      if (widget.goal == null) {
        await ApiClient.post('/goals', data: data);
      } else {
        await ApiClient.put('/goals/${widget.goal!.id}', data: data);
      }
      if (mounted) Navigator.pop(context, true);
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
    final isNew = widget.goal == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Add Goal' : 'Edit Goal',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
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
            // ── Goal Name ──────────────────────────────────────────────────
            _label('Goal Name'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDec(
                hint: 'e.g. New Laptop, Emergency Fund',
                icon: Icons.flag_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // ── Target Amount ──────────────────────────────────────────────
            _label('Target Amount'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDec(
                hint: '0.00',
                icon: Icons.attach_money,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Current Amount ─────────────────────────────────────────────
            _label('Current Amount Saved'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDec(
                hint: '0.00',
                icon: Icons.savings_outlined,
              ),
            ),
            const SizedBox(height: 14),

            // ── Target Date ────────────────────────────────────────────────
            _label('Target Date'),
            const SizedBox(height: 4),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _inputDec(
                  hint: 'Optional',
                  icon: Icons.calendar_today_outlined,
                  suffix: _targetDate != null
                      ? GestureDetector(
                          onTap: () => setState(() => _targetDate = null),
                          child: const Icon(Icons.close,
                              size: 16, color: AppTheme.textSecondary),
                        )
                      : const Icon(Icons.chevron_right,
                          color: AppTheme.textSecondary, size: 18),
                ),
                child: Text(
                  _targetDate != null
                      ? DateFormat('EEE, MMM d yyyy').format(_targetDate!)
                      : 'No target date',
                  style: TextStyle(
                      fontSize: 14,
                      color: _targetDate != null
                          ? AppTheme.primary
                          : AppTheme.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Save button ────────────────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(isNew ? 'Add Goal' : 'Save Changes'),
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
}
