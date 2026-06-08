import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  List<dynamic> _trend = [];
  List<dynamic> _categories = [];
  List<dynamic> _topDays = [];
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fmt = DateFormat('yyyy-MM-dd');
    final params = {
      'startDate': fmt.format(_dateRange.start),
      'endDate': fmt.format(_dateRange.end),
    };
    try {
      final results = await Future.wait([
        ApiClient.get('/reports/spending-trend', params: params),
        ApiClient.get('/reports/category-breakdown', params: params),
        ApiClient.get('/reports/top-days', params: params),
      ]);
      final trendData = results[0].data;
      _trend = trendData is List ? trendData : (trendData['data'] ?? []);
      final catData = results[1].data;
      _categories = catData is List ? catData : (catData['data'] ?? []);
      final topData = results[2].data;
      _topDays = topData is List ? topData : (topData['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      _dateRange = range;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date range picker
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                          '${DateFormat('MMM d').format(_dateRange.start)} – ${DateFormat('MMM d').format(_dateRange.end)}'),
                      onPressed: _pickRange,
                    ),
                  ),
                  _buildTrendChart(),
                  const SizedBox(height: 16),
                  _buildCategoryChart(),
                  const SizedBox(height: 16),
                  _buildTopDays(),
                ],
              ),
            ),
    );
  }

  Widget _buildTrendChart() {
    if (_trend.isEmpty) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No spending trend data')));
    }
    final spots = _trend.asMap().entries.map((e) {
      final val = (e.value['total'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), val);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending Trend',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    ),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_categories.isEmpty) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(16), child: Text('No category data')));
    }

    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple,
      Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
    ];

    final sections = _categories.asMap().entries.map((e) {
      final pct = (e.value['percentage'] as num?)?.toDouble() ?? 0;
      return PieChartSectionData(
        value: pct,
        color: colors[e.key % colors.length],
        title: '${pct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                    )),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _categories.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[e.key % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.value['category']?.toString() ?? 'Other',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ..._categories.map((cat) => ListTile(
                  dense: true,
                  title: Text(cat['category']?.toString() ?? 'Other'),
                  trailing: Text(
                    formatCurrency(
                        (cat['total'] as num?)?.toDouble() ?? 0,
                        cat['currency']?.toString() ?? 'EGP'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDays() {
    if (_topDays.isEmpty) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(16), child: Text('No top days data')));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Spending Days',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._topDays.take(5).map((day) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_today, size: 18),
                  title: Text(day['date']?.toString() ?? ''),
                  trailing: Text(
                    formatCurrency(
                        (day['total'] as num?)?.toDouble() ?? 0,
                        day['currency']?.toString() ?? 'EGP'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
