import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/account.dart';
import '../../core/theme/app_theme.dart';

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
    'cash', 'bank', 'investment', 'credit', 'loan', 'commodity', 'monetary', 'other'
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl     = TextEditingController(text: a?.name ?? '');
    _balanceCtrl  = TextEditingController(text: a?.balance.toString() ?? '0');
    _currencyCtrl = TextEditingController(text: a?.currency ?? 'EGP');
    _quantityCtrl = TextEditingController(text: a?.quantity?.toString() ?? '');
    _priceCtrl    = TextEditingController(text: a?.pricePerUnit?.toString() ?? '');
    _type         = (_types.contains(a?.type) ? a?.type : null) ?? 'cash';
    _isLiability  = a?.isLiability ?? false;
    _isCommodity  = a?.quantity != null;
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
    final isNew = widget.account == null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Add Account' : 'Edit Account',
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

            // ── Account Name ─────────────────────────────────────────────
            _label('Account Name'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDec(hint: 'e.g. CIB, Wallet, Gold', icon: Icons.account_balance_wallet_outlined),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // ── Type ─────────────────────────────────────────────────────
            _label('Type'),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _inputDec(hint: 'Select type', icon: Icons.category_outlined),
              isExpanded: true,
              items: _types.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t[0].toUpperCase() + t.substring(1)),
              )).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 14),

            // ── Currency ─────────────────────────────────────────────────
            _label('Currency'),
            const SizedBox(height: 4),
            TextFormField(
              controller: _currencyCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDec(hint: 'e.g. EGP, USD', icon: Icons.currency_exchange_outlined),
            ),
            const SizedBox(height: 14),

            // ── Balance (non-commodity only) ──────────────────────────────
            if (!_isCommodity) ...[
              _label('Balance'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDec(
                  hint: '0.00',
                  icon: Icons.attach_money,
                  suffix: Text(
                    _currencyCtrl.text.trim().toUpperCase().isEmpty
                        ? 'EGP'
                        : _currencyCtrl.text.trim().toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Toggles ───────────────────────────────────────────────────
            _label('Options'),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Liability (debt / credit card)',
                        style: TextStyle(fontSize: 14)),
                    value: _isLiability,
                    onChanged: (v) => setState(() => _isLiability = v),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Divider(height: 1, color: AppTheme.textSecondary.withValues(alpha: 0.15)),
                  SwitchListTile(
                    title: const Text('Commodity (gold, stocks…)',
                        style: TextStyle(fontSize: 14)),
                    value: _isCommodity,
                    onChanged: (v) => setState(() => _isCommodity = v),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ],
              ),
            ),

            // ── Commodity fields ──────────────────────────────────────────
            if (_isCommodity) ...[
              const SizedBox(height: 14),
              _label('Quantity (units)'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDec(hint: 'e.g. 10.5', icon: Icons.scale_outlined),
              ),
              const SizedBox(height: 14),
              _label('Price per unit'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDec(hint: 'e.g. 3200.00', icon: Icons.price_change_outlined),
              ),
            ],

            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(isNew ? 'Add Account' : 'Save Changes'),
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
