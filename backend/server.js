const express = require('express');
const cors = require('cors');
require('dotenv').config();

const pool = require('./config/db');
const expenseRoutes = require('./routes/expenses');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Auto-initialize database table on startup
const initializeDatabase = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS expenses (
        id SERIAL PRIMARY KEY,
        amount DECIMAL(10, 2) NOT NULL,
        category VARCHAR(50) NOT NULL,
        note TEXT DEFAULT '',
        date DATE NOT NULL DEFAULT CURRENT_DATE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);`);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);`);
    console.log('✅ Database tables ready');
  } catch (error) {
    console.error('❌ Database init error:', error.message);
  }
};

// Routes
app.use('/api/expenses', expenseRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Root
app.get('/', (req, res) => {
  res.json({
    message: 'Smart Expense Tracker API',
    version: '1.0.0',
    endpoints: {
      health: 'GET /api/health',
      addExpense: 'POST /api/expenses',
      getExpenses: 'GET /api/expenses',
      deleteExpense: 'DELETE /api/expenses/:id',
      aggregation: 'GET /api/expenses/aggregation?period=week|month',
      insights: 'GET /api/expenses/insights'
    }
  });
});

// Start server
initializeDatabase().then(() => {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
  });
});
