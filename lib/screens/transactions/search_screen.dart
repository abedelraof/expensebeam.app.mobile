import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/expense.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/expense_tile.dart';
import 'edit_expense_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();

  List<Expense> _results   = [];
  bool _loading            = false;
  bool _hasSearched        = false;

  // Filters
  String? _selectedCategory;
  DateTimeRange? _dateRange;

  // Categories for chips
  List<String> _categories = [];

  // Recent searches (in-memory)
  static final List<String> _recents = [];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _quickCategories = [
    'Food', 'Transport', 'Shopping', 'Utilities',
    'Health', 'Entertainment', 'Education', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res  = await ApiClient.get('/categories');
      final data = res.data;
      List<dynamic> list = [];
      if (data is List) list = data;
      else if (data is Map) {
        for (final key in ['categories', 'data', 'items']) {
          if (data[key] is List) { list = data[key]; break; }
        }
      }
      final names = list
          .map((e) => (e is Map ? e['name'] : e)?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (mounted) setState(() => _categories = names);
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty && _selectedCategory == null && _dateRange == null) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }

    // Save to recents
    final q = query.trim();
    if (q.isNotEmpty && !_recents.contains(q)) {
      _recents.insert(0, q);
      if (_recents.length > 6) _recents.removeLast();
    }

    setState(() { _loading = true; _hasSearched = true; });

    try {
      final params = <String, String>{
        'page': '1',
        'limit': '30',
        'sort': 'date_desc',
        if (q.isNotEmpty) 'search': q,
        if (_selectedCategory != null) 'category': _selectedCategory!,
        if (_dateRange != null)
          'startDate': DateFormat('yyyy-MM-dd').format(_dateRange!.start),
        if (_dateRange != null)
          'endDate': DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      };
      final res  = await ApiClient.get('/expenses', params: params);
      final data = res.data;

      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        for (final key in ['expenses', 'data', 'items', 'results']) {
          if (data[key] is List) { list = data[key]; break; }
        }
      }

      final fetched = <Expense>[];
      for (final e in list) {
        try { fetched.add(Expense.fromJson(Map<String, dynamic>.from(e))); }
        catch (_) {}
      }

      if (mounted) setState(() => _results = fetched);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _dateRange        = null;
    });
    _search(_searchCtrl.text);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
      _search(_searchCtrl.text);
    }
  }

  bool get _hasFilters => _selectedCategory != null || _dateRange != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            // Search field
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.fieldBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  onChanged: (v) {
                    setState(() {});
                    if (v.isEmpty) _search('');
                  },
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    hintStyle: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.textSecondary, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: AppTheme.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search('');
                              _focusNode.requestFocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            // Filter icon
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showFilterSheet,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _hasFilters
                      ? AppTheme.accent.withValues(alpha: 0.12)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasFilters
                        ? AppTheme.accent.withValues(alpha: 0.4)
                        : AppTheme.fieldBorder,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.tune,
                        color: _hasFilters
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        size: 20),
                    if (_hasFilters)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    final displayCats = _categories.isNotEmpty ? _categories : _quickCategories;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Date chip
          if (_dateRange != null)
            _chip(
              '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}',
              active: true,
              onTap: () { setState(() => _dateRange = null); _search(_searchCtrl.text); },
              trailing: Icons.close,
            ),
          // Category chips
          ...displayCats.map((cat) => _chip(
                cat,
                active: _selectedCategory == cat,
                onTap: () {
                  setState(() => _selectedCategory =
                      _selectedCategory == cat ? null : cat);
                  _search(_searchCtrl.text);
                },
              )),
        ],
      ),
    );
  }

  Widget _chip(String label,
      {bool active = false, VoidCallback? onTap, IconData? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(
            horizontal: trailing != null ? 10 : 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accent.withValues(alpha: 0.12)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppTheme.accent.withValues(alpha: 0.5)
                : AppTheme.fieldBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal,
                    color: active ? AppTheme.accent : AppTheme.textSecondary)),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing, size: 14, color: AppTheme.accent),
            ],
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) return _buildIdleState();

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 64,
                color: AppTheme.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No results found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
            const SizedBox(height: 6),
            const Text('Try a different keyword or adjust filters',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            if (_hasFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear filters')),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            '${_results.length} result${_results.length == 1 ? '' : 's'}',
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            itemCount: _results.length,
            itemBuilder: (ctx, i) => ExpenseTile(
              expense: _results[i],
              onDeleted: () => _search(_searchCtrl.text),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            EditExpenseScreen(expense: _results[i])));
                _search(_searchCtrl.text);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Idle state (no search yet) ────────────────────────────────────────
  Widget _buildIdleState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_recents.isNotEmpty) ...[
          _sectionLabel('Recent Searches'),
          const SizedBox(height: 8),
          ..._recents.map((q) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history,
                    size: 18, color: AppTheme.textSecondary),
                title: Text(q,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.primary)),
                trailing: const Icon(Icons.north_west,
                    size: 16, color: AppTheme.textSecondary),
                onTap: () {
                  _searchCtrl.text = q;
                  _search(q);
                },
                dense: true,
              )),
          const SizedBox(height: 20),
        ],
        _sectionLabel('Browse by Category'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_categories.isNotEmpty ? _categories : _quickCategories)
              .map((cat) => GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _search(_searchCtrl.text);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.2)),
                      ),
                      child: Text(cat,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w500)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5),
      );

  // ── Filter sheet ──────────────────────────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary)),
                if (_hasFilters)
                  TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearFilters();
                      },
                      child: const Text('Clear all')),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_dateRange == null
                  ? 'Pick Date Range'
                  : '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d').format(_dateRange!.end)}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _pickDateRange();
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
