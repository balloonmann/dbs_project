-- ============================================================================
-- STOCK PORTFOLIO MANAGEMENT & ANALYTICS SYSTEM
-- Triggers
-- ============================================================================
-- Triggers:
--   1. trg_after_buy_insert       — Auto-log every BUY transaction
--   2. trg_after_sell_insert      — Auto-log every SELL transaction
--   3. trg_audit_portfolio_update — Audit trail for portfolio modifications
--   4. trg_audit_portfolio_delete — Audit trail for portfolio deletions
-- ============================================================================

USE stock_portfolio_db;

DELIMITER $$

-- ============================================================================
-- TRIGGER 1: trg_after_buy_insert
-- Fires AFTER a BUY transaction is inserted.
-- Logs the purchase details to the audit_log table.
-- ============================================================================
DROP TRIGGER IF EXISTS trg_after_buy_insert$$

CREATE TRIGGER trg_after_buy_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type = 'BUY' THEN
        INSERT INTO audit_log (user_id, table_name, operation, new_values)
        VALUES (
            NEW.user_id,
            'transactions',
            'INSERT',
            JSON_OBJECT(
                'transaction_id', NEW.transaction_id,
                'action',         'BUY',
                'stock_id',       NEW.stock_id,
                'quantity',       NEW.quantity,
                'price_per_unit', NEW.price_per_unit,
                'total_amount',   NEW.quantity * NEW.price_per_unit,
                'executed_at',    NEW.transaction_date
            )
        );
    END IF;
END$$


-- ============================================================================
-- TRIGGER 2: trg_after_sell_insert
-- Fires AFTER a SELL transaction is inserted.
-- Logs the sale details and calculates realized P&L in the audit entry.
-- ============================================================================
DROP TRIGGER IF EXISTS trg_after_sell_insert$$

CREATE TRIGGER trg_after_sell_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_avg_cost DECIMAL(12,2) DEFAULT 0;

    IF NEW.transaction_type = 'SELL' THEN
        -- Retrieve the average buy price for P&L calculation
        SELECT avg_buy_price INTO v_avg_cost
        FROM portfolios
        WHERE user_id = NEW.user_id AND stock_id = NEW.stock_id
        LIMIT 1;

        INSERT INTO audit_log (user_id, table_name, operation, new_values)
        VALUES (
            NEW.user_id,
            'transactions',
            'INSERT',
            JSON_OBJECT(
                'transaction_id', NEW.transaction_id,
                'action',         'SELL',
                'stock_id',       NEW.stock_id,
                'quantity',       NEW.quantity,
                'price_per_unit', NEW.price_per_unit,
                'total_amount',   NEW.quantity * NEW.price_per_unit,
                'avg_buy_cost',   COALESCE(v_avg_cost, 0),
                'realized_pnl',  ROUND((NEW.price_per_unit - COALESCE(v_avg_cost, NEW.price_per_unit)) * NEW.quantity, 2),
                'executed_at',    NEW.transaction_date
            )
        );
    END IF;
END$$


-- ============================================================================
-- TRIGGER 3: trg_audit_portfolio_update
-- Fires AFTER any portfolio row is updated.
-- Captures old and new values for a complete audit trail.
-- ============================================================================
DROP TRIGGER IF EXISTS trg_audit_portfolio_update$$

CREATE TRIGGER trg_audit_portfolio_update
AFTER UPDATE ON portfolios
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (user_id, table_name, operation, old_values, new_values)
    VALUES (
        NEW.user_id,
        'portfolios',
        'UPDATE',
        JSON_OBJECT(
            'portfolio_id',  OLD.portfolio_id,
            'quantity',      OLD.quantity,
            'avg_buy_price', OLD.avg_buy_price,
            'last_updated',  OLD.last_updated
        ),
        JSON_OBJECT(
            'portfolio_id',  NEW.portfolio_id,
            'quantity',      NEW.quantity,
            'avg_buy_price', NEW.avg_buy_price,
            'last_updated',  NEW.last_updated
        )
    );
END$$


-- ============================================================================
-- TRIGGER 4: trg_audit_portfolio_delete
-- Fires AFTER a portfolio row is deleted (e.g., user sells all shares).
-- Preserves the deleted record in the audit log.
-- ============================================================================
DROP TRIGGER IF EXISTS trg_audit_portfolio_delete$$

CREATE TRIGGER trg_audit_portfolio_delete
AFTER DELETE ON portfolios
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (user_id, table_name, operation, old_values)
    VALUES (
        OLD.user_id,
        'portfolios',
        'DELETE',
        JSON_OBJECT(
            'portfolio_id',  OLD.portfolio_id,
            'stock_id',      OLD.stock_id,
            'quantity',      OLD.quantity,
            'avg_buy_price', OLD.avg_buy_price,
            'first_purchased', OLD.first_purchased,
            'reason',        'All shares sold or position closed'
        )
    );
END$$

DELIMITER ;

-- ============================================================================
-- END OF TRIGGERS
-- ============================================================================
