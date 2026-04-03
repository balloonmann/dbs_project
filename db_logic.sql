USE stock_portfolio_db;

DELIMITER $$

-- Procedure to automatically calculate current_value and profit_loss for all portfolio entries of a user
DROP PROCEDURE IF EXISTS Calculate_Portfolio_Performance$$

CREATE PROCEDURE Calculate_Portfolio_Performance(IN p_user_id INT)
BEGIN
    UPDATE Portfolio p
    JOIN Stocks s ON p.stock_symbol = s.stock_symbol
    SET 
        p.current_value = p.quantity * s.current_price,
        p.profit_loss = (p.quantity * s.current_price) - p.total_investment
    WHERE p.user_id = p_user_id;
END$$

-- Trigger to update Portfolio when a Transaction occurs
DROP TRIGGER IF EXISTS After_Transaction_Insert$$

CREATE TRIGGER After_Transaction_Insert
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    DECLARE v_count INT;

    -- Check if user already has this stock in their portfolio
    SELECT COUNT(*) INTO v_count 
    FROM Portfolio 
    WHERE user_id = NEW.user_id AND stock_symbol = NEW.stock_symbol;

    IF NEW.transaction_type = 'BUY' THEN
        IF v_count = 0 THEN
            -- First time buying this stock
            INSERT INTO Portfolio (user_id, stock_symbol, quantity, avg_buy_price, total_investment)
            VALUES (NEW.user_id, NEW.stock_symbol, NEW.quantity, NEW.price_per_share, NEW.quantity * NEW.price_per_share);
        ELSE
            -- Update existing portfolio entry
            UPDATE Portfolio
            SET 
                total_investment = total_investment + (NEW.quantity * NEW.price_per_share),
                quantity = quantity + NEW.quantity,
                avg_buy_price = (total_investment + (NEW.quantity * NEW.price_per_share)) / (quantity + NEW.quantity)
            WHERE user_id = NEW.user_id AND stock_symbol = NEW.stock_symbol;
        END IF;
        
    ELSEIF NEW.transaction_type = 'SELL' THEN
        IF v_count > 0 THEN
             -- Update existing portfolio entry (reduce quantity and investment proportionally)
             -- We don't change avg_buy_price on sell, but we reduce total_investment proportionally
            UPDATE Portfolio
            SET 
                total_investment = total_investment - (avg_buy_price * NEW.quantity),
                quantity = quantity - NEW.quantity
            WHERE user_id = NEW.user_id AND stock_symbol = NEW.stock_symbol;
            
            -- If quantity becomes 0 or less, maybe delete the portfolio entry or leave it as 0
            -- Let's delete it if quantity becomes 0 to keep it clean
            DELETE FROM Portfolio WHERE user_id = NEW.user_id AND stock_symbol = NEW.stock_symbol AND quantity <= 0;
        END IF;
    END IF;

    -- Recalculate performance for this user right after updating portfolio
    CALL Calculate_Portfolio_Performance(NEW.user_id);
    
END$$

-- Trigger to recalculate performance when a stock's current price changes
DROP TRIGGER IF EXISTS After_Stock_Price_Update$$

CREATE TRIGGER After_Stock_Price_Update
AFTER UPDATE ON Stocks
FOR EACH ROW
BEGIN
    IF OLD.current_price != NEW.current_price THEN
        -- Safely update only the portfolio entries specifically holding this stock
        UPDATE Portfolio
        SET 
            current_value = quantity * NEW.current_price,
            profit_loss = (quantity * NEW.current_price) - total_investment
        WHERE stock_symbol = NEW.stock_symbol;
    END IF;
END$$

-- Advanced Analytics Stored Procedure
DROP PROCEDURE IF EXISTS Get_Risk_Analytics$$
DROP PROCEDURE IF EXISTS Get_Ultimate_Analytics$$

CREATE PROCEDURE Get_Ultimate_Analytics(IN p_user_id INT)
BEGIN
    DECLARE v_total_invested DECIMAL(15,2);
    DECLARE v_total_portfolio DECIMAL(15,2);
    DECLARE v_largest_asset_val DECIMAL(15,2);
    DECLARE v_total_buy_vol DECIMAL(15,2);

    -- Base aggregates
    SELECT IFNULL(SUM(total_investment), 0), IFNULL(SUM(current_value), 0)
    INTO v_total_invested, v_total_portfolio
    FROM Portfolio WHERE user_id = p_user_id;

    -- Largest asset
    SELECT IFNULL(MAX(current_value), 0) INTO v_largest_asset_val
    FROM Portfolio WHERE user_id = p_user_id;

    -- Turnover
    SELECT IFNULL(SUM(quantity * price_per_share), 0) INTO v_total_buy_vol
    FROM Transactions WHERE user_id = p_user_id AND transaction_type = 'BUY';

    -- Output JSON mapping targets
    SELECT 
        (SELECT stock_symbol FROM Portfolio WHERE user_id = p_user_id ORDER BY profit_loss DESC LIMIT 1) as best_stock,
        (SELECT MAX(profit_loss) FROM Portfolio WHERE user_id = p_user_id) as best_profit,
        (SELECT stock_symbol FROM Portfolio WHERE user_id = p_user_id ORDER BY profit_loss ASC LIMIT 1) as worst_stock,
        (SELECT MIN(profit_loss) FROM Portfolio WHERE user_id = p_user_id) as worst_profit,
        CASE WHEN v_total_portfolio > 0 THEN ROUND((v_largest_asset_val / v_total_portfolio) * 100, 2) ELSE 0 END as concentration_risk_pct,
        CASE WHEN v_total_portfolio > 0 THEN ROUND((v_total_buy_vol / v_total_portfolio), 2) ELSE 0 END as turnover_ratio,
        CASE WHEN v_total_invested > 0 THEN ROUND(((v_total_portfolio - v_total_invested) / v_total_invested) * 100, 2) ELSE 0 END as roi_pct,
        (SELECT ROUND(AVG(s.pe_ratio), 2) FROM Portfolio p JOIN Stocks s ON p.stock_symbol = s.stock_symbol WHERE p.user_id = p_user_id) as avg_pe_ratio;
END$$

DELIMITER ;
