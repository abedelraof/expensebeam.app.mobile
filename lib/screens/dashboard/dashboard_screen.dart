import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/goal.dart';
import '../../core/utils/formatters.dart';
import 'confirm_expenses_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // Quick expense
  final _expenseCtrl   = TextEditingController();
  bool _expenseLoading = false;

  // Scan animation
  late final AnimationController _scanCtrl;
  late final AnimationController _pulseCtrl;

  // Monthly stats
  Map<String, dynamic>? _stats;

  // Goals
  List<Goal> _goals   = [];
  bool _goalsLoading  = true;

  // AI chat
  final _aiCtrl   = TextEditingController();
  bool _aiLoading = false;
  String? _aiAnswer;
  String? _aiQuestion;

  static const _suggested = [
    'How much did I spend this month?',
    'What is my biggest expense category?',
    'Am I on track with my savings goals?',
    'How does my spending compare to last month?',
    'What can I cut back on to save more?',
  ];

  @override
  void initState() {
    super.initState();
    final idx = Random().nextInt(_tips.length);
    _tipTitle   = _tips[idx].$1;
    _tipMessage = _tips[idx].$2;
    _loadGoals();
    _loadStats();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _expenseCtrl.dispose();
    _aiCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Load goals ────────────────────────────────────────────────────────
  Future<void> _loadGoals() async {
    if (mounted) setState(() {
      _goalsLoading = true;
      final idx = Random().nextInt(_tips.length);
      _tipTitle   = _tips[idx].$1;
      _tipMessage = _tips[idx].$2;
    });
    try {
      final res = await ApiClient.get('/goals');
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        final val = data['goals'] ?? data['data'] ?? data['items'];
        if (val is List) {
          list = val;
        } else {
          for (final v in data.values) {
            if (v is List) { list = v; break; }
          }
        }
      }
      final parsed = <Goal>[];
      for (final item in list) {
        try { parsed.add(Goal.fromJson(Map<String, dynamic>.from(item))); }
        catch (e) { debugPrint('Goal parse: $e'); }
      }
      if (mounted) setState(() => _goals = parsed);
    } catch (e) {
      debugPrint('Goals error: $e');
    } finally {
      if (mounted) setState(() => _goalsLoading = false);
    }
  }

  // ── Load monthly stats ────────────────────────────────────────────────
  Future<void> _loadStats() async {
    try {
      final res  = await ApiClient.get('/reports/dashboard-stats');
      final data = res.data;
      debugPrint('STATS RESPONSE: $data');
      if (mounted) {
        setState(() {
          if (data is Map) {
            _stats = Map<String, dynamic>.from(data);
          } else {
            // Wrap non-map in empty map so strip still shows
            _stats = {};
          }
        });
      }
    } catch (e) {
      debugPrint('STATS ERROR: $e');
      if (mounted) setState(() => _stats = {});
    }
  }

  // ── Parse expense text via AI ─────────────────────────────────────────
  Future<void> _parseExpenses() async {
    final text = _expenseCtrl.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _expenseLoading = true);
    _scanCtrl.repeat();
    _pulseCtrl.repeat(reverse: true);
    try {
      final res = await ApiClient.post('/ai/parse', data: {'text': text});
      if (!mounted) return;

      // Normalise: API may return a single object OR a list
      final raw = res.data;
      List<Map<String, dynamic>> expenses;

      if (raw is List) {
        expenses = raw.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (raw is Map) {
        // Could be { expenses: [...] } or a single expense object
        if (raw.containsKey('expenses') && raw['expenses'] is List) {
          expenses = (raw['expenses'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (raw.containsKey('items') && raw['items'] is List) {
          expenses = (raw['items'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          // Single expense object
          expenses = [Map<String, dynamic>.from(raw)];
        }
      } else {
        throw Exception('Unexpected response format');
      }

      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect any expenses in your text.')),
        );
        return;
      }

      // Navigate to confirm screen
      final added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmExpensesScreen(expenses: expenses),
        ),
      );

      if (added == true) {
        _expenseCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expenses added ✓'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not parse expenses: $e')),
        );
      }
    } finally {
      _scanCtrl.stop(); _scanCtrl.reset();
      _pulseCtrl.stop(); _pulseCtrl.reset();
      if (mounted) setState(() => _expenseLoading = false);
    }
  }

  // ── AI ask ────────────────────────────────────────────────────────────
  Future<void> _askAI(String question) async {
    if (question.trim().isEmpty) return;
    setState(() {
      _aiLoading  = true;
      _aiQuestion = question;
      _aiAnswer   = null;
    });
    _aiCtrl.text = question;
    try {
      final res = await ApiClient.post('/ai/ask', data: {'question': question});
      if (mounted) {
        setState(() {
          _aiAnswer = res.data['answer'] ??
              res.data['message'] ??
              res.data.toString();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _aiAnswer =
            "Sorry, I couldn't get an answer right now. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ── Financial tips (100 messages) ────────────────────────────────────
  static const _tips = [
    ('Budget First', 'Pay yourself first — set aside savings before you spend anything else.'),
    ('The 50/30/20 Rule', 'Allocate 50% to needs, 30% to wants, and 20% to savings and debt repayment.'),
    ('Emergency Fund', 'Aim to keep 3–6 months of living expenses in an easily accessible account.'),
    ('Track Every Pound', 'Small daily expenses add up fast. Tracking them reveals where your money really goes.'),
    ('Avoid Lifestyle Inflation', 'When your income rises, resist the urge to raise your spending at the same rate.'),
    ('The 24-Hour Rule', 'Wait 24 hours before any non-essential purchase over 200 EGP.'),
    ('Automate Savings', 'Set up automatic transfers to savings on payday — what you don\'t see, you won\'t spend.'),
    ('Cut Subscription Creep', 'Review your subscriptions quarterly and cancel anything you haven\'t used this month.'),
    ('Cook More, Spend Less', 'Preparing meals at home can cut your food spending by up to 60% versus eating out.'),
    ('High-Interest Debt First', 'Attack your highest-interest debt first — it\'s the most expensive money you owe.'),
    ('Net Worth Over Income', 'What you keep matters more than what you earn. Track net worth, not just salary.'),
    ('Invest Early', 'Time in the market beats timing the market. Starting early is the biggest advantage.'),
    ('Opportunity Cost', 'Every purchase is a trade-off. Ask: what else could this money do for me?'),
    ('Negotiate Everything', 'Bills, salaries, rent — almost everything is negotiable if you simply ask.'),
    ('Sinking Funds', 'Set money aside monthly for irregular expenses like car repairs or annual fees.'),
    ('One Financial Goal', 'Focus on one financial goal at a time. Divided attention slows all progress.'),
    ('Cash Envelope Method', 'Using physical cash for categories like dining makes overspending feel real.'),
    ('Review Bank Fees', 'Bank charges, ATM fees, and account fees can silently drain hundreds per year.'),
    ('Round-Up Savings', 'Round every purchase up to the nearest 10 and transfer the difference to savings.'),
    ('The Latte Factor', 'Daily small habits cost more than you think. A 30 EGP coffee daily is 10,950 EGP/year.'),
    ('Zero-Based Budgeting', 'Give every pound a job. Budget income minus expenses should equal zero each month.'),
    ('Financial Calendar', 'List all annual expenses on a calendar so large bills never catch you off guard.'),
    ('Money Date Night', 'Schedule a monthly money review with yourself or your partner — consistency wins.'),
    ('Avoid Comparison', 'Comparing your finances to others\' highlights leads to poor decisions. Run your own race.'),
    ('The Power of Compounding', 'Compound interest doubles money at a predictable rate — start now, not later.'),
    ('Price Per Use', 'Divide cost by expected uses. A 1,000 EGP item used 500 times costs 2 EGP per use.'),
    ('Side Income Streams', 'A small secondary income removes financial pressure and accelerates goals.'),
    ('No-Spend Days', 'Challenge yourself to one no-spend day per week — it resets spending habits.'),
    ('Insurance Review', 'Over-insuring costs money; under-insuring costs far more. Review coverage annually.'),
    ('Buy Quality Once', 'Cheap items bought repeatedly cost more than one quality purchase. Think long-term.'),
    ('Keep Records', 'Organize receipts and financial documents — tax season and disputes will thank you.'),
    ('Limit Credit Cards', 'Credit cards aren\'t bad, but using more than you can pay monthly is expensive.'),
    ('Housing Under 30%', 'Aim to keep housing costs below 30% of take-home pay for breathing room elsewhere.'),
    ('Transportation Costs', 'Vehicle ownership is often the second biggest expense — review it honestly.'),
    ('Gift Budget Early', 'Set a gift budget at the start of the year, not when occasions arrive.'),
    ('Meal Planning', 'Planning meals weekly reduces food waste and impulse grocery purchases dramatically.'),
    ('Pre-Commitment', 'Pre-commit to savings by setting goals before you receive your paycheck.'),
    ('Invest in Yourself', 'Skills and knowledge offer the highest long-term return on any investment.'),
    ('Unsubscribe from Temptation', 'Remove retail emails and unfollow shopping accounts to reduce impulse spending.'),
    ('Buy Used First', 'Always check second-hand options before buying new. Condition is often perfect.'),
    ('Energy Audit', 'Small changes in energy use — lighting, cooling, appliances — add up over a year.'),
    ('Debt Snowball', 'Paying off smallest debts first builds momentum and psychological wins.'),
    ('Wants vs Needs', 'Before every purchase ask: is this a want or a need? Honest answers change habits.'),
    ('Financial Literacy', 'Read one personal finance article or book chapter weekly — knowledge compounds too.'),
    ('Avoid Payday Loans', 'Payday loans carry extreme interest rates. Explore all other options first.'),
    ('DIY Where Possible', 'Learn basic home repairs, cooking, and maintenance — skills save thousands yearly.'),
    ('Shop with a List', 'Entering any store without a list almost guarantees unplanned spending.'),
    ('Tax Awareness', 'Understand which deductions apply to you — unclaimed deductions are money lost.'),
    ('Annual Fee Audit', 'List every annual fee you pay and justify each one against its actual value.'),
    ('Avoid Lifestyle Debt', 'Borrowing for holidays, gadgets, or fashion locks future income into past fun.'),
    ('Set a Savings Rate', 'Aim to save at least 20% of income. Even 10% is a transformative habit.'),
    ('Reward Milestones', 'Celebrate financial milestones with small, budgeted rewards to stay motivated.'),
    ('Bank Relationship', 'A good relationship with your bank can unlock lower rates and better products.'),
    ('Charitable Giving', 'Budget for giving — generosity increases gratitude and reduces impulse spending.'),
    ('Avoid Timing the Market', 'Consistent, regular investing outperforms most attempts to time market highs and lows.'),
    ('Dollar-Cost Averaging', 'Investing a fixed amount regularly removes the emotion from market fluctuations.'),
    ('Financial Stress', 'Financial stress is real health issue. A plan — even imperfect — reduces anxiety.'),
    ('Spouse Alignment', 'Financial goals only work if both partners are aligned. Talk money regularly.'),
    ('Savings Goal Naming', 'Naming savings accounts after goals ("Car Fund", "Holiday 2027") increases motivation.'),
    ('Credit Score', 'A good credit score saves thousands in interest over a lifetime — protect it.'),
    ('Compare Before Buying', 'Spending 10 minutes comparing prices on large purchases saves real money.'),
    ('Cashback Smartly', 'Cashback and rewards are only valuable if you don\'t change spending behavior for them.'),
    ('Invest in Index Funds', 'Low-cost index funds outperform most actively managed funds over the long term.'),
    ('Retirement Early', 'Every year you delay saving for retirement costs significantly more to catch up.'),
    ('Know Your Numbers', 'Know your monthly income, expenses, and net worth — you can\'t manage what you don\'t measure.'),
    ('Frugal vs Cheap', 'Frugal means maximizing value. Cheap means minimizing cost. The difference matters.'),
    ('Utility Negotiation', 'Call your utility and service providers annually to ask for better rates.'),
    ('Emergency vs Investment', 'Never invest money you might need within 12 months — emergencies destroy investments.'),
    ('Pay Bills on Time', 'Late fees and interest on overdue bills are purely avoidable costs.'),
    ('Windfall Rule', 'When you receive unexpected money, save at least 50% before spending any of it.'),
    ('Health Investment', 'Preventive healthcare is far cheaper than reactive care — invest in your health.'),
    ('Mental Money Accounts', 'Avoid the mental trap of treating a bonus or refund as "free money" — it\'s income.'),
    ('Long-Term Thinking', 'The best financial decisions often feel uncomfortable today but free you tomorrow.'),
    ('Delayed Gratification', 'The ability to delay gratification is one of the strongest predictors of financial success.'),
    ('Asset vs Liability', 'Assets put money in your pocket. Liabilities take it out. Buy more assets.'),
    ('Minimalism', 'Owning less reduces maintenance costs, storage needs, and the urge to upgrade.'),
    ('Conscious Spending', 'Spend generously on things you love, and ruthlessly cut everything you don\'t.'),
    ('Financial Independence', 'FI isn\'t about retirement — it\'s about having choices. Every saved pound buys freedom.'),
    ('Review Annually', 'Your financial plan should be reviewed at least once a year as life changes.'),
    ('Social Spending', 'Social pressure to spend is real. It\'s okay to suggest free or low-cost alternatives.'),
    ('Currency Risk', 'If you hold savings in one currency, diversifying can protect against devaluation.'),
    ('Grocery Store Tricks', 'Shop the perimeter of the store first — that\'s where the fresh, unprocessed food lives.'),
    ('Small Wins', 'Every financial goal starts with a small win. Celebrate the first 1,000 EGP saved.'),
    ('Income Diversification', 'Relying on a single income source is fragile. Build multiple streams over time.'),
    ('Accountability Partner', 'Sharing financial goals with a trusted person dramatically increases follow-through.'),
    ('Wealth Building', 'Wealth is built quietly, through consistent habits, not dramatic windfalls.'),
    ('Know Your Worth', 'Undercharging for your work is a financial problem. Know your market value.'),
    ('Avoid Anchoring', 'A 50% sale on something you didn\'t need is still 100% of wasted money.'),
    ('Mental Health & Money', 'Stress spending and retail therapy are expensive coping mechanisms — find alternatives.'),
    ('Passive Income', 'Build assets that generate income while you sleep — savings interest, dividends, rent.'),
    ('Renegotiate Rent', 'Long-term tenants often qualify for rent freezes or reductions — ask directly.'),
    ('Car Costs', 'The true cost of a car includes insurance, fuel, maintenance, and depreciation — not just the price.'),
    ('Financial Boundaries', 'It\'s okay to say no to lending money or expensive social events — protect your plan.'),
    ('Patience Pays', 'The greatest financial returns reward patience over cleverness.'),
    ('Wealth Mindset', 'Wealth isn\'t a number — it\'s a mindset that sees every expense as a choice, not a necessity.'),
    ('Simplify', 'The simpler your finances, the easier they are to manage and optimize.'),
    ('Future Self', 'Make financial decisions that your future self will thank you for, not just your present self.'),
  ];

  String _tipTitle   = '';
  String _tipMessage = '';

  // ── Build ─────────────────────────────────────────────────────────────
  // ── Scan overlay ─────────────────────────────────────────────────────
  Widget _buildScanOverlay() {
    final size = MediaQuery.of(context).size;
    final rng  = Random(42);
    final dataLines = [
      '0x${rng.nextInt(0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0')} · PARSING INPUT',
      'TOKEN STREAM: ACTIVE',
      'ENTITY EXTRACTION: RUNNING',
      'AMOUNT · CATEGORY · DATE',
      'CONFIDENCE THRESHOLD: 0.85',
      'AI ENGINE: v2.1 · READY',
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_scanCtrl, _pulseCtrl]),
      builder: (_, __) {
        final scanY = _scanCtrl.value * size.height;
        final pulse = _pulseCtrl.value;
        final dots  = '.' * ((_scanCtrl.value * 4).floor() % 4);

        return Stack(
          children: [
            // 1 — Blurred + tinted bg
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: AppTheme.primary.withValues(alpha: 0.88),
              ),
            ),

            // 2 — Horizontal grid lines
            CustomPaint(
              size: size,
              painter: _GridPainter(),
            ),

            // 3 — Scan line with glow
            Positioned(
              top: scanY.clamp(0, size.height - 2),
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF2B7BE0),
                      Colors.white,
                      Color(0xFF2B7BE0),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2B7BE0).withValues(alpha: 0.8),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // 4 — Corner brackets
            ..._buildCornerBrackets(size),

            // 5 — Center status
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hex icon
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF2B7BE0).withValues(alpha: 0.6 + pulse * 0.4),
                          width: 2),
                      color: const Color(0xFF2B7BE0).withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: const Color(0xFF2B7BE0).withValues(alpha: 0.7 + pulse * 0.3),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '⬡  AI PARSING',
                    style: TextStyle(
                      color: const Color(0xFF2B7BE0).withValues(alpha: 0.6 + pulse * 0.4),
                      fontSize: 11,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ANALYZING$dots',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: null,
                      backgroundColor: const Color(0xFF1E2D45),
                      valueColor: AlwaysStoppedAnimation(
                        const Color(0xFF2B7BE0).withValues(alpha: 0.8 + pulse * 0.2),
                      ),
                      minHeight: 2,
                    ),
                  ),
                ],
              ),
            ),

            // 6 — Flickering data lines at bottom
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dataLines.asMap().entries.map((e) {
                  final opacity = ((pulse + e.key * 0.15) % 1.0).clamp(0.2, 0.7);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: const Color(0xFF2B7BE0).withValues(alpha: opacity),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCornerBrackets(Size size) {
    const c = Color(0xFF2B7BE0);
    const s = 36.0;
    const t = 2.5;
    const pad = 24.0;

    Widget bracket(double? top, double? bottom, double? left, double? right,
        bool flipH, bool flipV) {
      return Positioned(
        top: top, bottom: bottom, left: left, right: right,
        child: Transform.scale(
          scaleX: flipH ? -1 : 1,
          scaleY: flipV ? -1 : 1,
          child: SizedBox(
            width: s, height: s,
            child: CustomPaint(painter: _BracketPainter(c, t)),
          ),
        ),
      );
    }

    return [
      bracket(pad, null, pad, null, false, false), // top-left
      bracket(pad, null, null, pad, true, false),  // top-right
      bracket(null, pad, pad, null, false, true),  // bottom-left
      bracket(null, pad, null, pad, true, true),   // bottom-right
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: RefreshIndicator(
        onRefresh: () async { await _loadGoals(); await _loadStats(); },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _buildTipBanner(),
            const SizedBox(height: 24),
            _buildQuickExpense(),
            const SizedBox(height: 12),
            _buildMonthlyStats(),
            if (_goalsLoading || _goals.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildGoals(),
            ],
            const SizedBox(height: 28),
            _buildAskAI(),
          ],
        ),
      ),
        ),
        if (_expenseLoading) _buildScanOverlay(),
      ],
    );
  }

  Widget _buildTipBanner() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1.0),
          end: Alignment(0.5, 1.0),
          colors: [Color(0xFF2A7B9B), Color(0xFF3DADA0), Color(0xFF57C785)],
          stops: [0.0, 0.75, 1.0],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A7B9B).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark — clipped cleanly by the gradient container's borders
          Positioned(
            left: -70,
            bottom: -30,
            child: Opacity(
              opacity: 0.12,
              child: const Text('💡', style: TextStyle(fontSize: 140)),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('💡', style: TextStyle(fontSize: 52)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tipTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tipMessage,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section: Quick Expense ────────────────────────────────────────────
  Widget _buildQuickExpense() {
    return _Section(
      title: 'Log an Expense',
      subtitle: 'Describe your expenses in plain language — AI will handle the rest.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _expenseCtrl,
            maxLines: 4,
            minLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  'e.g. "Coffee 45 EGP, lunch with team 320, Uber to airport 150 EGP"',
              hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _expenseLoading ? null : _parseExpenses,
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              icon: _expenseLoading
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_expenseLoading ? 'Parsing...' : 'Parse & Review'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly stats strip ───────────────────────────────────────────────
  Widget _buildMonthlyStats() {
    final s        = _stats ?? {};
    final currency = s['currency']?.toString() ?? 'EGP';
    final spent    = (s['totalSpent'] as num? ?? 0).toDouble();
    final txCount  = s['transactionCount'] ?? 0;
    final topCat   = s['topCategory']?.toString() ?? '—';
    final daily    = (s['dailyAverage'] as num? ?? 0).toDouble();
    final month    = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec']
                    [DateTime.now().month - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month label
          Text(
            '$month overview',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          // Stats row
          Row(
            children: [
              _statChip(Icons.receipt_long_outlined,
                  formatCurrency(spent, currency), 'Spent'),
              _statDivider(),
              _statChip(Icons.swap_horiz_outlined,
                  '$txCount', 'Transactions'),
              _statDivider(),
              _statChip(Icons.category_outlined, topCat, 'Top Category'),
              _statDivider(),
              _statChip(Icons.today_outlined,
                  formatCurrency(daily, currency), 'Daily avg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 15, color: AppTheme.accent),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1, height: 32,
        color: AppTheme.accent.withValues(alpha: 0.15),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── Section: Savings Goals ────────────────────────────────────────────
  Widget _buildGoals() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Savings Goals',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
            const SizedBox(height: 3),
            const Text('Track your progress towards each goal.',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            if (_goalsLoading)
              const Center(child: CircularProgressIndicator())
            else
              ..._goals.take(3).map((g) => _GoalCard(goal: g)),
          ],
        ),
      ),
    );
  }

  // ── Section: Ask AI ───────────────────────────────────────────────────
  Widget _buildAskAI() {
    return _Section(
      title: 'Ask About Your Finances',
      subtitle: 'Ask anything — your spending, savings, trends, or advice.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _aiCtrl,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText:
                  'e.g. "Where am I overspending?" or "How much can I save this month?"',
              hintStyle: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed:
                  _aiLoading ? null : () => _askAI(_aiCtrl.text.trim()),
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              icon: _aiLoading
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_aiLoading ? 'Thinking...' : 'Ask AI'),
            ),
          ),
          const SizedBox(height: 20),
          Text('Suggested questions',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary.withValues(alpha: 0.8))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggested
                .map((q) => GestureDetector(
                      onTap: () => _askAI(q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.08),
                          border: Border.all(
                              color:
                                  AppTheme.accent.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(q,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w500)),
                      ),
                    ))
                .toList(),
          ),
          if (_aiQuestion != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(_aiQuestion!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.4)),
              ),
            ),
            const SizedBox(height: 12),
            if (_aiLoading)
              Row(children: [
                _aiAvatar(),
                const SizedBox(width: 10),
                const Text('Thinking...',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ])
            else if (_aiAnswer != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _aiAvatar(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        border: Border.all(color: AppTheme.fieldBorder),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: MarkdownBody(
                        data: _aiAnswer!,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primary,
                              height: 1.5),
                          strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _aiAvatar() => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.accent),
      );
}

// ── Reusable section card ─────────────────────────────────────────────────────
// ── Grid painter ─────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2B7BE0).withValues(alpha: 0.07)
      ..strokeWidth = 0.5;
    const spacing = 24.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(_GridPainter _) => false;
}

// ── Corner bracket painter ────────────────────────────────────────────────────
class _BracketPainter extends CustomPainter {
  final Color color;
  final double thickness;
  const _BracketPainter(this.color, this.thickness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const leg = 16.0;
    // Top-left L-shape
    canvas.drawLine(Offset(0, leg), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(leg, 0), paint);
  }

  @override bool shouldRepaint(_BracketPainter _) => false;
}

// ── Reusable section card ─────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Section(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Goal progress card ────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final pct      = goal.progress;
    final days     = goal.daysRemaining;
    final currency = goal.targetCurrency;
    final barColor = pct >= 1 ? AppTheme.success : AppTheme.accent;

    final daysColor = days == null
        ? AppTheme.textSecondary
        : days < 0
            ? AppTheme.danger
            : days < 30
                ? AppTheme.warning
                : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Text(goal.icon ?? '🎯',
                      style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.primary)),
                  if (goal.accountId != null && goal.accountName != null)
                    Text(goal.accountName!,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (days != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: daysColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  days < 0
                      ? 'Overdue'
                      : days == 0
                          ? 'Due today'
                          : '$days days left',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: daysColor),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AppTheme.fieldBorder,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text(formatCurrency(goal.effectiveAmount, currency),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: barColor)),
            Text(' of ${formatCurrency(goal.targetAmount, currency)}',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const Spacer(),
            Text('${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: pct >= 1 ? AppTheme.success : AppTheme.primary)),
          ]),
        ],
      ),
    );
  }
}
