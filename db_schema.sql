-- Create Database
CREATE DATABASE IF NOT EXISTS stock_portfolio_db;
USE stock_portfolio_db;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20)
);

-- 2. Stocks Table
-- Stores the list of available stocks and their current market price.
CREATE TABLE IF NOT EXISTS Stocks (
    stock_symbol VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    current_price DECIMAL(10, 2) NOT NULL
);

-- 3. Portfolio Table
-- Stores the aggregated data of a user's holdings for a specific stock.
CREATE TABLE IF NOT EXISTS Portfolio (
    portfolio_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    stock_symbol VARCHAR(10) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    avg_buy_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total_investment DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    current_value DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    profit_loss DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (stock_symbol) REFERENCES Stocks(stock_symbol) ON DELETE CASCADE,
    UNIQUE(user_id, stock_symbol) -- A user has one portfolio entry per stock
);

-- 4. Transactions Table
-- Records every buy/sell action.
CREATE TABLE IF NOT EXISTS Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    stock_symbol VARCHAR(10) NOT NULL,
    transaction_type ENUM('BUY', 'SELL') NOT NULL,
    quantity INT NOT NULL,
    price_per_share DECIMAL(10, 2) NOT NULL,
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (stock_symbol) REFERENCES Stocks(stock_symbol) ON DELETE CASCADE
);
