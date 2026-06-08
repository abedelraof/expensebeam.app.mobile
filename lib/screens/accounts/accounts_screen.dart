import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/account.dart';
import '../../core/utils/formatters.dart';
import 'edit_account_screen.dart';
import 'account_history_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account> _accounts = [];
  bool _loading = true;
  double _netWorth = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/accounts');
      final data = res.data;
      final list =
          data is List ? data : (data['accounts'] ?? data['data'] ?? []);
      _accounts = (list as List).map((a) => Account.fromJson(a)).toList();
      _netWorth = _accounts.fold(0.0, (sum, a) {
        final bal = a.quantity != null && a.pricePerUnit != null
            ? a.quantity! * a.pricePerUnit!
            : a.balance;
        return sum + (a.isLiability ? -bal : bal);
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(Account account) async {
    try {
      await ApiClient.delete('/accounts/${account.id}');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final assets = _accounts.where((a) => !a.isLiability).toList();
    final liabilities = _accounts.where((a) => a.isLiability).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditAccountScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildNetWorthCard(),
                  const SizedBox(height: 16),
                  if (assets.isNotEmpty) ...[
                    _buildSectionHeader('Assets', assets),
                    ...assets.map((a) => _buildAccountCard(a)),
                    const SizedBox(height: 8),
                  ],
                  if (liabilities.isNotEmpty) ...[
                    _buildSectionHeader('Liabilities', liabilities),
                    ...liabilities.map((a) => _buildAccountCard(a)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildNetWorthCard() => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Net Worth',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                formatCurrency(_netWorth, 'EGP'),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

  Widget _buildSectionHeader(String title, List<Account> accounts) {
    final total = accounts.fold(0.0, (s, a) {
      final bal = a.quantity != null && a.pricePerUnit != null
          ? a.quantity! * a.pricePerUnit!
          : a.balance;
      return s + bal;
    });
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(formatCurrency(total, 'EGP'),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final displayBalance =
        account.quantity != null && account.pricePerUnit != null
            ? account.quantity! * account.pricePerUnit!
            : account.balance;

    return Dismissible(
      key: Key(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete account?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete')),
          ],
        ),
      ),
      onDismissed: (_) => _delete(account),
      child: Card(
        child: ListTile(
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditAccountScreen(account: account)));
            _load();
          },
          leading: Icon(
            account.isLiability
                ? Icons.trending_down
                : Icons.trending_up,
            color: account.isLiability
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          title: Text(account.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${account.type} • ${account.currency}'),
              if (account.quantity != null)
                Text(
                    '${account.quantity} units × ${account.pricePerUnit}',
                    style: const TextStyle(fontSize: 11)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(displayBalance, account.currency),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: account.isLiability
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AccountHistoryScreen(account: account))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
