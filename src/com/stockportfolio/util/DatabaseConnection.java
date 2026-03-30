package com.stockportfolio.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    private static final String URL = "jdbc:mysql://localhost:3306/stock_portfolio_db";
    private static final String USER = "root"; // Update with actual DB user
    private static final String PASSWORD = "041121t"; // Update with actual DB password

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            return DriverManager.getConnection(URL, USER, PASSWORD);
        } catch (ClassNotFoundException e) {
            System.err.println("Database Driver not found!");
            e.printStackTrace();
            throw new SQLException("Database Driver not found", e);
        }
    }
}
