import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/subscription/upgrade_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
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
      navigatorKey: AuthProvider.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      routes: {
        '/upgrade': (_) => const UpgradeScreen(),
      },
      home: auth.isChecking
          ? const SplashScreen()
          : auth.isAuthenticated
              ? MainShell(key: MainShell.shellKey)
              : const AuthScreen(),
    );
  }
}
