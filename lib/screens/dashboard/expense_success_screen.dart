import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class ExpenseSuccessScreen extends StatefulWidget {
  final List<Map<String, dynamic>> expenses;
  const ExpenseSuccessScreen({super.key, required this.expenses});

  @override
  State<ExpenseSuccessScreen> createState() => _ExpenseSuccessScreenState();
}

class _ExpenseSuccessScreenState extends State<ExpenseSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _particleCtrl;

  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _ringScale;
  late final Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _checkScale = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.elasticOut,
    );

    _checkOpacity = CurvedAnimation(
      parent: _checkCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _ringScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOutCubic),
    );

    _fadeSlide = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOutCubic,
    );

    // Stagger: check first, then content, then particles
    _checkCtrl.forward().then((_) {
      _fadeCtrl.forward();
      _particleCtrl.forward();
    });
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _fadeCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount => widget.expenses.fold(
        0,
        (sum, e) => sum + ((e['amount'] as num? ?? 0).toDouble()),
      );

  String get _currency =>
      widget.expenses.isNotEmpty
          ? (widget.expenses.first['currency']?.toString() ?? 'EGP')
          : 'EGP';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.expenses.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Particle burst
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(_particleCtrl.value),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Animated check icon ──────────────────────────────
                  AnimatedBuilder(
                    animation: _checkCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: _checkScale.value,
                      child: Opacity(
                        opacity: _checkOpacity.value.clamp(0.0, 1.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring
                            Transform.scale(
                              scale: _ringScale.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.success.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            // Inner circle
                            Container(
                              width: 88,
                              height: 88,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.success,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Congrats text ────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeSlide,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_fadeSlide),
                      child: Column(
                        children: [
                          Text(
                            count == 1
                                ? 'Expense Logged!'
                                : 'All $count Expenses Logged!',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            count == 1
                                ? 'Great job keeping your finances in check.'
                                : 'Great job! Your records are up to date.',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Summary card ─────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeSlide,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(_fadeSlide),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.fieldBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Total row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total added',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  formatCurrency(_totalAmount, _currency),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.danger,
                                  ),
                                ),
                              ],
                            ),

                            if (count > 1) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),

                              // Expense list
                              ...widget.expenses.map((e) {
                                final desc = e['description']?.toString() ?? 'Expense';
                                final amount = (e['amount'] as num? ?? 0).toDouble();
                                final currency = e['currency']?.toString() ?? 'EGP';
                                final category = e['category']?.toString();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_outlined,
                                          size: 18,
                                          color: AppTheme.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              desc,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (category != null && category.isNotEmpty)
                                              Text(
                                                category,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(amount, currency),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Done button ──────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeSlide,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Back to Dashboard'),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Particle burst painter ────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _rng = Random(42);

  static final List<_Particle> _particles = List.generate(30, (i) {
    final angle = (i / 30) * 2 * pi + _rng.nextDouble() * 0.4;
    final speed = 0.25 + _rng.nextDouble() * 0.35;
    final size  = 4.0 + _rng.nextDouble() * 6;
    final colors = [
      AppTheme.success,
      AppTheme.accent,
      AppTheme.warning,
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];
    return _Particle(
      angle: angle,
      speed: speed,
      size:  size,
      color: colors[i % colors.length],
    );
  });

  const _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final cx = size.width / 2;
    final cy = size.height * 0.32;

    for (final p in _particles) {
      final t       = (progress / p.speed).clamp(0.0, 1.0);
      final fade    = (1 - t).clamp(0.0, 1.0);
      final dist    = t * size.height * 0.45;
      final x       = cx + cos(p.angle) * dist;
      final y       = cy + sin(p.angle) * dist;
      final gravity = t * t * size.height * 0.15;

      final paint = Paint()
        ..color = p.color.withValues(alpha: fade * 0.85)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y + gravity), p.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color  color;
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}
