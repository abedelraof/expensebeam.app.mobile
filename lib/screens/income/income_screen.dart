import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/income.dart';
import '../../core/utils/formatters.dart';
import 'edit_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  List<Income> _incomes = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String? _source;
  DateTimeRange? _dateRange;

  static const _sources = [
    'Salary', 'Business', 'Freelance', 'Investment', 'Rental', 'Gift', 'Other'
  ];

  static const _sourceColors = {
    'Salary': Colors.blue,
    'Business': Colors.green,
    'Freelance': Colors.orange,
    'Investment': Colors.purple,
    'Rental': Colors.teal,
    'Gift': Colors.pink,
    'Other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = <String, String>{
        if (_searchCtrl.text.isNotEmpty) 'search': _searchCtrl.text,
        if (_source != null) 'source': _source!,
        if (_dateRange != null)
          'startDate': DateFormat('yyyy-MM-dd').format(_dateRange!.start),
        if (_dateRange != null)
          'endDate': DateFormat('yyyy-MM-dd').format(_dateRange!.end),
      };
      final res = await ApiClient.get('/income', params: params);
      final data = res.data;
      final list =
          data is List ? data : (data['income'] ?? data['data'] ?? []);
      _incomes = (list as List).map((e) => Income.fromJson(e)).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(Income income) async {
    try {
      await ApiClient.delete('/income/${income.id}');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilter),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditIncomeScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search income...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        })
                    : null,
              ),
              onChanged: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _incomes.isEmpty
                    ? const Center(child: Text('No income entries'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _incomes.length,
                        itemBuilder: (ctx, i) {
                          final inc = _incomes[i];
                          return Dismissible(
                            key: Key(inc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: Theme.of(ctx).colorScheme.error,
                              child: const Icon(Icons.delete,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) => _delete(inc),
                            child: Card(
                              child: ListTile(
                                onTap: () async {
                                  await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              EditIncomeScreen(income: inc)));
                                  _load();
                                },
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _sourceColors[inc.source] ?? Colors.grey,
                                  child: Text(inc.source[0],
                                      style: const TextStyle(
                                          color: Colors.white)),
                                ),
                                title: Text(inc.description),
                                subtitle: Text(
                                    '${inc.source} • ${formatDate(inc.date)}'),
                                trailing: Text(
                                  formatCurrency(inc.amount, inc.currency),
                                  style: TextStyle(
                                      color: Theme.of(ctx).colorScheme.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilter() {
    String? tmpSource = _source;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filter', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: tmpSource,
                decoration: const InputDecoration(labelText: 'Source'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._sources.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (v) => setS(() => tmpSource = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  _source = tmpSource;
                  Navigator.pop(ctx);
                  _load();
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
