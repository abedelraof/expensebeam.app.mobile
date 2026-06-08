import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../income/income_screen.dart';
import '../goals/goals_screen.dart';
import '../recurring/recurring_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  final _apiKeyCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/settings');
      final data = res.data is Map
          ? Map<String, dynamic>.from(res.data)
          : <String, dynamic>{};
      _currencyCtrl.text = data['currency'] ?? 'EGP';
      _apiKeyCtrl.text = data['claudeApiKey'] ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    try {
      await ApiClient.put('/settings', data: {
        'currency': _currencyCtrl.text.trim().toUpperCase(),
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
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('Profile', [
                  TextFormField(
                    controller: _currencyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Home Currency',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Profile')),
                ]),
                const SizedBox(height: 16),
                _section('Theme', [
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('System default'),
                    value: ThemeMode.system,
                    groupValue: themeProvider.mode,
                    onChanged: (v) => themeProvider.setMode(v!),
                  ),
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: themeProvider.mode,
                    onChanged: (v) => themeProvider.setMode(v!),
                  ),
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.mode,
                    onChanged: (v) => themeProvider.setMode(v!),
                  ),
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
                  _navTile('Income', Icons.attach_money, () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen()))),
                  _navTile('Savings Goals', Icons.savings, () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()))),
                  _navTile('Recurring Expenses', Icons.repeat, () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()))),
                  _navTile('Categories', Icons.category, () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen()))),
                  _navTile('Budgets', Icons.pie_chart, () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()))),
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
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sign Out')),
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
