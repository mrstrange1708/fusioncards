import 'dart:ui';
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

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  String _period = 'month';
  late AnimationController _animController;
  int touchedIndex = -1; // Added for PieChart interaction

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Longer duration for full spin
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadData() {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    _animController.reset();
    provider.loadAggregation(period: _period).then((_) {
      if (mounted) {
        _animController.forward();
      }
    });
    provider.loadInsights();
  }

  static const _catColors = <String, Color>{
    'Food': Color(0xFF4ADE80), 
    'Travel': Color(0xFF34D399),
    'Shopping': Color(0xFF10B981),
    'Entertainment': Color(0xFF059669),
    'Bills': Color(0xFF6EE7B7),
    'Health': Color(0xFFA7F3D0),
    'Education': Color(0xFFD1FAE5),
    'Other': Color(0xFF9CA3AF),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black theme
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, _) {
            final agg = provider.aggregation;
            return RefreshIndicator(
              color: const Color(0xFF4ADE80),
              backgroundColor: Colors.white.withOpacity(0.1),
              onRefresh: () async => _loadData(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Insights',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your spending analytics',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
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
                    ...provider.insights.asMap().entries.map((entry) {
                      final index = entry.key;
                      final insight = entry.value;
                      final startDelay = (0.5 + (index * 0.1)).clamp(0.0, 1.0);
                      final endDelay = (startDelay + 0.3).clamp(0.0, 1.0);

                      final slideAnim = Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animController,
                          curve: Interval(startDelay, endDelay, curve: Curves.easeOutCubic),
                        ),
                      );

                      final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animController,
                          curve: Interval(startDelay, endDelay, curve: Curves.easeIn),
                        ),
                      );

                      return FadeTransition(
                        opacity: fadeAnim,
                        child: SlideTransition(
                          position: slideAnim,
                          child: _buildInsightCard(insight),
                        ),
                      );
                    }),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: ['week', 'month'].map((p) {
              final active = _period == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_period != p) {
                      setState(() => _period = p);
                      _loadData();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF4ADE80).withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        p == 'week' ? 'This Week' : 'This Month',
                        style: TextStyle(
                          color: active ? const Color(0xFF4ADE80) : Colors.white54,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AggregationData agg) {
    final dailyAvg = agg.totalTransactions > 0
        ? agg.totalSpend / (agg.dailyBreakdown.isNotEmpty ? agg.dailyBreakdown.length : 1)
        : 0.0;
        
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _summaryCard(
              'Total Spend',
              '₹${NumberFormat('#,##,###').format(agg.totalSpend)}',
              Icons.account_balance_wallet_rounded,
              const Color(0xFF4ADE80),
              0.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              'Transactions',
              '${agg.totalTransactions}',
              Icons.receipt_long_rounded,
              const Color(0xFF4ECDC4),
              0.1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard(
              'Daily Avg',
              '₹${NumberFormat('#,##,###').format(dailyAvg)}',
              Icons.trending_up_rounded,
              const Color(0xFFFF6B6B),
              0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color, double delay) {
    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeIn),
      ),
    );
    final scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(delay, delay + 0.3, curve: Curves.easeOutBack),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: ScaleTransition(
        scale: scaleAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(AggregationData agg) {
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeIn),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: agg.categoryBreakdown.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final pct = agg.totalSpend > 0 ? (cat.total / agg.totalSpend * 100) : 0.0;
                  final color = _catColors[cat.category] ?? const Color(0xFF9CA3AF);
                  final isTouched = i == touchedIndex;
                  final radius = isTouched ? 60.0 : 50.0;
                  
                  return PieChartSectionData(
                    value: cat.total,
                    color: color,
                    radius: radius,
                    title: isTouched ? '${cat.category}\n${pct.toStringAsFixed(0)}%' : '${pct.toStringAsFixed(0)}%',
                    titlePositionPercentageOffset: isTouched ? 1.2 : 0.5,
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 12 : 11,
                      fontWeight: FontWeight.bold,
                      color: isTouched ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryList(AggregationData agg) {
    return Column(
      children: agg.categoryBreakdown.asMap().entries.map((entry) {
        final index = entry.key;
        final cat = entry.value;
        final color = _catColors[cat.category] ?? const Color(0xFF9CA3AF);
        final pct = agg.totalSpend > 0 ? (cat.total / agg.totalSpend) : 0.0;
        final iconData = Expense.categoryIcons[cat.category] ?? Icons.category_rounded;

        final startDelay = (0.2 + (index * 0.1)).clamp(0.0, 1.0);
        final endDelay = (startDelay + 0.3).clamp(0.0, 1.0);

        final slideAnim = Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(startDelay, endDelay, curve: Curves.easeOutCubic),
          ),
        );

        final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(startDelay, endDelay, curve: Curves.easeIn),
          ),
        );

        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(
            position: slideAnim,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(iconData, color: color, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                cat.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '₹${NumberFormat('#,##,###').format(cat.total)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              // We use the animation controller for the progress bars too, starting after the initial fade
                              final progressAnim = Tween<double>(begin: 0.0, end: pct).animate(
                                CurvedAnimation(
                                  parent: _animController,
                                  curve: Interval(startDelay, 1.0, curve: Curves.easeOutCubic),
                                ),
                              );
                              return LinearProgressIndicator(
                                value: progressAnim.value,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 4,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    Color bgColor;
    Color borderColor;
    IconData iconData;
    switch (insight.type) {
      case 'alert':
        bgColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red.withOpacity(0.3);
        iconData = Icons.warning_amber_rounded;
        break;
      case 'warning':
        bgColor = Colors.orange.withOpacity(0.1);
        borderColor = Colors.orange.withOpacity(0.3);
        iconData = Icons.trending_up_rounded;
        break;
      case 'success':
        bgColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green.withOpacity(0.3);
        iconData = Icons.trending_down_rounded;
        break;
      default:
        bgColor = const Color(0xFF4ADE80).withOpacity(0.1); // Green accent
        borderColor = const Color(0xFF4ADE80).withOpacity(0.3);
        iconData = Icons.info_outline_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconData, color: borderColor.withOpacity(1.0), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.5),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmptyState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.bar_chart_rounded, size: 48, color: Color(0xFF4ADE80)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No data yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add some expenses to see insights',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
