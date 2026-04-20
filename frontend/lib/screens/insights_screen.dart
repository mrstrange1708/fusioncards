import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    provider.loadAggregation(period: _period);
    provider.loadInsights();
  }

  static const _catColors = <String, Color>{
    'Food': Color(0xFFFF6B6B),
    'Travel': Color(0xFF4ECDC4),
    'Shopping': Color(0xFFFFE66D),
    'Entertainment': Color(0xFFA78BFA),
    'Bills': Color(0xFF60A5FA),
    'Health': Color(0xFF34D399),
    'Education': Color(0xFFFBBF24),
    'Other': Color(0xFF9CA3AF),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, _) {
            final agg = provider.aggregation;
            return RefreshIndicator(
              color: const Color(0xFF6C63FF),
              backgroundColor: const Color(0xFF1E1E2C),
              onRefresh: () async => _loadData(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 10),
                  const Text('Insights', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Your spending analytics', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 20),
                  // Period toggle
                  _buildPeriodToggle(),
                  const SizedBox(height: 20),
                  // Summary cards
                  if (agg != null) ...[
                    _buildSummaryCards(agg),
                    const SizedBox(height: 24),
                    if (agg.categoryBreakdown.isNotEmpty) ...[
                      _buildSectionTitle('Category Breakdown'),
                      const SizedBox(height: 16),
                      _buildPieChart(agg),
                      const SizedBox(height: 16),
                      _buildCategoryList(agg),
                      const SizedBox(height: 24),
                    ],
                  ],
                  // Smart insights
                  if (provider.insights.isNotEmpty) ...[
                    _buildSectionTitle('Smart Insights'),
                    const SizedBox(height: 12),
                    ...provider.insights.map(_buildInsightCard),
                  ],
                  if (agg == null && provider.insights.isEmpty)
                    _buildEmptyState(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: ['week', 'month'].map((p) {
          final active = _period == p;
          return Expanded(
            child: GestureDetector(
              onTap: () { setState(() => _period = p); _loadData(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: active ? const Color(0xFF6C63FF) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(p == 'week' ? 'This Week' : 'This Month', style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 14))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(AggregationData agg) {
    final dailyAvg = agg.totalTransactions > 0 ? agg.totalSpend / (agg.dailyBreakdown.isNotEmpty ? agg.dailyBreakdown.length : 1) : 0.0;
    return Row(
      children: [
        Expanded(child: _summaryCard('Total Spend', '₹${NumberFormat('#,##,###').format(agg.totalSpend)}', Icons.account_balance_wallet_rounded, const Color(0xFF6C63FF))),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Transactions', '${agg.totalTransactions}', Icons.receipt_long_rounded, const Color(0xFF4ECDC4))),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard('Daily Avg', '₹${NumberFormat('#,##,###').format(dailyAvg)}', Icons.trending_up_rounded, const Color(0xFFFF6B6B))),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPieChart(AggregationData agg) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(16)),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: agg.categoryBreakdown.map((cat) {
            final pct = agg.totalSpend > 0 ? (cat.total / agg.totalSpend * 100) : 0.0;
            final color = _catColors[cat.category] ?? const Color(0xFF9CA3AF);
            return PieChartSectionData(
              value: cat.total,
              color: color,
              radius: 50,
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryList(AggregationData agg) {
    return Column(
      children: agg.categoryBreakdown.map((cat) {
        final color = _catColors[cat.category] ?? const Color(0xFF9CA3AF);
        final pct = agg.totalSpend > 0 ? (cat.total / agg.totalSpend) : 0.0;
        final emoji = Expense.categoryIcons[cat.category] ?? '📦';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cat.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                  Text('₹${NumberFormat('#,##,###').format(cat.total)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    Color bgColor;
    Color borderColor;
    switch (insight.type) {
      case 'alert': bgColor = Colors.red.withOpacity(0.1); borderColor = Colors.red.withOpacity(0.3); break;
      case 'warning': bgColor = Colors.orange.withOpacity(0.1); borderColor = Colors.orange.withOpacity(0.3); break;
      case 'success': bgColor = Colors.green.withOpacity(0.1); borderColor = Colors.green.withOpacity(0.3); break;
      default: bgColor = const Color(0xFF6C63FF).withOpacity(0.1); borderColor = const Color(0xFF6C63FF).withOpacity(0.3);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(insight.message, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5), letterSpacing: 1.2));
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('No data yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Add some expenses to see insights', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
