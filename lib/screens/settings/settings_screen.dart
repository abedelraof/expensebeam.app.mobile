import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/theme/app_theme.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/settings');
      final data = res.data is Map
          ? Map<String, dynamic>.from(res.data)
          : <String, dynamic>{};
      final c = data['currency'] ?? 'EGP';
      _selectedCurrency = _currencies.contains(c) ? c : 'EGP';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    try {
      await ApiClient.put('/settings', data: {
        'currency': _selectedCurrency,
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
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Plan badge
                _buildPlanBanner(sub),
                const SizedBox(height: 16),
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

  Widget _buildPlanBanner(SubscriptionProvider sub) {
    final isPro = sub.isPro;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: isPro
            ? AppTheme.headerGradient
            : const LinearGradient(
                colors: [Color(0xFFF5F7FA), Color(0xFFEAEEF5)],
              ),
        borderRadius: BorderRadius.circular(14),
        border: isPro
            ? null
            : Border.all(color: AppTheme.fieldBorder),
      ),
      child: Row(
        children: [
          Icon(
            isPro
                ? Icons.workspace_premium_rounded
                : Icons.account_circle_outlined,
            color: isPro ? Colors.amber : AppTheme.textSecondary,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? 'ExpenseBeam Pro' : 'Free Plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isPro ? Colors.white : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPro
                      ? '${sub.aiUsed} / ${sub.aiLimit} AI requests used this month'
                      : 'Upgrade to unlock AI features and remove ads',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPro
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isPro) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/upgrade'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
              child: const Text('Upgrade'),
            ),
          ],
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
