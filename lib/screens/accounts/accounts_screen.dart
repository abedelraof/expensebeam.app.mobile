import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/models/account.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'edit_account_screen.dart';
import 'account_history_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account>      _accounts = [];
  List<AccountGroup> _groups   = [];
  bool _loading = false;
  final Set<int>    _expandedGroups   = {};
  bool              _expandedUngrouped = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/accounts'),
        ApiClient.get('/account-groups'),
      ]);

      // Parse accounts
      final aData = results[0].data;
      List<dynamic> aList = [];
      if (aData is List) aList = aData;
      else if (aData is Map) {
        for (final k in ['accounts', 'data', 'items']) {
          if (aData[k] is List) { aList = aData[k]; break; }
        }
      }
      final accounts = <Account>[];
      for (final a in aList) {
        try { accounts.add(Account.fromJson(Map<String, dynamic>.from(a))); }
        catch (_) {}
      }

      // Parse groups
      final gData = results[1].data;
      List<dynamic> gList = [];
      if (gData is List) gList = gData;
      else if (gData is Map) {
        for (final k in ['groups', 'account_groups', 'data', 'items']) {
          if (gData[k] is List) { gList = gData[k]; break; }
        }
      }
      final groups = <AccountGroup>[];
      for (final g in gList) {
        try { groups.add(AccountGroup.fromJson(Map<String, dynamic>.from(g))); }
        catch (_) {}
      }
      groups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _groups   = groups;
          // Auto-expand groups that have accounts, collapse empty ones
          _expandedGroups.clear();
          for (final g in groups) {
            if (accounts.any((a) => a.groupId == g.id)) {
              _expandedGroups.add(g.id);
            }
          }
          // Expand ungrouped if there are ungrouped accounts
          _expandedUngrouped = accounts.any((a) => a.groupId == null);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deleteAccount(Account a) async {
    try {
      await ApiClient.delete('/accounts/${a.id}');
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not delete account')));
    }
  }

  Future<void> _deleteGroup(AccountGroup g) async {
    try {
      await ApiClient.delete('/account-groups/${g.id}');
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not delete group')));
    }
  }

  double get _netWorth => _accounts.fold(0.0, (s, a) =>
      s + (a.isLiability ? -a.displayBalance : a.displayBalance));

  List<Account> _accountsInGroup(int groupId) =>
      _accounts.where((a) => a.groupId == groupId).toList();

  List<Account> get _ungrouped =>
      _accounts.where((a) => a.groupId == null).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditAccountScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // ── Net Worth banner ──────────────────────────────────
                  _buildNetWorthBanner(),
                  const SizedBox(height: 20),

                  // ── Groups ────────────────────────────────────────────
                  ..._groups.map((g) {
                    final accounts  = _accountsInGroup(g.id);
                    final total     = accounts.fold(0.0, (s, a) =>
                        s + (a.isLiability ? -a.displayBalance : a.displayBalance));
                    final isExpanded = _expandedGroups.contains(g.id);

                    return _buildGroupCard(
                      key: ValueKey('g${g.id}'),
                      icon: g.icon,
                      name: g.name,
                      accounts: accounts,
                      total: total,
                      isExpanded: isExpanded,
                      onToggle: () => setState(() {
                        if (isExpanded) _expandedGroups.remove(g.id);
                        else _expandedGroups.add(g.id);
                      }),
                      onEdit: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => EditGroupScreen(group: g)));
                        _load();
                      },
                      onDelete: () => _confirmDeleteGroup(g),
                    );
                  }),

                  // ── Ungrouped ─────────────────────────────────────────
                  if (_ungrouped.isNotEmpty) ...[
                    _buildGroupCard(
                      key: const ValueKey('ungrouped'),
                      icon: '📂',
                      name: 'Ungrouped',
                      accounts: _ungrouped,
                      total: _ungrouped.fold(0.0, (s, a) =>
                          s + (a.isLiability ? -a.displayBalance : a.displayBalance)),
                      isExpanded: _expandedUngrouped,
                      onToggle: () => setState(
                          () => _expandedUngrouped = !_expandedUngrouped),
                      onEdit: null,
                      onDelete: null,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // ── Group card ─────────────────────────────────────────────────────────────
  Widget _buildGroupCard({
    required Key key,
    required String icon,
    required String name,
    required List<Account> accounts,
    required double total,
    required bool isExpanded,
    required VoidCallback onToggle,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.fieldBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Group header
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: full-width name + chevron
                    Row(
                      children: [
                        Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppTheme.textSecondary, size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 2: accounts count (left) + total (right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${accounts.length} account${accounts.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          formatCurrency(total.abs(), accounts.isNotEmpty ? accounts.first.currency : 'EGP'),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: total < 0 ? AppTheme.danger : AppTheme.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // Account rows
            if (isExpanded && accounts.isNotEmpty) ...[
              Divider(height: 1, color: AppTheme.fieldBorder),
              ...accounts.asMap().entries.map((e) {
                final i   = e.key;
                final acc = e.value;
                final isLast = i == accounts.length - 1;
                return Column(
                  children: [
                    _buildAccountRow(acc, isLast),
                    if (!isLast)
                      Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: AppTheme.fieldBorder.withValues(alpha: 0.5)),
                  ],
                );
              }),
            ],

            if (isExpanded && accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No accounts in this group',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }

  // ── Account row ────────────────────────────────────────────────────────────
  Widget _buildAccountRow(Account acc, bool isLast) {
    return InkWell(
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AccountHistoryScreen(account: acc))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(acc.icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            // Name + currency
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(acc.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(acc.currency,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            // Balance
            Text(
              formatCurrency(acc.displayBalance, acc.currency),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: acc.isLiability ? AppTheme.danger : AppTheme.primary),
            ),
            // Edit
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: AppTheme.textSecondary),
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => EditAccountScreen(account: acc)));
                _load();
              },
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppTheme.danger),
              onPressed: () => _confirmDeleteAccount(acc),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  // ── Net worth banner ───────────────────────────────────────────────────────
  Widget _buildNetWorthBanner() {
    final assets      = _accounts.where((a) => !a.isLiability)
        .fold(0.0, (s, a) => s + a.displayBalance);
    final liabilities = _accounts.where((a) => a.isLiability)
        .fold(0.0, (s, a) => s + a.displayBalance);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2A4A), Color(0xFF2B4A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net Worth',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(_netWorth.abs(), 'EGP'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statPill('Assets', assets, AppTheme.success),
              const SizedBox(height: 6),
              _statPill('Liabilities', liabilities, AppTheme.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, double amount, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
            const SizedBox(width: 6),
            Text(formatCurrency(amount, 'EGP'),
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  void _confirmDeleteAccount(Account acc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text('Remove "${acc.name}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () { Navigator.pop(ctx); _deleteAccount(acc); },
              child: const Text('Delete')),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(AccountGroup g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${g.name}"?'),
        content: const Text('This will delete the group. Accounts inside will become ungrouped.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () { Navigator.pop(ctx); _deleteGroup(g); },
              child: const Text('Delete')),
        ],
      ),
    );
  }
}

// ── Placeholder edit group screen ─────────────────────────────────────────────
class EditGroupScreen extends StatefulWidget {
  final AccountGroup? group;
  const EditGroupScreen({super.key, this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _nameCtrl = TextEditingController();
  String _icon    = '📁';
  bool   _saving  = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.group?.name ?? '';
    _icon          = widget.group?.icon ?? '📁';
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {'name': _nameCtrl.text.trim(), 'icon': _icon};
      if (widget.group == null) {
        await ApiClient.post('/account-groups', data: data);
      } else {
        await ApiClient.put('/account-groups/${widget.group!.id}', data: data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.group == null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'Add Group' : 'Edit Group',
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
              ),
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isNew ? 'Add' : 'Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Group Name',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          const SizedBox(height: 4),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Bank Of Palestine',
              prefixIcon: const Icon(Icons.folder_outlined, size: 18, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Icon',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['📁','🏦','💰','💳','📈','🏠','💵','💴','💶','💷','🥇','💎','🪙','🏧','📊']
                .map((e) => GestureDetector(
                      onTap: () => setState(() => _icon = e),
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _icon == e
                              ? AppTheme.accent.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _icon == e ? AppTheme.accent : AppTheme.fieldBorder,
                          ),
                        ),
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(isNew ? 'Add Group' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}
