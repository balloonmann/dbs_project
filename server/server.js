// ============================================================================
// STOCK PORTFOLIO MANAGEMENT & ANALYTICS SYSTEM
// Express REST API Server
// ============================================================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------
app.use(cors());
app.use(express.json());

// Serve the frontend
app.use(express.static(path.join(__dirname, '..', 'frontend')));

// ---------------------------------------------------------------------------
// MySQL Connection Pool
// ---------------------------------------------------------------------------
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'stock_portfolio_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    multipleStatements: true,
});

// Test DB connection on startup
(async () => {
    try {
        const conn = await pool.getConnection();
        console.log('✅ MySQL database connected successfully');
        conn.release();
    } catch (err) {
        console.warn('⚠️  MySQL not available — API will return errors for DB routes.');
        console.warn('   Run database/schema.sql and seed_data.sql first.');
    }
})();

// ---------------------------------------------------------------------------
// ROUTE: Users
// ---------------------------------------------------------------------------
app.get('/api/users', async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT user_id, username, full_name, email, account_balance, created_at FROM users ORDER BY user_id'
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/users/:id', async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT user_id, username, full_name, email, account_balance, created_at FROM users WHERE user_id = ?',
            [req.params.id]
        );
        if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Stocks
// ---------------------------------------------------------------------------
app.get('/api/stocks', async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT * FROM stocks ORDER BY ticker_symbol'
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/stocks/:ticker', async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT * FROM stocks WHERE ticker_symbol = ?',
            [req.params.ticker.toUpperCase()]
        );
        if (rows.length === 0) return res.status(404).json({ error: 'Stock not found' });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Portfolio
// ---------------------------------------------------------------------------
app.get('/api/portfolio/:userId', async (req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT
                p.portfolio_id,
                s.ticker_symbol,
                s.company_name,
                s.sector,
                p.quantity,
                p.avg_buy_price,
                s.current_price,
                ROUND(p.quantity * p.avg_buy_price, 2) AS cost_basis,
                ROUND(p.quantity * s.current_price, 2) AS market_value,
                ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2) AS unrealized_gain,
                ROUND(((s.current_price - p.avg_buy_price) / p.avg_buy_price) * 100, 2) AS gain_pct
            FROM portfolios p
            INNER JOIN stocks s ON p.stock_id = s.stock_id
            WHERE p.user_id = ?
            ORDER BY market_value DESC`,
            [req.params.userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Execute Trade (calls stored procedure)
// ---------------------------------------------------------------------------
app.post('/api/portfolio/trade', async (req, res) => {
    const { userId, ticker, type, quantity } = req.body;

    if (!userId || !ticker || !type || !quantity) {
        return res.status(400).json({ error: 'Missing required fields: userId, ticker, type, quantity' });
    }

    try {
        const [results] = await pool.query(
            'CALL sp_execute_trade(?, ?, ?, ?)',
            [userId, ticker.toUpperCase(), type.toUpperCase(), parseInt(quantity)]
        );
        // sp_execute_trade returns a result set as confirmation
        res.json(results[0][0]);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Analytics — Portfolio Summary (stored procedure)
// ---------------------------------------------------------------------------
app.get('/api/analytics/summary/:userId', async (req, res) => {
    try {
        const [results] = await pool.query(
            'CALL sp_portfolio_summary(?)',
            [req.params.userId]
        );
        // Procedure returns two result sets: header + holdings
        res.json({
            summary: results[0][0] || {},
            holdings: results[1] || []
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Analytics — Profit/Loss Report (stored procedure)
// ---------------------------------------------------------------------------
app.get('/api/analytics/pnl/:userId', async (req, res) => {
    try {
        const [results] = await pool.query(
            'CALL sp_profit_loss_report(?)',
            [req.params.userId]
        );
        res.json({
            realized: results[0] || [],
            unrealized: results[1] || [],
            totals: results[2][0] || {}
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Analytics — Investment Analysis (stored procedure)
// ---------------------------------------------------------------------------
app.get('/api/analytics/investment/:userId', async (req, res) => {
    try {
        const [results] = await pool.query(
            'CALL sp_user_investment_analysis(?)',
            [req.params.userId]
        );
        res.json({
            sectors: results[0] || [],
            metrics: results[1][0] || {},
            activity: results[2] || []
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Analytics — Sector Allocation (from view)
// ---------------------------------------------------------------------------
app.get('/api/analytics/sectors/:userId', async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT * FROM vw_sector_allocation WHERE user_id = ?',
            [req.params.userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Analytics — Top Performers (from view)
// ---------------------------------------------------------------------------
app.get('/api/analytics/top-performers', async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT * FROM vw_top_performers ORDER BY performance_rank LIMIT 10'
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Transactions
// ---------------------------------------------------------------------------
app.get('/api/transactions/:userId', async (req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT
                t.transaction_id,
                s.ticker_symbol,
                s.company_name,
                t.transaction_type,
                t.quantity,
                t.price_per_unit,
                t.total_amount,
                t.transaction_date
            FROM transactions t
            INNER JOIN stocks s ON t.stock_id = s.stock_id
            WHERE t.user_id = ?
            ORDER BY t.transaction_date DESC`,
            [req.params.userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Watchlist
// ---------------------------------------------------------------------------
app.get('/api/watchlist/:userId', async (req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT
                w.watchlist_id,
                s.ticker_symbol,
                s.company_name,
                s.current_price,
                s.sector,
                w.alert_price,
                s.day_high,
                s.day_low,
                s.pe_ratio,
                w.added_at
            FROM watchlist w
            INNER JOIN stocks s ON w.stock_id = s.stock_id
            WHERE w.user_id = ?
            ORDER BY w.added_at DESC`,
            [req.params.userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Stock Price History
// ---------------------------------------------------------------------------
app.get('/api/prices/:stockId', async (req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT
                sp.price_date,
                sp.open_price,
                sp.close_price,
                sp.high_price,
                sp.low_price,
                sp.volume
            FROM stock_prices sp
            WHERE sp.stock_id = ?
            ORDER BY sp.price_date ASC`,
            [req.params.stockId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// ROUTE: Audit Log
// ---------------------------------------------------------------------------
app.get('/api/audit', async (req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT
                al.log_id,
                COALESCE(u.full_name, 'System') AS performed_by,
                al.table_name,
                al.operation,
                al.old_values,
                al.new_values,
                al.performed_at
            FROM audit_log al
            LEFT JOIN users u ON al.user_id = u.user_id
            ORDER BY al.performed_at DESC
            LIMIT 50`
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ---------------------------------------------------------------------------
// Fallback: serve frontend for SPA routes
// ---------------------------------------------------------------------------
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'frontend', 'index.html'));
});

// ---------------------------------------------------------------------------
// Stock Price Fluctuation Engine
// Simulates realistic micro price movements every 5-10 seconds.
// Each stock moves by a small random % (typically ±0.05% to ±0.3%).
// ---------------------------------------------------------------------------
function randomBetween(min, max) {
    return Math.random() * (max - min) + min;
}

async function fluctuateStockPrices() {
    try {
        const [stocks] = await pool.query(
            'SELECT stock_id, current_price, day_high, day_low FROM stocks'
        );

        for (const stock of stocks) {
            const price = parseFloat(stock.current_price);

            // Random % change between -0.3% and +0.3%, slight upward bias
            const changePct = randomBetween(-0.30, 0.32) / 100;
            let newPrice = price * (1 + changePct);

            // Keep price above ₹1
            newPrice = Math.max(newPrice, 1.0);
            newPrice = Math.round(newPrice * 100) / 100;

            // Update day_high / day_low if needed
            const dayHigh = Math.max(parseFloat(stock.day_high), newPrice);
            const dayLow = Math.min(parseFloat(stock.day_low), newPrice);

            await pool.query(
                'UPDATE stocks SET current_price = ?, day_high = ?, day_low = ? WHERE stock_id = ?',
                [newPrice, dayHigh, dayLow, stock.stock_id]
            );
        }
    } catch (err) {
        // Silently ignore if DB is unavailable
    }
}

// Schedule fluctuations at random intervals between 5-10 seconds
function scheduleNextFluctuation() {
    const delay = randomBetween(5000, 10000);
    setTimeout(async () => {
        await fluctuateStockPrices();
        scheduleNextFluctuation();
    }, delay);
}

// ---------------------------------------------------------------------------
// Start Server
// ---------------------------------------------------------------------------
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Frontend served at http://localhost:${PORT}`);

    // Start price fluctuation engine
    scheduleNextFluctuation();
    console.log('Stock price fluctuation engine started (5-10s intervals)');
});

