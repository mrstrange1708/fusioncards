const pool = require('../config/db');

// Add a new expense
const addExpense = async (req, res) => {
  try {
    const { amount, category, note, date } = req.body;

    if (!amount || !category) {
      return res.status(400).json({ error: 'Amount and category are required' });
    }

    if (amount <= 0) {
      return res.status(400).json({ error: 'Amount must be greater than 0' });
    }

    const validCategories = ['Food', 'Travel', 'Shopping', 'Entertainment', 'Bills', 'Health', 'Education', 'Other'];
    if (!validCategories.includes(category)) {
      return res.status(400).json({ error: `Invalid category. Must be one of: ${validCategories.join(', ')}` });
    }

    const result = await pool.query(
      `INSERT INTO expenses (amount, category, note, date) 
       VALUES ($1, $2, $3, $4) 
       RETURNING *`,
      [amount, category, note || '', date || new Date().toISOString().split('T')[0]]
    );

    res.status(201).json({
      message: 'Expense added successfully',
      expense: result.rows[0]
    });
  } catch (error) {
    console.error('Error adding expense:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Fetch all expenses (with optional filters)
const getExpenses = async (req, res) => {
  try {
    const { category, startDate, endDate, groupBy } = req.query;

    let query = 'SELECT * FROM expenses WHERE 1=1';
    const params = [];
    let paramIndex = 1;

    if (category) {
      query += ` AND category = $${paramIndex++}`;
      params.push(category);
    }

    if (startDate) {
      query += ` AND date >= $${paramIndex++}`;
      params.push(startDate);
    }

    if (endDate) {
      query += ` AND date <= $${paramIndex++}`;
      params.push(endDate);
    }

    query += ' ORDER BY date DESC, created_at DESC';

    const result = await pool.query(query, params);

    // Group results if requested
    if (groupBy === 'date') {
      const grouped = {};
      result.rows.forEach(expense => {
        const dateKey = new Date(expense.date).toISOString().split('T')[0];
        if (!grouped[dateKey]) grouped[dateKey] = [];
        grouped[dateKey].push(expense);
      });
      return res.json({ expenses: grouped, total: result.rows.length });
    }

    if (groupBy === 'category') {
      const grouped = {};
      result.rows.forEach(expense => {
        if (!grouped[expense.category]) grouped[expense.category] = [];
        grouped[expense.category].push(expense);
      });
      return res.json({ expenses: grouped, total: result.rows.length });
    }

    res.json({ expenses: result.rows, total: result.rows.length });
  } catch (error) {
    console.error('Error fetching expenses:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete an expense
const deleteExpense = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM expenses WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Expense not found' });
    }

    res.json({ message: 'Expense deleted successfully', expense: result.rows[0] });
  } catch (error) {
    console.error('Error deleting expense:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Aggregation: total spend + category-wise breakdown
const getAggregation = async (req, res) => {
  try {
    const { period } = req.query; // 'week' or 'month'

    let dateFilter = '';
    if (period === 'week') {
      dateFilter = "WHERE date >= CURRENT_DATE - INTERVAL '7 days'";
    } else if (period === 'month') {
      dateFilter = "WHERE date >= DATE_TRUNC('month', CURRENT_DATE)";
    }

    // Total spending
    const totalResult = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) as total_spend, 
              COUNT(*) as total_transactions
       FROM expenses ${dateFilter}`
    );

    // Category-wise breakdown
    const categoryResult = await pool.query(
      `SELECT category, 
              SUM(amount) as total, 
              COUNT(*) as count,
              ROUND(AVG(amount), 2) as average
       FROM expenses ${dateFilter}
       GROUP BY category 
       ORDER BY total DESC`
    );

    // Daily breakdown
    const dailyResult = await pool.query(
      `SELECT date, SUM(amount) as total
       FROM expenses ${dateFilter}
       GROUP BY date 
       ORDER BY date DESC
       LIMIT 30`
    );

    res.json({
      period: period || 'all',
      totalSpend: parseFloat(totalResult.rows[0].total_spend),
      totalTransactions: parseInt(totalResult.rows[0].total_transactions),
      categoryBreakdown: categoryResult.rows.map(row => ({
        category: row.category,
        total: parseFloat(row.total),
        count: parseInt(row.count),
        average: parseFloat(row.average)
      })),
      dailyBreakdown: dailyResult.rows.map(row => ({
        date: new Date(row.date).toISOString().split('T')[0],
        total: parseFloat(row.total)
      }))
    });
  } catch (error) {
    console.error('Error getting aggregation:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = {
  addExpense,
  getExpenses,
  deleteExpense,
  getAggregation
};
