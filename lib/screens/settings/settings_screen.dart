import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  final _apiKeyCtrl = TextEditingController();
  String _selectedCurrency = 'EGP';

  static const _currencies = [
    'EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED', 'JOD', 'KWD', 'QAR', 'BHD',
    'TRY', 'CAD', 'AUD', 'CHF', 'CNY', 'JPY', 'INR',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/settings');
      final data = res.data is Map
          ? Map<String, dynamic>.from(res.data)
          : <String, dynamic>{};
      final c = data['currency'] ?? 'EGP';
      _selectedCurrency = _currencies.contains(c) ? c : 'EGP';
      _apiKeyCtrl.text = data['claudeApiKey'] ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    try {
      await ApiClient.put('/settings', data: {
        'currency': _selectedCurrency,
        'claudeApiKey': _apiKeyCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null) return;
    try {
      await ApiClient.post('/import/csv',
          data: {'filePath': result.files.single.path});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV imported successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('Profile', [
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Home Currency',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: _currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Profile')),
                ]),
                const SizedBox(height: 16),
                _section('AI', [
                  TextFormField(
                    controller: _apiKeyCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Claude API Key',
                      prefixIcon: Icon(Icons.key),
                      hintText: 'sk-ant-...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: _saveSettings,
                      child: const Text('Save API Key')),
                ]),
                const SizedBox(height: 16),
                _section('More', [
                  _navTile('Categories', Icons.category, () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()))),
                ]),
                const SizedBox(height: 16),
                _section('Data', [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Import CSV'),
                    subtitle:
                        const Text('Import expenses from a CSV file'),
                    onTap: _importCsv,
                  ),
                ]),
                const SizedBox(height: 16),
                _section('Account', [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout,
                        color: Theme.of(context).colorScheme.error),
                    title: Text('Sign Out',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign out?'),
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.15),
                                        foregroundColor: AppTheme.textSecondary),
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Ok'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) await auth.logout();
                    },
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children),
            ),
          ),
        ],
      );

  Widget _navTile(String title, IconData icon, VoidCallback onTap) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
