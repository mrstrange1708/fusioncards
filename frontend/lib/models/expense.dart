import 'package:flutter/material.dart';

class Expense {
  final int? id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final DateTime? createdAt;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      note: json['note'] ?? '',
      date: DateTime.parse(json['date']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String().split('T')[0],
    };
  }

  static const List<String> categories = [
    'Food',
    'Travel',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Education',
    'Other',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.fastfood_rounded,
    'Travel': Icons.flight_takeoff_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Health': Icons.medical_services_rounded,
    'Education': Icons.school_rounded,
    'Other': Icons.category_rounded,
  };
}

class Insight {
  final String type;
  final String icon;
  final String title;
  final String message;
  final String category;
  final int changePercent;

  Insight({
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    required this.category,
    required this.changePercent,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      type: json['type'] ?? 'info',
      icon: json['icon'] ?? '📊',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      category: json['category'] ?? '',
      changePercent: json['changePercent'] ?? 0,
    );
  }
}

class AggregationData {
  final String period;
  final double totalSpend;
  final int totalTransactions;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<DailyBreakdown> dailyBreakdown;

  AggregationData({
    required this.period,
    required this.totalSpend,
    required this.totalTransactions,
    required this.categoryBreakdown,
    required this.dailyBreakdown,
  });

  factory AggregationData.fromJson(Map<String, dynamic> json) {
    return AggregationData(
      period: json['period'] ?? 'all',
      totalSpend: double.parse(json['totalSpend'].toString()),
      totalTransactions: json['totalTransactions'] ?? 0,
      categoryBreakdown: (json['categoryBreakdown'] as List? ?? [])
          .map((e) => CategoryBreakdown.fromJson(e))
          .toList(),
      dailyBreakdown: (json['dailyBreakdown'] as List? ?? [])
          .map((e) => DailyBreakdown.fromJson(e))
          .toList(),
    );
  }
}

class CategoryBreakdown {
  final String category;
  final double total;
  final int count;
  final double average;

  CategoryBreakdown({
    required this.category,
    required this.total,
    required this.count,
    required this.average,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'],
      total: double.parse(json['total'].toString()),
      count: json['count'] ?? 0,
      average: double.parse(json['average'].toString()),
    );
  }
}

class DailyBreakdown {
  final String date;
  final double total;

  DailyBreakdown({required this.date, required this.total});

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyBreakdown(
      date: json['date'],
      total: double.parse(json['total'].toString()),
    );
  }
}
