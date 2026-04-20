import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class ApiService {
  // Use environment variable for the backend URL
  static String get baseUrl {
    return dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000/api';
  }

  // Add a new expense
  static Future<Expense?> addExpense(Expense expense) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(expense.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Expense.fromJson(data['expense']);
      } else {
        throw Exception('Failed to add expense: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Fetch all expenses
  static Future<List<Expense>> getExpenses({
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse('$baseUrl/expenses').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['expenses'] as List)
            .map((e) => Expense.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to fetch expenses');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete an expense
  static Future<bool> deleteExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get aggregation data
  static Future<AggregationData> getAggregation({String period = 'month'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/aggregation?period=$period'),
      );

      if (response.statusCode == 200) {
        return AggregationData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch aggregation');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get smart insights
  static Future<List<Insight>> getInsights() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/insights'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['insights'] as List)
            .map((e) => Insight.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to fetch insights');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
