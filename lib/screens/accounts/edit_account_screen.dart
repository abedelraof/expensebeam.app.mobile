import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/account.dart';

class EditAccountScreen extends StatefulWidget {
  final Account? account;
  const EditAccountScreen({super.key, this.account});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _priceCtrl;
  String _type = 'cash';
  bool _isLiability = false;
  bool _isCommodity = false;
  bool _saving = false;

  static const _types = [
    'cash', 'bank', 'investment', 'credit', 'loan', 'commodity', 'other'
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _balanceCtrl =
        TextEditingController(text: a?.balance.toString() ?? '0');
    _currencyCtrl = TextEditingController(text: a?.currency ?? 'EGP');
    _quantityCtrl =
        TextEditingController(text: a?.quantity?.toString() ?? '');
    _priceCtrl =
        TextEditingController(text: a?.pricePerUnit?.toString() ?? '');
    _type = a?.type ?? 'cash';
    _isLiability = a?.isLiability ?? false;
    _isCommodity = a?.quantity != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _currencyCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'currency': _currencyCtrl.text.trim().toUpperCase(),
        'balance': double.tryParse(_balanceCtrl.text) ?? 0,
        'isLiability': _isLiability,
        if (_isCommodity && _quantityCtrl.text.isNotEmpty)
          'quantity': double.parse(_quantityCtrl.text),
        if (_isCommodity && _priceCtrl.text.isNotEmpty)
          'pricePerUnit': double.parse(_priceCtrl.text),
      };
      if (widget.account == null) {
        await ApiClient.post('/accounts', data: data);
      } else {
        await ApiClient.put('/accounts/${widget.account!.id}', data: data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.account == null ? 'Add Account' : 'Edit Account'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Account Name'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _types
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currencyCtrl,
              decoration: const InputDecoration(labelText: 'Currency'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Is Liability (debt)'),
              value: _isLiability,
              onChanged: (v) => setState(() => _isLiability = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Commodity (gold, stocks...)'),
              value: _isCommodity,
              onChanged: (v) => setState(() => _isCommodity = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isCommodity) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Quantity (units)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Price per unit'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Balance'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.account == null ? 'Add Account' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
