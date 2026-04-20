import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _noteController = TextEditingController();
  String _amount = '0';
  String _selectedCategory = 'Other';
  final DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (value == 'C') {
        _amount = '0';
      } else if (value == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          // Prevent too many decimals
          if (_amount.contains('.')) {
            final parts = _amount.split('.');
            if (parts.length > 1 && parts[1].length >= 2) return;
          }
          // Prevent huge numbers
          if (_amount.length < 10) {
            _amount += value;
          }
        }
      }
    });
  }

  Future<void> _submitExpense() async {
    final amountParsed = double.tryParse(_amount) ?? 0.0;
    if (amountParsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount greater than 0'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final expense = Expense(
      amount: amountParsed,
      category: _selectedCategory,
      note: _noteController.text,
      date: _selectedDate,
    );

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final success = await provider.addExpense(expense);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _noteController.clear();
      setState(() {
        _amount = '0';
        _selectedCategory = 'Other';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Expense saved!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else if (mounted) {
      final errorMessage = provider.error ?? 'Failed to save expense';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Select Category',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: Expense.categories.length,
                      itemBuilder: (context, index) {
                        final category = Expense.categories[index];
                        final icon = Expense.categoryIcons[category] ?? Icons.category;
                        return ListTile(
                          leading: Icon(icon, color: const Color(0xFF4ADE80)),
                          title: Text(
                            category,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Deep black background
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _amount = '0';
                        _noteController.clear();
                      });
                    },
                    child: Row(
                      children: [
                        Icon(Icons.close, color: const Color(0xFF4ADE80).withOpacity(0.8), size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'CANCEL',
                          style: TextStyle(
                            color: const Color(0xFF4ADE80).withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitExpense,
                    child: Row(
                      children: [
                        if (_isSubmitting)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4ADE80),
                            ),
                          )
                        else
                          const Icon(Icons.check, color: Color(0xFF4ADE80), size: 20),
                        const SizedBox(width: 4),
                        const Text(
                          'SAVE',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Selectors Row (Account & Category)
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectorButton(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Account',
                            onTap: () {
                              // Not implemented yet based on user requirements
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectorButton(
                            icon: Icons.sell_rounded,
                            label: _selectedCategory,
                            onTap: _showCategoryPicker,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes Area
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: TextField(
                            controller: _noteController,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Add notes',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Amount Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              child: Text(
                                _amount,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _onKeypadTap('⌫'),
                            onLongPress: () => _onKeypadTap('C'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.backspace_outlined,
                                color: Color(0xFF4ADE80),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Keypad
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 36) / 4;
                        final height = width * 0.8; // Aspect ratio for buttons

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildKey(label: '7', width: width, height: height),
                                _buildKey(label: '8', width: width, height: height),
                                _buildKey(label: '9', width: width, height: height),
                                _buildKey(label: 'C', width: width, height: height, isOp: true),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildKey(label: '4', width: width, height: height),
                                _buildKey(label: '5', width: width, height: height),
                                _buildKey(label: '6', width: width, height: height),
                                _buildKey(label: '+', width: width, height: height, isOp: true),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildKey(label: '1', width: width, height: height),
                                _buildKey(label: '2', width: width, height: height),
                                _buildKey(label: '3', width: width, height: height),
                                _buildKey(label: '-', width: width, height: height, isOp: true),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildKey(label: '.', width: width, height: height),
                                _buildKey(label: '0', width: width, height: height),
                                _buildKey(label: '00', width: width, height: height),
                                _buildKey(label: '=', width: width, height: height, isOp: true),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date & Time Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: 1,
                              height: 12,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(_selectedDate),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
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

  Widget _buildSelectorButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF4ADE80), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKey({
    required String label,
    required double width,
    required double height,
    bool isOp = false,
  }) {
    // For math operators, we just ignore them for now except C
    final bool isUnimplementedOp = (label == '+' || label == '-' || label == '=');

    return GestureDetector(
      onTap: isUnimplementedOp ? null : () => _onKeypadTap(label),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isOp 
              ? const Color(0xFF4ADE80).withOpacity(0.1) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOp 
                ? const Color(0xFF4ADE80).withOpacity(0.2) 
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: isOp ? FontWeight.bold : FontWeight.w400,
              color: isOp ? const Color(0xFF4ADE80) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
