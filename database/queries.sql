-- ============================================================================
-- STOCK PORTFOLIO MANAGEMENT & ANALYTICS SYSTEM
-- SQL Queries Collection
-- ============================================================================
-- Categories:
--   1. Basic CRUD Operations
--   2. JOIN Queries
--   3. Aggregate Queries
--   4. Analytical / Portfolio Performance Queries
--   5. Subqueries & Nested Queries
-- ============================================================================

USE stock_portfolio_db;

-- ============================================================================
-- 1. BASIC CRUD OPERATIONS
-- ============================================================================

-- Q1: SELECT — Retrieve all stocks in the Technology sector
SELECT stock_id, ticker_symbol, company_name, current_price, pe_ratio
FROM stocks
WHERE sector = 'Technology'
ORDER BY current_price DESC;

-- Q2: INSERT — Register a new user
INSERT INTO users (username, email, password_hash, full_name)
VALUES ('new_investor', 'new.investor@email.com', SHA2('NewPass123!', 256), 'New Investor');

-- Q3: UPDATE — Update stock's current price (simulating market movement)
UPDATE stocks
SET current_price = 195.20, day_high = 196.00, day_low = 192.50
WHERE ticker_symbol = 'AAPL';

-- Q4: DELETE — Remove a stock from watchlist
DELETE FROM watchlist
WHERE user_id = 1 AND stock_id = 4;

-- Q5: SELECT with multiple conditions
SELECT u.full_name, u.account_balance
FROM users u
WHERE u.account_balance > 90000
  AND u.created_at >= '2024-01-01'
ORDER BY u.account_balance DESC;


-- ============================================================================
-- 2. JOIN QUERIES
-- ============================================================================

-- Q6: INNER JOIN — Show each user's portfolio holdings with stock details
SELECT
    u.full_name        AS investor,
    s.ticker_symbol    AS ticker,
    s.company_name     AS company,
    p.quantity,
    p.avg_buy_price,
    s.current_price,
    ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2) AS unrealized_pnl
FROM portfolios p
INNER JOIN users u  ON p.user_id  = u.user_id
INNER JOIN stocks s ON p.stock_id = s.stock_id
ORDER BY u.full_name, unrealized_pnl DESC;

-- Q7: LEFT JOIN — All users with their holdings (including users with no holdings)
SELECT
    u.full_name,
    COALESCE(s.ticker_symbol, '— No Holdings —') AS ticker,
    COALESCE(p.quantity, 0)                       AS shares_held
FROM users u
LEFT JOIN portfolios p ON u.user_id  = p.user_id
LEFT JOIN stocks s     ON p.stock_id = s.stock_id
ORDER BY u.full_name;

-- Q8: INNER JOIN — Full transaction history with stock names
SELECT
    t.transaction_id,
    u.full_name,
    s.ticker_symbol,
    t.transaction_type,
    t.quantity,
    t.price_per_unit,
    t.total_amount,
    t.transaction_date
FROM transactions t
INNER JOIN users u  ON t.user_id  = u.user_id
INNER JOIN stocks s ON t.stock_id = s.stock_id
ORDER BY t.transaction_date DESC;

-- Q9: LEFT JOIN — Stocks that no one currently holds
SELECT s.ticker_symbol, s.company_name, s.sector
FROM stocks s
LEFT JOIN portfolios p ON s.stock_id = p.stock_id
WHERE p.portfolio_id IS NULL;


-- ============================================================================
-- 3. AGGREGATE QUERIES
-- ============================================================================

-- Q10: Total investment per user (SUM + GROUP BY)
SELECT
    u.full_name,
    COUNT(p.portfolio_id)                                  AS num_holdings,
    SUM(p.quantity)                                        AS total_shares,
    ROUND(SUM(p.quantity * p.avg_buy_price), 2)            AS total_invested,
    ROUND(SUM(p.quantity * s.current_price), 2)            AS current_value
FROM users u
INNER JOIN portfolios p ON u.user_id  = p.user_id
INNER JOIN stocks s     ON p.stock_id = s.stock_id
GROUP BY u.user_id, u.full_name
ORDER BY current_value DESC;

-- Q11: Average buy price per sector per user
SELECT
    u.full_name,
    s.sector,
    ROUND(AVG(p.avg_buy_price), 2) AS avg_sector_buy_price,
    SUM(p.quantity)                AS total_shares_in_sector
FROM portfolios p
INNER JOIN users u  ON p.user_id  = u.user_id
INNER JOIN stocks s ON p.stock_id = s.stock_id
GROUP BY u.user_id, u.full_name, s.sector
ORDER BY u.full_name, s.sector;

-- Q12: Sector-wise market cap distribution
SELECT
    sector,
    COUNT(*)                           AS num_stocks,
    ROUND(SUM(market_cap), 2)          AS total_market_cap,
    ROUND(AVG(current_price), 2)       AS avg_price,
    ROUND(AVG(pe_ratio), 2)            AS avg_pe
FROM stocks
GROUP BY sector
HAVING COUNT(*) >= 1
ORDER BY total_market_cap DESC;

-- Q13: Monthly transaction volume summary
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS month,
    transaction_type,
    COUNT(*)                               AS num_transactions,
    SUM(quantity)                           AS total_shares,
    ROUND(SUM(total_amount), 2)            AS total_value
FROM transactions
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m'), transaction_type
ORDER BY month, transaction_type;


-- ============================================================================
-- 4. ANALYTICAL / PORTFOLIO PERFORMANCE QUERIES
-- ============================================================================

-- Q14: Unrealized Profit/Loss per holding (gain %, absolute gain)
SELECT
    u.full_name,
    s.ticker_symbol,
    p.quantity,
    p.avg_buy_price,
    s.current_price,
    ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2)              AS absolute_gain,
    ROUND(((s.current_price - p.avg_buy_price) / p.avg_buy_price) * 100, 2) AS gain_pct
FROM portfolios p
INNER JOIN users u  ON p.user_id  = u.user_id
INNER JOIN stocks s ON p.stock_id = s.stock_id
ORDER BY gain_pct DESC;

-- Q15: Top 5 most profitable holdings across all users
SELECT
    u.full_name,
    s.ticker_symbol,
    ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2) AS profit
FROM portfolios p
INNER JOIN users u  ON p.user_id  = u.user_id
INNER JOIN stocks s ON p.stock_id = s.stock_id
ORDER BY profit DESC
LIMIT 5;

-- Q16: Portfolio allocation percentage per user
SELECT
    u.full_name,
    s.ticker_symbol,
    ROUND(p.quantity * s.current_price, 2) AS holding_value,
    ROUND(
        (p.quantity * s.current_price) /
        SUM(p.quantity * s.current_price) OVER (PARTITION BY u.user_id) * 100
    , 2) AS allocation_pct
FROM portfolios p
INNER JOIN users u  ON p.user_id  = u.user_id
INNER JOIN stocks s ON p.stock_id = s.stock_id
ORDER BY u.full_name, allocation_pct DESC;

-- Q17: 10-day price trend analysis (daily return %)
SELECT
    s.ticker_symbol,
    sp.price_date,
    sp.close_price,
    ROUND(
        ((sp.close_price - LAG(sp.close_price) OVER (
            PARTITION BY sp.stock_id ORDER BY sp.price_date
        )) / LAG(sp.close_price) OVER (
            PARTITION BY sp.stock_id ORDER BY sp.price_date
        )) * 100
    , 2) AS daily_return_pct
FROM stock_prices sp
INNER JOIN stocks s ON sp.stock_id = s.stock_id
ORDER BY s.ticker_symbol, sp.price_date;


-- ============================================================================
-- 5. SUBQUERIES & NESTED QUERIES
-- ============================================================================

-- Q18: Users whose total portfolio value exceeds the average
SELECT u.full_name, portfolio_val.total_value
FROM users u
INNER JOIN (
    SELECT p.user_id,
           ROUND(SUM(p.quantity * s.current_price), 2) AS total_value
    FROM portfolios p
    INNER JOIN stocks s ON p.stock_id = s.stock_id
    GROUP BY p.user_id
) AS portfolio_val ON u.user_id = portfolio_val.user_id
WHERE portfolio_val.total_value > (
    SELECT AVG(sub.total_value)
    FROM (
        SELECT SUM(p2.quantity * s2.current_price) AS total_value
        FROM portfolios p2
        INNER JOIN stocks s2 ON p2.stock_id = s2.stock_id
        GROUP BY p2.user_id
    ) AS sub
)
ORDER BY portfolio_val.total_value DESC;

-- Q19: Stocks that have been bought by more than 2 different users
SELECT s.ticker_symbol, s.company_name, buyer_count.num_buyers
FROM stocks s
INNER JOIN (
    SELECT stock_id, COUNT(DISTINCT user_id) AS num_buyers
    FROM transactions
    WHERE transaction_type = 'BUY'
    GROUP BY stock_id
    HAVING COUNT(DISTINCT user_id) > 2
) AS buyer_count ON s.stock_id = buyer_count.stock_id
ORDER BY buyer_count.num_buyers DESC;

-- Q20: Correlated subquery — Users who have at least one holding
--      outperforming the sector average current price
SELECT DISTINCT u.full_name
FROM users u
WHERE EXISTS (
    SELECT 1
    FROM portfolios p
    INNER JOIN stocks s ON p.stock_id = s.stock_id
    WHERE p.user_id = u.user_id
      AND s.current_price > (
          SELECT AVG(s2.current_price)
          FROM stocks s2
          WHERE s2.sector = s.sector
      )
);

-- Q21: Most traded stock (by total transaction volume)
SELECT s.ticker_symbol, s.company_name,
    (SELECT SUM(t.quantity)
     FROM transactions t
     WHERE t.stock_id = s.stock_id) AS total_volume
FROM stocks s
WHERE s.stock_id IN (
    SELECT stock_id FROM transactions
)
ORDER BY total_volume DESC
LIMIT 3;

-- ============================================================================
-- END OF QUERIES
-- ============================================================================
