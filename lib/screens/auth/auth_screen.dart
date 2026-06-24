import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

// ── Star data (static) ────────────────────────────────────────────────────
class _Star {
  final double x, y, size, opacity;
  const _Star(this.x, this.y, this.size, this.opacity);
}

List<_Star> _generateStars(int count, Size size) {
  final rng = Random(42);
  return List.generate(count, (_) => _Star(
    rng.nextDouble() * size.width,
    rng.nextDouble() * size.height,
    rng.nextDouble() * 2.4 + 0.6,
    rng.nextDouble() * 0.6 + 0.15,
  ));
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  _StarsPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      canvas.drawCircle(
        Offset(s.x, s.y),
        s.size / 2,
        Paint()..color = Colors.white.withValues(alpha: s.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}

// ── Currency symbol data (animated) ──────────────────────────────────────
class _CurrencySymbol {
  final double x;            // 0.0–1.0 of screen width
  final double y;            // 0.0–1.0 of screen height (initial)
  final double size;         // 13–42
  final double opacity;      // 0.08–0.28
  final double blur;         // 0.0–1.0
  final double speed;        // drift speed 0.25–0.9
  final double phase;        // animation phase offset 0.0–1.0
  final double rotSpeed;     // rotation speed -1.0 to 1.0
  final String symbol;

  const _CurrencySymbol({
    required this.x, required this.y, required this.size,
    required this.opacity, required this.blur, required this.speed,
    required this.phase, required this.rotSpeed, required this.symbol,
  });
}

List<_CurrencySymbol> _generateCurrencySymbols(int count) {
  final rng = Random(99);
  const symbols = ['\$', '€', '£', '¥', '₿', '₹', '₩', '₣'];

  // Grid-jitter: divide space into cols×rows cells, one symbol per cell.
  // Guarantees minimum spacing = one cell width/height — no overlaps.
  const cols = 4;
  const rows = 6; // 24 cells ≥ 22 symbols → 2 cells always empty (natural gaps)
  final cells = List.generate(cols * rows, (i) => i)..shuffle(rng);

  return List.generate(count, (i) {
    final cell  = cells[i];
    final col   = cell % cols;
    final row   = cell ~/ cols;
    const cellW = 1.0 / cols;
    const cellH = 1.0 / rows;

    return _CurrencySymbol(
      x:        (col + rng.nextDouble()) * cellW,  // random within cell column
      y:        (row + rng.nextDouble()) * cellH,  // random within cell row
      size:     rng.nextDouble() * 29 + 13,
      opacity:  rng.nextDouble() * 0.20 + 0.08,
      blur:     rng.nextDouble() * 1.0,
      speed:    rng.nextDouble() * 0.65 + 0.25,
      phase:    rng.nextDouble(),
      rotSpeed: (rng.nextDouble() - 0.5) * 2.0,
      symbol:   symbols[rng.nextInt(symbols.length)],
    );
  });
}

// ── Auth Screen ───────────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {

  int _tab = 0;

  // Login form
  final _loginFormKey   = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl  = TextEditingController();
  bool _loginObscure    = true;
  bool _rememberMe      = false;

  // Register form
  final _regFormKey      = GlobalKey<FormState>();
  final _regNameCtrl     = TextEditingController();
  final _regEmailCtrl    = TextEditingController();
  final _regPassCtrl     = TextEditingController();
  final _regConfirmCtrl  = TextEditingController();
  bool _regObscure       = true;
  bool _regConfirmObscure = true;

  // Animation
  late final AnimationController _ctrl;
  late final List<_CurrencySymbol> _symbols;

  // ── Colors ──────────────────────────────────────────────────────────────
  static const _gradientTop   = Color(0xFF0A0F2C);
  static const _gradientMid   = Color(0xFF1A2657);
  static const _gradientBot   = Color(0xFF2B4FA8);
  static const _cardBg        = Color(0xFFFFFFFF);
  static const _tabBarBg      = Color(0xFFEDEFF3);
  static const _fieldFill     = Color(0xFFF5F7FA);
  static const _fieldBorder   = Color(0xFFE8ECF0);
  static const _fieldIcon     = Color(0xFF9EA5B2);
  static const _btnColor      = Color(0xFF2B7BE0);
  static const _textPrimary   = Color(0xFF1B2A4A);
  static const _textSecondary = Color(0xFF8A8D9A);
  static const _dividerColor  = Color(0xFFDDE1E8);

  @override
  void initState() {
    super.initState();
    _symbols = _generateCurrencySymbols(22);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_loginEmailCtrl.text.trim(), _loginPassCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Login failed')));
    }
  }

  Future<void> _register() async {
    if (!_regFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signup(_regEmailCtrl.text.trim(), _regPassCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Registration failed')));
    }
  }

  // ── Currency layer ────────────────────────────────────────────────────
  Widget _buildCurrencyLayer(Size size) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          children: _symbols.map((s) {
            // y drifts upward, wraps 0→1 continuously
            final normY = ((s.y - _ctrl.value * s.speed + s.phase) % 1.0);
            final dy = normY * size.height;
            final dx = s.x * size.width;
            final angle = _ctrl.value * s.rotSpeed * 2 * pi;

            // Fade near top (0–10%) and bottom (90–100%) for smooth wrap
            const fadeZone = 0.10;
            double edgeFade = 1.0;
            if (normY < fadeZone) {
              edgeFade = normY / fadeZone;
            } else if (normY > 1.0 - fadeZone) {
              edgeFade = (1.0 - normY) / fadeZone;
            }
            final finalOpacity = (s.opacity * edgeFade).clamp(0.0, 1.0);

            Widget text = Text(
              s.symbol,
              style: TextStyle(
                color: Colors.white.withValues(alpha: finalOpacity),
                fontSize: s.size,
                fontWeight: FontWeight.bold,
              ),
            );

            // Apply blur if > 0.2
            if (s.blur > 0.2) {
              text = ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: s.blur, sigmaY: s.blur),
                child: text,
              );
            }

            return Positioned(
              left: dx,
              top: dy,
              child: Transform.rotate(
                angle: angle,
                child: text,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final stars = _generateStars(120, size);

    return Scaffold(
      backgroundColor: _gradientTop,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1 ── Gradient ────────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_gradientTop, _gradientMid, _gradientBot],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2 ── Stars (static) ─────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _StarsPainter(stars)),
          ),

          // 3 ── Currency symbols (animated) ────────────────────────────
          Positioned.fill(
            child: _buildCurrencyLayer(size),
          ),

          // 4 ── Content ─────────────────────────────────────────────────
          OrientationBuilder(
            builder: (context, orientation) {
              final sz = MediaQuery.of(context).size;
              final isLandscape = orientation == Orientation.landscape &&
                  sz.aspectRatio > 1.3;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLandscape
                    ? _buildLandscape(auth)
                    : _buildPortrait(auth),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Portrait layout (unchanged) ──────────────────────────────────────
  Widget _buildPortrait(AuthProvider auth) {
    return SafeArea(
      key: const ValueKey('portrait'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 4, child: _buildBranding(compact: false)),
          Expanded(flex: 7, child: _buildCard(auth, landscape: false)),
        ],
      ),
    );
  }

  // ── Landscape layout (side-by-side) ──────────────────────────────────
  Widget _buildLandscape(AuthProvider auth) {
    return Row(
      key: const ValueKey('landscape'),
      children: [
        Expanded(
          child: SafeArea(
            right: false,
            child: _buildBranding(compact: true),
          ),
        ),
        Expanded(
          child: _buildCard(auth, landscape: true),
        ),
      ],
    );
  }

  // ── Shared branding panel ─────────────────────────────────────────────
  Widget _buildBranding({required bool compact}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              _tab == 0
                  ? 'Welcome back\nto ExpenseBeam'
                  : 'Start tracking\nyour finances',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 18 : 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              _tab == 0
                  ? 'Sign in to manage your money,\ntrack spending and hit your goals'
                  : 'Create a free account and take\ncontrol of your financial life',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: compact ? 12 : 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // App name — right aligned with dash prefix
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '—— ExpenseBeam',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared white card ─────────────────────────────────────────────────
  Widget _buildCard(AuthProvider auth, {required bool landscape}) {
    final borderRadius = landscape
        ? BorderRadius.zero
        : const BorderRadius.vertical(top: Radius.circular(32));

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: _cardBg,
        child: landscape
            // In landscape: full-height card, SafeArea inside for content only
            ? Column(
                children: [
                  SafeArea(
                    left: false,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: _buildTabBar(),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: IndexedStack(
                        index: _tab,
                        children: [
                          _buildLoginForm(auth),
                          _buildRegisterForm(auth),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            // In portrait: full scroll
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTabBar(),
                    const SizedBox(height: 28),
                    IndexedStack(
                      index: _tab,
                      children: [
                        _buildLoginForm(auth),
                        _buildRegisterForm(auth),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _tabBarBg,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _tabItem('Login', 0),
        _tabItem('Register', 1),
      ]),
    );
  }

  Widget _tabItem(String label, int index) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: active
                ? [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? _textPrimary : _textSecondary,
              )),
        ),
      ),
    );
  }

  // ── Field decoration ──────────────────────────────────────────────────
  InputDecoration _fieldDeco(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _fieldIcon, fontSize: 14),
      prefixIcon: Icon(icon, color: _fieldIcon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fieldBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fieldBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _btnColor, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF43F5E))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5)),
    );
  }

  // ── Pill button ───────────────────────────────────────────────────────
  Widget _pillBtn(String label, VoidCallback? onPressed, bool loading) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _btnColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _btnColor.withValues(alpha: 0.5),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: loading
            ? const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(label),
      ),
    );
  }

  // ── Terms & Privacy bottom sheet ─────────────────────────────────────
  void _showTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _fieldBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Terms & Privacy Policy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: _textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(color: _dividerColor),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: const [
                    _TermsSection(
                      title: '1. Acceptance of Terms',
                      body:
                          'By creating an account and using ExpenseBeam, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, please do not use our service.',
                    ),
                    _TermsSection(
                      title: '2. Use of Service',
                      body:
                          'ExpenseBeam is a personal finance tracking application. You agree to use this service only for lawful purposes and in a manner that does not infringe the rights of others. You are responsible for maintaining the confidentiality of your account credentials.',
                    ),
                    _TermsSection(
                      title: '3. Data Collection & Privacy',
                      body:
                          'We collect the information you provide when registering and using the app, including email address, financial transaction data, and usage analytics. This data is used solely to provide and improve our service. We do not sell your personal data to third parties.',
                    ),
                    _TermsSection(
                      title: '4. Data Security',
                      body:
                          'We implement industry-standard security measures to protect your data. All data is encrypted in transit using TLS and at rest using AES-256 encryption. However, no method of transmission over the internet is 100% secure.',
                    ),
                    _TermsSection(
                      title: '5. Financial Data',
                      body:
                          'ExpenseBeam stores expense and income records that you manually enter. We do not connect to your bank accounts or financial institutions unless you explicitly grant permission through a third-party integration. You retain full ownership of your financial data.',
                    ),
                    _TermsSection(
                      title: '6. Account Termination',
                      body:
                          'You may delete your account at any time from the app settings. Upon deletion, all your personal data will be permanently removed from our servers within 30 days. We reserve the right to terminate accounts that violate these terms.',
                    ),
                    _TermsSection(
                      title: '7. Changes to Terms',
                      body:
                          'We may update these terms from time to time. We will notify you of significant changes via email or in-app notification. Continued use of ExpenseBeam after changes constitutes acceptance of the new terms.',
                    ),
                    _TermsSection(
                      title: '8. Contact Us',
                      body:
                          'If you have any questions about these Terms or our Privacy Policy, please contact us at support@expensebeam.com. We aim to respond to all enquiries within 48 hours.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Forgot Password bottom sheet ─────────────────────────────────────
  void _showForgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                bool loading = false;
                bool sent = false;

                return StatefulBuilder(
                  builder: (ctx, setInner) {
                    return Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40, height: 4,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: _fieldBorder,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          if (!sent) ...[
                            const Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Enter your email and we'll send you a reset link.",
                              style: TextStyle(color: _textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: _textPrimary, fontSize: 14),
                              decoration: _fieldDeco('Email address', Icons.mail_outline),
                              validator: (v) =>
                                  v == null || !v.contains('@') ? 'Enter a valid email' : null,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) return;
                                        setInner(() => loading = true);
                                        final auth = context.read<AuthProvider>();
                                        final ok = await auth.forgotPassword(emailCtrl.text.trim());
                                        setInner(() => loading = false);
                                        if (ok) {
                                          setInner(() => sent = true);
                                        } else if (ctx.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(auth.error ?? 'Failed to send reset email')),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _btnColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _btnColor.withValues(alpha: 0.5),
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        height: 22, width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : const Text('Send Reset Link'),
                              ),
                            ),
                          ] else ...[
                            // Success state
                            const Center(
                              child: Icon(Icons.mark_email_read_outlined,
                                  size: 64, color: _btnColor),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Check your inbox!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'A reset link has been sent to ${emailCtrl.text.trim()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _btnColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Back to Login'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Login form ────────────────────────────────────────────────────────
  Widget _buildLoginForm(AuthProvider auth) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ignore: dead_code
          if (false) ...[
          Row(children: [
            Expanded(child: _socialBtn('Google')),
            const SizedBox(width: 12),
            Expanded(child: _socialBtn('Apple')),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Divider(color: _dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with email',
                  style: TextStyle(
                      color: _textSecondary.withValues(alpha: 0.8), fontSize: 12)),
            ),
            const Expanded(child: Divider(color: _dividerColor)),
          ]),
          const SizedBox(height: 20),
          ], // end hidden social section
          // Fields
          TextFormField(
            controller: _loginEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: _fieldDeco('E-mail ID', Icons.mail_outline),
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPassCtrl,
            obscureText: _loginObscure,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: _fieldDeco('Password', Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _loginObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _fieldIcon, size: 20,
                  ),
                  onPressed: () => setState(() => _loginObscure = !_loginObscure),
                )),
            validator: (v) =>
                v == null || v.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v!),
                      activeColor: _btnColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: const BorderSide(color: _fieldBorder, width: 1.5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Remember me',
                      style: TextStyle(color: _textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showForgotPassword(context),
              child: const Text('Forgot Password?',
                  style: TextStyle(color: _btnColor, fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 24),
          _pillBtn('Login', auth.isLoading ? null : _login, auth.isLoading),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _tab = 1),
            child: const Text(
              "Don't have an account? Register",
              style: TextStyle(color: _btnColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialBtn(String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _fieldBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        foregroundColor: _textPrimary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label == 'Google')
            const Text('G ', style: TextStyle(
                fontWeight: FontWeight.bold, color: _btnColor, fontSize: 16)),
          if (label == 'Apple')
            const Icon(Icons.apple, size: 18, color: _textPrimary),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Register form ─────────────────────────────────────────────────────
  Widget _buildRegisterForm(AuthProvider auth) {
    return Form(
      key: _regFormKey,
      child: Column(
        key: const ValueKey('reg'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ignore: dead_code
          if (false) ...[
          Row(children: [
            Expanded(child: _socialBtn('Google')),
            const SizedBox(width: 12),
            Expanded(child: _socialBtn('Apple')),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Divider(color: _dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or sign up with email',
                  style: TextStyle(
                      color: _textSecondary.withValues(alpha: 0.8),
                      fontSize: 12)),
            ),
            const Expanded(child: Divider(color: _dividerColor)),
          ]),
          const SizedBox(height: 20),
          ], // end hidden social section
          // Full Name
          TextFormField(
            controller: _regNameCtrl,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: _fieldDeco('Full Name', Icons.person_outline),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 16),
          // Email
          TextFormField(
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: _fieldDeco('Email address', Icons.mail_outline),
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          // Password
          TextFormField(
            controller: _regPassCtrl,
            obscureText: _regObscure,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: _fieldDeco('Password', Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _regObscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _fieldIcon, size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _regObscure = !_regObscure),
                )),
            validator: (v) =>
                v == null || v.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 16),
          // Confirm Password
          TextFormField(
            controller: _regConfirmCtrl,
            obscureText: _regConfirmObscure,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: _fieldDeco('Confirm Password', Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _regConfirmObscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _fieldIcon, size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _regConfirmObscure = !_regConfirmObscure),
                )),
            validator: (v) =>
                v != _regPassCtrl.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 16),
          // Terms & Privacy
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: _textSecondary, fontSize: 11),
              children: [
                const TextSpan(text: 'By registering you agree to our '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _showTerms(context),
                    child: const Text(
                      'Terms & Privacy Policy',
                      style: TextStyle(
                        color: _btnColor,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _pillBtn('Create Account',
              auth.isLoading ? null : _register, auth.isLoading),
          const SizedBox(height: 4),
          // Tab-switch link
          TextButton(
            onPressed: () => setState(() => _tab = 0),
            child: const Text(
              'Already have an account? Sign in',
              style: TextStyle(color: _btnColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Terms section widget ──────────────────────────────────────────────────────
class _TermsSection extends StatelessWidget {
  final String title;
  final String body;
  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2A4A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8A8D9A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
