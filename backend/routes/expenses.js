const express = require('express');
const router = express.Router();
const { addExpense, getExpenses, deleteExpense, getAggregation } = require('../controllers/expenseController');
const { getInsights } = require('../services/insightService');

// CRUD routes
router.post('/', addExpense);
router.get('/', getExpenses);
router.delete('/:id', deleteExpense);

// Analytics routes
router.get('/aggregation', getAggregation);
router.get('/insights', getInsights);

module.exports = router;
