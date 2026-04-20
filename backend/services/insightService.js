const pool = require('../config/db');

const getInsights = async (req, res) => {
  try {
    const insights = [];

    // ──────────────────────────────────────────────
    // 1. Week-over-week category comparison
    // ──────────────────────────────────────────────
    const weekComparison = await pool.query(`
      WITH current_week AS (
        SELECT category, COALESCE(SUM(amount), 0) as total
        FROM expenses
        WHERE date >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY category
      ),
      previous_week AS (
        SELECT category, COALESCE(SUM(amount), 0) as total
        FROM expenses
        WHERE date >= CURRENT_DATE - INTERVAL '14 days'
          AND date < CURRENT_DATE - INTERVAL '7 days'
        GROUP BY category
      )
      SELECT 
        COALESCE(cw.category, pw.category) as category,
        COALESCE(cw.total, 0) as current_total,
        COALESCE(pw.total, 0) as previous_total
      FROM current_week cw
      FULL OUTER JOIN previous_week pw ON cw.category = pw.category
      ORDER BY COALESCE(cw.total, 0) DESC
    `);

    weekComparison.rows.forEach(row => {
      const current = parseFloat(row.current_total);
      const previous = parseFloat(row.previous_total);

      if (previous > 0 && current > 0) {
        const changePercent = Math.round(((current - previous) / previous) * 100);
        if (changePercent > 0) {
          insights.push({
            type: 'warning',
            icon: '📈',
            title: `${row.category} Spending Up`,
            message: `You spent ${changePercent}% more on ${row.category} this week compared to last week (₹${current.toFixed(0)} vs ₹${previous.toFixed(0)})`,
            category: row.category,
            changePercent: changePercent
          });
        } else if (changePercent < -10) {
          insights.push({
            type: 'success',
            icon: '📉',
            title: `${row.category} Spending Down`,
            message: `Great! You spent ${Math.abs(changePercent)}% less on ${row.category} this week (₹${current.toFixed(0)} vs ₹${previous.toFixed(0)})`,
            category: row.category,
            changePercent: changePercent
          });
        }
      } else if (current > 0 && previous === 0) {
        insights.push({
          type: 'info',
          icon: '🆕',
          title: `New ${row.category} Spending`,
          message: `You started spending on ${row.category} this week — ₹${current.toFixed(0)} total`,
          category: row.category,
          changePercent: 100
        });
      }
    });

    // ──────────────────────────────────────────────
    // 2. Top spending category this month
    // ──────────────────────────────────────────────
    const topCategory = await pool.query(`
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE date >= DATE_TRUNC('month', CURRENT_DATE)
      GROUP BY category
      ORDER BY total DESC
      LIMIT 1
    `);

    if (topCategory.rows.length > 0) {
      insights.push({
        type: 'info',
        icon: '🏆',
        title: 'Top Category This Month',
        message: `Your biggest expense category this month is ${topCategory.rows[0].category} at ₹${parseFloat(topCategory.rows[0].total).toFixed(0)}`,
        category: topCategory.rows[0].category,
        changePercent: 0
      });
    }

    // ──────────────────────────────────────────────
    // 3. Daily average spending this week
    // ──────────────────────────────────────────────
    const dailyAvg = await pool.query(`
      SELECT 
        COALESCE(SUM(amount), 0) as total,
        COUNT(DISTINCT date) as days
      FROM expenses
      WHERE date >= CURRENT_DATE - INTERVAL '7 days'
    `);

    if (dailyAvg.rows.length > 0 && parseInt(dailyAvg.rows[0].days) > 0) {
      const avg = parseFloat(dailyAvg.rows[0].total) / parseInt(dailyAvg.rows[0].days);
      insights.push({
        type: 'info',
        icon: '📊',
        title: 'Daily Average',
        message: `You're spending an average of ₹${avg.toFixed(0)} per day this week`,
        category: 'all',
        changePercent: 0
      });
    }

    // ──────────────────────────────────────────────
    // 4. Spending spike detection
    // ──────────────────────────────────────────────
    const spikeDetection = await pool.query(`
      WITH weekly_avg AS (
        SELECT category, AVG(weekly_total) as avg_weekly
        FROM (
          SELECT category, 
                 DATE_TRUNC('week', date) as week,
                 SUM(amount) as weekly_total
          FROM expenses
          WHERE date >= CURRENT_DATE - INTERVAL '28 days'
            AND date < CURRENT_DATE - INTERVAL '7 days'
          GROUP BY category, DATE_TRUNC('week', date)
        ) sub
        GROUP BY category
      ),
      current_week AS (
        SELECT category, SUM(amount) as total
        FROM expenses
        WHERE date >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY category
      )
      SELECT cw.category, cw.total as current_total, wa.avg_weekly
      FROM current_week cw
      JOIN weekly_avg wa ON cw.category = wa.category
      WHERE cw.total > wa.avg_weekly * 1.5
    `);

    spikeDetection.rows.forEach(row => {
      insights.push({
        type: 'alert',
        icon: '🚨',
        title: `Unusual ${row.category} Spending`,
        message: `Your ${row.category} spending this week (₹${parseFloat(row.current_total).toFixed(0)}) is significantly higher than your weekly average (₹${parseFloat(row.avg_weekly).toFixed(0)})`,
        category: row.category,
        changePercent: Math.round(((parseFloat(row.current_total) - parseFloat(row.avg_weekly)) / parseFloat(row.avg_weekly)) * 100)
      });
    });

    // ──────────────────────────────────────────────
    // 5. Monthly total vs previous month
    // ──────────────────────────────────────────────
    const monthComparison = await pool.query(`
      SELECT 
        COALESCE((SELECT SUM(amount) FROM expenses WHERE date >= DATE_TRUNC('month', CURRENT_DATE)), 0) as current_month,
        COALESCE((SELECT SUM(amount) FROM expenses WHERE date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') AND date < DATE_TRUNC('month', CURRENT_DATE)), 0) as previous_month
    `);

    if (monthComparison.rows.length > 0) {
      const current = parseFloat(monthComparison.rows[0].current_month);
      const previous = parseFloat(monthComparison.rows[0].previous_month);
      if (previous > 0 && current > 0) {
        const pct = Math.round(((current - previous) / previous) * 100);
        const direction = pct > 0 ? 'more' : 'less';
        insights.push({
          type: pct > 0 ? 'warning' : 'success',
          icon: pct > 0 ? '💸' : '💰',
          title: 'Monthly Comparison',
          message: `You've spent ${Math.abs(pct)}% ${direction} this month (₹${current.toFixed(0)}) compared to last month (₹${previous.toFixed(0)})`,
          category: 'all',
          changePercent: pct
        });
      }
    }

    // Sort: warnings & alerts first
    const priority = { alert: 0, warning: 1, success: 2, info: 3 };
    insights.sort((a, b) => (priority[a.type] || 99) - (priority[b.type] || 99));

    res.json({
      insights,
      generatedAt: new Date().toISOString(),
      totalInsights: insights.length
    });
  } catch (error) {
    console.error('Error generating insights:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
};

module.exports = { getInsights };
