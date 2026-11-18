import 'dart:convert';

import 'package:rose_valley/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EarningExpenseChart extends StatefulWidget {
  const EarningExpenseChart({super.key});

  @override
  State<EarningExpenseChart> createState() => _EarningExpenseChartState();
}

class _EarningExpenseChartState extends State<EarningExpenseChart> {
  static const Color incomeColor = Colors.deepPurple;
  static const Color expenseColor = Colors.teal;

  static const List<String> months = [
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
    "Jan",
    "Feb",
    "Mar",
  ];

  List<double> income = List.filled(12, 0);
  List<double> expense = List.filled(12, 0);

  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await ApiService.post(context, "/admin/report/analysis");

      if (!mounted) return;

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List incomeApi = data["income"] ?? [];
        final List expenseApi = data["expenses"] ?? [];

        final newIncome = List.generate(
          12,
          (i) => i < incomeApi.length ? (incomeApi[i] as num).toDouble() : 0.0,
        );

        final newExpense = List.generate(
          12,
          (i) =>
              i < expenseApi.length ? (expenseApi[i] as num).toDouble() : 0.0,
        );

        setState(() {
          income = newIncome;
          expense = newExpense;

          totalIncome = income.fold(0, (a, b) => a + b);
          totalExpense = expense.fold(0, (a, b) => a + b);

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  double get maxValue {
    final highestIncome = income.reduce((a, b) => a > b ? a : b);
    final highestExpense = expense.reduce((a, b) => a > b ? a : b);

    final highest = highestIncome > highestExpense
        ? highestIncome
        : highestExpense;

    return highest <= 0 ? 100 : highest * 1.25;
  }

  String formatAmount(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    }

    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }

  Widget _legendItem(Color color, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.055),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '₹${formatAmount(amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 230,
      child: BarChart(
        BarChartData(
          maxY: maxValue,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          groupsSpace: 8,

          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(6),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final title = rodIndex == 0 ? 'Income' : 'Expenses';

                return BarTooltipItem(
                  '$title\n₹${rod.toY.toStringAsFixed(0)}',
                  TextStyle(
                    color: rodIndex == 0 ? incomeColor : expenseColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 0.8,
                dashArray: [4, 4],
              );
            },
          ),

          borderData: FlBorderData(show: false),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxValue / 4,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Text(
                      formatAmount(value),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black45,
                      ),
                    ),
                  );
                },
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= months.length) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[index],
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          barGroups: _barGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _barGroups() {
    return List.generate(12, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 3,
        barRods: [
          BarChartRodData(
            toY: income[i],
            color: incomeColor,
            width: 7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),

          BarChartRodData(
            toY: expense[i],
            color: expenseColor,
            width: 7,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: incomeColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: incomeColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Earning & Expenses",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      "Monthly financial overview",
                      style: TextStyle(fontSize: 10, color: Colors.black45),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  "Apr - Mar",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary cards
          Row(
            children: [
              _summaryCard(
                title: "Total Income",
                amount: totalIncome,
                color: incomeColor,
                icon: Icons.trending_up_rounded,
              ),

              const SizedBox(width: 9),

              _summaryCard(
                title: "Total Expenses",
                amount: totalExpense,
                color: expenseColor,
                icon: Icons.trending_down_rounded,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Chart title and legends
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Monthly Analysis",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),

              _legendItem(incomeColor, "Income"),

              const SizedBox(width: 12),

              _legendItem(expenseColor, "Expenses"),
            ],
          ),

          const SizedBox(height: 12),

          // Chart
          _buildChart(),

          const SizedBox(height: 8),

          Divider(color: Colors.grey.shade100, height: 1),

          const SizedBox(height: 10),

          // Footer
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.black38,
              ),

              const SizedBox(width: 6),

              const Expanded(
                child: Text(
                  "Tap bars to view monthly amount",
                  style: TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ),

              Text(
                "Net: ₹${formatAmount(totalIncome - totalExpense)}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: totalIncome >= totalExpense
                      ? incomeColor
                      : expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
