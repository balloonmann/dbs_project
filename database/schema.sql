-- ============================================================================
-- STOCK PORTFOLIO MANAGEMENT & ANALYTICS SYSTEM
-- Database Schema (DDL)
-- ============================================================================
-- Normalized to 3NF | MySQL 8.0+
-- Author: Database Systems Lab Project
-- ============================================================================

-- Create and use the database
CREATE DATABASE IF NOT EXISTS stock_portfolio_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE stock_portfolio_db;

-- ============================================================================
-- TABLE 1: USERS
-- Stores registered users and their account balances.
-- ============================================================================
CREATE TABLE users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)    NOT NULL UNIQUE,
    email         VARCHAR(100)   NOT NULL UNIQUE,
    password_hash VARCHAR(255)   NOT NULL,
    full_name     VARCHAR(120)   NOT NULL,
    account_balance DECIMAL(15,2) NOT NULL DEFAULT 100000.00
        CHECK (account_balance >= 0),
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_users_email (email),
    INDEX idx_users_username (username)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 2: STOCKS
-- Master list of tradable stocks with current market data.
-- ============================================================================
CREATE TABLE stocks (
    stock_id       INT AUTO_INCREMENT PRIMARY KEY,
    ticker_symbol  VARCHAR(10)   NOT NULL UNIQUE,
    company_name   VARCHAR(200)  NOT NULL,
    sector         VARCHAR(80)   NOT NULL,
    current_price  DECIMAL(12,2) NOT NULL CHECK (current_price > 0),
    market_cap     DECIMAL(18,2) DEFAULT NULL,
    day_high       DECIMAL(12,2) DEFAULT NULL,
    day_low        DECIMAL(12,2) DEFAULT NULL,
    pe_ratio       DECIMAL(8,2)  DEFAULT NULL,
    last_updated   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_stocks_sector (sector),
    INDEX idx_stocks_ticker (ticker_symbol)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 3: PORTFOLIOS
-- Represents a user's current holding in a specific stock.
-- Composite uniqueness on (user_id, stock_id) ensures one row per holding.
-- ============================================================================
CREATE TABLE portfolios (
    portfolio_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT            NOT NULL,
    stock_id       INT            NOT NULL,
    quantity       INT            NOT NULL CHECK (quantity > 0),
    avg_buy_price  DECIMAL(12,2)  NOT NULL CHECK (avg_buy_price > 0),
    first_purchased DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_user_stock (user_id, stock_id),

    CONSTRAINT fk_portfolio_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_portfolio_stock
        FOREIGN KEY (stock_id) REFERENCES stocks(stock_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    INDEX idx_portfolio_user (user_id),
    INDEX idx_portfolio_stock (stock_id)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 4: TRANSACTIONS
-- Immutable ledger of every BUY/SELL trade.
-- ============================================================================
CREATE TABLE transactions (
    transaction_id   INT AUTO_INCREMENT PRIMARY KEY,
    user_id          INT            NOT NULL,
    stock_id         INT            NOT NULL,
    portfolio_id     INT            DEFAULT NULL,
    transaction_type ENUM('BUY','SELL') NOT NULL,
    quantity         INT            NOT NULL CHECK (quantity > 0),
    price_per_unit   DECIMAL(12,2)  NOT NULL CHECK (price_per_unit > 0),
    total_amount     DECIMAL(15,2)  GENERATED ALWAYS AS (quantity * price_per_unit) STORED,
    transaction_date DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_txn_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_txn_stock
        FOREIGN KEY (stock_id) REFERENCES stocks(stock_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_txn_portfolio
        FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_txn_user (user_id),
    INDEX idx_txn_stock (stock_id),
    INDEX idx_txn_date (transaction_date),
    INDEX idx_txn_type (transaction_type)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 5: STOCK_PRICES (Historical)
-- Daily OHLC price data for trend analysis.
-- ============================================================================
CREATE TABLE stock_prices (
    price_id    INT AUTO_INCREMENT PRIMARY KEY,
    stock_id    INT            NOT NULL,
    price_date  DATE           NOT NULL,
    open_price  DECIMAL(12,2)  NOT NULL,
    close_price DECIMAL(12,2)  NOT NULL,
    high_price  DECIMAL(12,2)  NOT NULL,
    low_price   DECIMAL(12,2)  NOT NULL,
    volume      BIGINT         NOT NULL DEFAULT 0,

    UNIQUE KEY uq_stock_date (stock_id, price_date),

    CONSTRAINT fk_price_stock
        FOREIGN KEY (stock_id) REFERENCES stocks(stock_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    INDEX idx_price_date (price_date),
    INDEX idx_price_stock (stock_id)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 6: WATCHLIST
-- Users can track stocks they're interested in with price alerts.
-- ============================================================================
CREATE TABLE watchlist (
    watchlist_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT            NOT NULL,
    stock_id     INT            NOT NULL,
    alert_price  DECIMAL(12,2)  DEFAULT NULL,
    added_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_watchlist_user_stock (user_id, stock_id),

    CONSTRAINT fk_watch_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_watch_stock
        FOREIGN KEY (stock_id) REFERENCES stocks(stock_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    INDEX idx_watch_user (user_id)
) ENGINE=InnoDB;

-- ============================================================================
-- TABLE 7: AUDIT_LOG
-- Captures all data-mutation events for compliance and debugging.
-- ============================================================================
CREATE TABLE audit_log (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT            DEFAULT NULL,
    table_name   VARCHAR(64)    NOT NULL,
    operation    ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    old_values   JSON           DEFAULT NULL,
    new_values   JSON           DEFAULT NULL,
    performed_at DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_audit_table (table_name),
    INDEX idx_audit_operation (operation),
    INDEX idx_audit_date (performed_at)
) ENGINE=InnoDB;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
