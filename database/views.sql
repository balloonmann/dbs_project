-- ============================================================================
-- STOCK PORTFOLIO MANAGEMENT & ANALYTICS SYSTEM
-- Views
-- ============================================================================
-- Views:
--   1. vw_portfolio_overview  — Enriched portfolio with gains and allocation
--   2. vw_sector_allocation   — Per-user sector distribution
--   3. vw_top_performers      — Stocks ranked by return percentage
-- ============================================================================

USE stock_portfolio_db;

-- ============================================================================
-- VIEW 1: vw_portfolio_overview
-- A comprehensive view joining users, portfolios, and stocks.
-- Pre-calculates market value, gains, and allocation for quick dashboarding.
-- ============================================================================
DROP VIEW IF EXISTS vw_portfolio_overview;

CREATE VIEW vw_portfolio_overview AS
SELECT
    u.user_id,
    u.full_name                                                      AS investor_name,
    u.account_balance                                                AS cash_balance,
    s.stock_id,
    s.ticker_symbol,
    s.company_name,
    s.sector,
    p.portfolio_id,
    p.quantity,
    p.avg_buy_price,
    s.current_price,
    ROUND(p.quantity * p.avg_buy_price, 2)                           AS cost_basis,
    ROUND(p.quantity * s.current_price, 2)                           AS market_value,
    ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2)       AS unrealized_gain,
    ROUND(
        ((s.current_price - p.avg_buy_price) / p.avg_buy_price) * 100
    , 2)                                                             AS gain_percentage,
    p.first_purchased,
    DATEDIFF(CURDATE(), p.first_purchased)                           AS holding_days
FROM portfolios p
INNER JOIN users u  ON p.user_id  = u.user_id
INNER JOIN stocks s ON p.stock_id = s.stock_id;


-- ============================================================================
-- VIEW 2: vw_sector_allocation
-- Shows each user's investment distribution across market sectors.
-- ============================================================================
DROP VIEW IF EXISTS vw_sector_allocation;

CREATE VIEW vw_sector_allocation AS
SELECT
    u.user_id,
    u.full_name                                        AS investor_name,
    s.sector,
    COUNT(p.portfolio_id)                              AS num_positions,
    SUM(p.quantity)                                     AS total_shares,
    ROUND(SUM(p.quantity * s.current_price), 2)         AS sector_value,
    ROUND(
        SUM(p.quantity * s.current_price) /
        (SELECT SUM(p2.quantity * s2.current_price)
         FROM portfolios p2
         INNER JOIN stocks s2 ON p2.stock_id = s2.stock_id
         WHERE p2.user_id = u.user_id) * 100
    , 2)                                               AS allocation_pct
FROM portfolios p
INNER JOIN users u  ON p.user_id  = u.user_id
INNER JOIN stocks s ON p.stock_id = s.stock_id
GROUP BY u.user_id, u.full_name, s.sector;


-- ============================================================================
-- VIEW 3: vw_top_performers
-- Ranks all current holdings by percentage gain. Useful for leaderboard-style
-- analytics dashboards.
-- ============================================================================
DROP VIEW IF EXISTS vw_top_performers;

CREATE VIEW vw_top_performers AS
SELECT
    u.full_name                                                      AS investor_name,
    s.ticker_symbol,
    s.company_name,
    p.quantity,
    p.avg_buy_price,
    s.current_price,
    ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2)       AS absolute_gain,
    ROUND(
        ((s.current_price - p.avg_buy_price) / p.avg_buy_price) * 100
    , 2)                                                             AS return_pct,
    RANK() OVER (ORDER BY
        ((s.current_price - p.avg_buy_price) / p.avg_buy_price) * 100 DESC
    )                                                                AS performance_rank
FROM portfolios p
INNER JOIN users u  ON p.user_id  = u.user_id
INNER JOIN stocks s ON p.stock_id = s.stock_id;

-- ============================================================================
-- END OF VIEWS
-- ============================================================================
