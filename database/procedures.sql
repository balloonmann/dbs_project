-- ============================================================================
-- STOCK PORTFOLIO MANAGEMENT & ANALYTICS SYSTEM
-- Stored Procedures
-- ============================================================================
-- Procedures:
--   1. sp_portfolio_summary      — Full portfolio overview for a user
--   2. sp_profit_loss_report     — Realized + unrealized P&L
--   3. sp_user_investment_analysis — Sector-wise breakdown & risk metrics
--   4. sp_execute_trade          — Atomic BUY/SELL with validation
-- ============================================================================

USE stock_portfolio_db;

DELIMITER $$

-- ============================================================================
-- PROCEDURE 1: sp_portfolio_summary
-- Returns a comprehensive portfolio summary for a given user:
--   holdings, current values, gains, allocation percentages.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_portfolio_summary$$

CREATE PROCEDURE sp_portfolio_summary(IN p_user_id INT)
BEGIN
    DECLARE v_user_name VARCHAR(120);
    DECLARE v_balance   DECIMAL(15,2);

    -- Validate user exists
    SELECT full_name, account_balance
    INTO v_user_name, v_balance
    FROM users
    WHERE user_id = p_user_id;

    IF v_user_name IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: User not found.';
    END IF;

    -- Header info
    SELECT
        v_user_name                               AS investor_name,
        v_balance                                  AS cash_balance,
        COALESCE(SUM(p.quantity * s.current_price), 0) AS portfolio_value,
        v_balance + COALESCE(SUM(p.quantity * s.current_price), 0) AS total_net_worth
    FROM portfolios p
    INNER JOIN stocks s ON p.stock_id = s.stock_id
    WHERE p.user_id = p_user_id;

    -- Detailed holdings
    SELECT
        s.ticker_symbol,
        s.company_name,
        s.sector,
        p.quantity,
        p.avg_buy_price,
        s.current_price,
        ROUND(p.quantity * p.avg_buy_price, 2)                               AS cost_basis,
        ROUND(p.quantity * s.current_price, 2)                               AS market_value,
        ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2)           AS unrealized_gain,
        ROUND(((s.current_price - p.avg_buy_price) / p.avg_buy_price) * 100, 2) AS gain_pct,
        ROUND(
            (p.quantity * s.current_price) /
            (SELECT SUM(p2.quantity * s2.current_price)
             FROM portfolios p2
             INNER JOIN stocks s2 ON p2.stock_id = s2.stock_id
             WHERE p2.user_id = p_user_id) * 100
        , 2) AS allocation_pct
    FROM portfolios p
    INNER JOIN stocks s ON p.stock_id = s.stock_id
    WHERE p.user_id = p_user_id
    ORDER BY market_value DESC;

END$$


-- ============================================================================
-- PROCEDURE 2: sp_profit_loss_report
-- Calculates both realized P&L (from sells) and unrealized P&L (current holdings).
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_profit_loss_report$$

CREATE PROCEDURE sp_profit_loss_report(IN p_user_id INT)
BEGIN
    -- Realized P&L (from SELL transactions)
    SELECT
        'REALIZED' AS pnl_type,
        s.ticker_symbol,
        t.quantity                                                         AS shares_sold,
        t.price_per_unit                                                   AS sell_price,
        COALESCE(
            (SELECT p.avg_buy_price
             FROM portfolios p
             WHERE p.user_id = t.user_id AND p.stock_id = t.stock_id),
            t.price_per_unit
        )                                                                  AS avg_cost,
        ROUND(
            (t.price_per_unit - COALESCE(
                (SELECT p.avg_buy_price
                 FROM portfolios p
                 WHERE p.user_id = t.user_id AND p.stock_id = t.stock_id),
                t.price_per_unit
            )) * t.quantity
        , 2)                                                               AS realized_pnl,
        t.transaction_date
    FROM transactions t
    INNER JOIN stocks s ON t.stock_id = s.stock_id
    WHERE t.user_id = p_user_id
      AND t.transaction_type = 'SELL'
    ORDER BY t.transaction_date DESC;

    -- Unrealized P&L (current holdings)
    SELECT
        'UNREALIZED' AS pnl_type,
        s.ticker_symbol,
        p.quantity                                                     AS shares_held,
        p.avg_buy_price                                                AS avg_cost,
        s.current_price,
        ROUND((s.current_price - p.avg_buy_price) * p.quantity, 2)     AS unrealized_pnl,
        ROUND(((s.current_price - p.avg_buy_price) / p.avg_buy_price) * 100, 2) AS gain_pct
    FROM portfolios p
    INNER JOIN stocks s ON p.stock_id = s.stock_id
    WHERE p.user_id = p_user_id
    ORDER BY unrealized_pnl DESC;

    -- Summary totals
    SELECT
        COALESCE((
            SELECT ROUND(SUM(
                (t.price_per_unit - COALESCE(
                    (SELECT p.avg_buy_price
                     FROM portfolios p
                     WHERE p.user_id = t.user_id AND p.stock_id = t.stock_id),
                    t.price_per_unit
                )) * t.quantity
            ), 2)
            FROM transactions t
            WHERE t.user_id = p_user_id AND t.transaction_type = 'SELL'
        ), 0) AS total_realized_pnl,

        COALESCE((
            SELECT ROUND(SUM((s.current_price - p.avg_buy_price) * p.quantity), 2)
            FROM portfolios p
            INNER JOIN stocks s ON p.stock_id = s.stock_id
            WHERE p.user_id = p_user_id
        ), 0) AS total_unrealized_pnl;

END$$


-- ============================================================================
-- PROCEDURE 3: sp_user_investment_analysis
-- Sector-wise investment breakdown, diversification score, risk metrics.
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_user_investment_analysis$$

CREATE PROCEDURE sp_user_investment_analysis(IN p_user_id INT)
BEGIN
    -- Sector-wise allocation
    SELECT
        s.sector,
        COUNT(*)                                           AS num_holdings,
        SUM(p.quantity)                                    AS total_shares,
        ROUND(SUM(p.quantity * p.avg_buy_price), 2)        AS total_invested,
        ROUND(SUM(p.quantity * s.current_price), 2)        AS current_value,
        ROUND(
            SUM(p.quantity * s.current_price) /
            (SELECT SUM(p2.quantity * s2.current_price)
             FROM portfolios p2
             INNER JOIN stocks s2 ON p2.stock_id = s2.stock_id
             WHERE p2.user_id = p_user_id) * 100
        , 2)                                               AS sector_allocation_pct,
        ROUND(
            (SUM(p.quantity * s.current_price) - SUM(p.quantity * p.avg_buy_price))
            / SUM(p.quantity * p.avg_buy_price) * 100
        , 2)                                               AS sector_return_pct
    FROM portfolios p
    INNER JOIN stocks s ON p.stock_id = s.stock_id
    WHERE p.user_id = p_user_id
    GROUP BY s.sector
    ORDER BY current_value DESC;

    -- Overall investment metrics
    SELECT
        COUNT(DISTINCT s.sector)                                        AS sectors_invested,
        COUNT(*)                                                        AS total_positions,
        ROUND(SUM(p.quantity * p.avg_buy_price), 2)                     AS total_cost_basis,
        ROUND(SUM(p.quantity * s.current_price), 2)                     AS total_market_value,
        ROUND(AVG(s.pe_ratio), 2)                                       AS weighted_avg_pe,
        ROUND(
            (SUM(p.quantity * s.current_price) - SUM(p.quantity * p.avg_buy_price))
            / SUM(p.quantity * p.avg_buy_price) * 100
        , 2)                                                            AS overall_return_pct,
        CASE
            WHEN COUNT(DISTINCT s.sector) >= 4 THEN 'Well Diversified'
            WHEN COUNT(DISTINCT s.sector) >= 2 THEN 'Moderately Diversified'
            ELSE 'Concentrated'
        END                                                             AS diversification_rating
    FROM portfolios p
    INNER JOIN stocks s ON p.stock_id = s.stock_id
    WHERE p.user_id = p_user_id;

    -- Transaction activity summary
    SELECT
        transaction_type,
        COUNT(*)                          AS num_trades,
        ROUND(SUM(total_amount), 2)       AS total_value,
        ROUND(AVG(total_amount), 2)       AS avg_trade_size,
        MIN(transaction_date)             AS first_trade,
        MAX(transaction_date)             AS last_trade
    FROM transactions
    WHERE user_id = p_user_id
    GROUP BY transaction_type;

END$$


-- ============================================================================
-- PROCEDURE 4: sp_execute_trade
-- Atomically executes a BUY or SELL trade with full validation:
--   - Checks user balance (BUY) or share count (SELL)
--   - Updates portfolio (insert or adjust quantity/avg price)
--   - Records transaction
--   - Adjusts user balance
-- ============================================================================
DROP PROCEDURE IF EXISTS sp_execute_trade$$

CREATE PROCEDURE sp_execute_trade(
    IN p_user_id   INT,
    IN p_ticker    VARCHAR(10),
    IN p_type      ENUM('BUY','SELL'),
    IN p_quantity  INT
)
BEGIN
    DECLARE v_stock_id      INT;
    DECLARE v_price         DECIMAL(12,2);
    DECLARE v_total         DECIMAL(15,2);
    DECLARE v_balance       DECIMAL(15,2);
    DECLARE v_portfolio_id  INT DEFAULT NULL;
    DECLARE v_current_qty   INT DEFAULT 0;
    DECLARE v_current_avg   DECIMAL(12,2) DEFAULT 0;
    DECLARE v_new_avg       DECIMAL(12,2);

    -- Start atomic transaction
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Resolve stock
    SELECT stock_id, current_price
    INTO v_stock_id, v_price
    FROM stocks
    WHERE ticker_symbol = p_ticker;

    IF v_stock_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Invalid ticker symbol.';
    END IF;

    -- Calculate total trade value
    SET v_total = p_quantity * v_price;

    -- Get user balance
    SELECT account_balance INTO v_balance
    FROM users
    WHERE user_id = p_user_id
    FOR UPDATE;  -- Lock the row

    -- Check existing portfolio position
    SELECT portfolio_id, quantity, avg_buy_price
    INTO v_portfolio_id, v_current_qty, v_current_avg
    FROM portfolios
    WHERE user_id = p_user_id AND stock_id = v_stock_id
    FOR UPDATE;

    -- ---- BUY LOGIC ----
    IF p_type = 'BUY' THEN
        -- Validate sufficient balance
        IF v_balance < v_total THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Error: Insufficient account balance.';
        END IF;

        -- Update or insert portfolio
        IF v_portfolio_id IS NOT NULL THEN
            -- Weighted average price
            SET v_new_avg = ROUND(
                ((v_current_qty * v_current_avg) + (p_quantity * v_price))
                / (v_current_qty + p_quantity)
            , 2);

            UPDATE portfolios
            SET quantity      = v_current_qty + p_quantity,
                avg_buy_price = v_new_avg
            WHERE portfolio_id = v_portfolio_id;
        ELSE
            INSERT INTO portfolios (user_id, stock_id, quantity, avg_buy_price)
            VALUES (p_user_id, v_stock_id, p_quantity, v_price);

            SET v_portfolio_id = LAST_INSERT_ID();
        END IF;

        -- Deduct balance
        UPDATE users
        SET account_balance = account_balance - v_total
        WHERE user_id = p_user_id;

    -- ---- SELL LOGIC ----
    ELSEIF p_type = 'SELL' THEN
        -- Validate holding exists and has enough shares
        IF v_portfolio_id IS NULL OR v_current_qty < p_quantity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Error: Insufficient shares to sell.';
        END IF;

        -- Update or remove portfolio entry
        IF v_current_qty = p_quantity THEN
            DELETE FROM portfolios WHERE portfolio_id = v_portfolio_id;
        ELSE
            UPDATE portfolios
            SET quantity = v_current_qty - p_quantity
            WHERE portfolio_id = v_portfolio_id;
        END IF;

        -- Credit balance
        UPDATE users
        SET account_balance = account_balance + v_total
        WHERE user_id = p_user_id;
    END IF;

    -- Record the transaction
    INSERT INTO transactions (user_id, stock_id, portfolio_id, transaction_type, quantity, price_per_unit)
    VALUES (p_user_id, v_stock_id, v_portfolio_id, p_type, p_quantity, v_price);

    COMMIT;

    -- Return confirmation
    SELECT
        p_type        AS trade_type,
        p_ticker      AS ticker,
        p_quantity    AS shares,
        v_price       AS price_per_share,
        v_total       AS total_value,
        (SELECT account_balance FROM users WHERE user_id = p_user_id) AS new_balance,
        'Trade executed successfully.' AS status;

END$$

DELIMITER ;

-- ============================================================================
-- END OF STORED PROCEDURES
-- ============================================================================
