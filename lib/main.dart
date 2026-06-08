import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ExpenseBeamApp(),
    ),
  );
}

class ExpenseBeamApp extends StatefulWidget {
  const ExpenseBeamApp({super.key});

  @override
  State<ExpenseBeamApp> createState() => _ExpenseBeamAppState();
}

class _ExpenseBeamAppState extends State<ExpenseBeamApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'ExpenseBeam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      home: auth.isAuthenticated ? const MainShell() : const AuthScreen(),
    );
  }
}
