import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  AggregationData? _aggregation;
  List<Insight> _insights = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  AggregationData? get aggregation => _aggregation;
  List<Insight> get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await ApiService.getExpenses();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      final newExpense = await ApiService.addExpense(expense);
      if (newExpense != null) {
        _expenses.insert(0, newExpense);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      final success = await ApiService.deleteExpense(id);
      if (success) {
        _expenses.removeWhere((e) => e.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAggregation({String period = 'month'}) async {
    try {
      _aggregation = await ApiService.getAggregation(period: period);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadInsights() async {
    try {
      _insights = await ApiService.getInsights();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadExpenses(),
      loadAggregation(),
      loadInsights(),
    ]);
  }
}
