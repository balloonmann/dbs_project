package com.stockportfolio.dao;

import com.stockportfolio.model.Stock;
import com.stockportfolio.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class StockDAO {

    public boolean addStock(Stock stock) {
        String sql = "INSERT INTO Stocks (stock_symbol, company_name, current_price) VALUES (?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setString(1, stock.getStockSymbol());
            stmt.setString(2, stock.getCompanyName());
            stmt.setDouble(3, stock.getCurrentPrice());
            
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateStockPrice(String symbol, double newPrice) {
        String sql = "UPDATE Stocks SET current_price = ? WHERE stock_symbol = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setDouble(1, newPrice);
            stmt.setString(2, symbol);
            
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<Stock> getAllStocks() {
        List<Stock> stocks = new ArrayList<>();
        String sql = "SELECT * FROM Stocks";
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            while (rs.next()) {
                stocks.add(new Stock(
                    rs.getString("stock_symbol"),
                    rs.getString("company_name"),
                    rs.getDouble("current_price")
                ));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return stocks;
    }
}
