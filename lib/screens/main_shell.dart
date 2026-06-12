import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'recurring/recurring_screen.dart';
import 'income/income_screen.dart';
import 'reports/reports_screen.dart';
import 'accounts/accounts_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final GlobalKey<_MainShellState> shellKey = GlobalKey<_MainShellState>();

  static void goToDashboard() {
    shellKey.currentState?._navigate(0);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    RecurringScreen(),
    IncomeScreen(),
    ReportsScreen(),
    AccountsScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    (label: 'Dashboard',    icon: Icons.home_outlined,                    filled: Icons.home),
    (label: 'Transactions', icon: Icons.list_alt_outlined,                filled: Icons.list_alt),
    (label: 'Recurring',    icon: Icons.repeat_outlined,                  filled: Icons.repeat),
    (label: 'Income',       icon: Icons.savings_outlined,                 filled: Icons.savings),
    (label: 'Reports',      icon: Icons.bar_chart_outlined,               filled: Icons.bar_chart),
    (label: 'Accounts',     icon: Icons.account_balance_wallet_outlined,  filled: Icons.account_balance_wallet),
    (label: 'Settings',     icon: Icons.settings_outlined,                filled: Icons.settings),
  ];

  void _navigate(int i) {
    setState(() => _index = i);
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,

      // ── Fixed solid header ───────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            boxShadow: [
              BoxShadow(
                color: Color(0x441E3A5F),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Hamburger button
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                    onPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _navItems[_index].label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Slide-in drawer ──────────────────────────────────────────────
      drawer: Drawer(
        width: 280,
        child: Container(
          decoration: const BoxDecoration(color: AppTheme.primary),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ExpenseBeam',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Personal Finance',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                const SizedBox(height: 12),

                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _navItems.length,
                    itemBuilder: (ctx, i) {
                      final item = _navItems[i];
                      final selected = _index == i;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Material(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _navigate(i),
                            splashColor: Colors.white.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              child: Row(
                                children: [
                                  Icon(
                                    selected ? item.filled : item.icon,
                                    color: selected
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.6),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.7),
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (selected) ...[
                                    const Spacer(),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Divider + Logout
                Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        _scaffoldKey.currentState?.closeDrawer();
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Icon(Icons.logout,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 22),
                            const SizedBox(width: 16),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── Main content ─────────────────────────────────────────────────
      body: IndexedStack(index: _index, children: _screens),
    );
  }
}
