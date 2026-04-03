package com.stockportfolio.dao;

import com.stockportfolio.model.PortfolioItem;
import com.stockportfolio.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PortfolioDAO {

    public List<PortfolioItem> getPortfolioByUserId(int userId) {
        List<PortfolioItem> portfolio = new ArrayList<>();
        String sql = "SELECT * FROM Portfolio WHERE user_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    PortfolioItem item = new PortfolioItem();
                    item.setPortfolioId(rs.getInt("portfolio_id"));
                    item.setUserId(rs.getInt("user_id"));
                    item.setStockSymbol(rs.getString("stock_symbol"));
                    item.setQuantity(rs.getInt("quantity"));
                    item.setAvgBuyPrice(rs.getDouble("avg_buy_price"));
                    item.setTotalInvestment(rs.getDouble("total_investment"));
                    item.setCurrentValue(rs.getDouble("current_value"));
                    item.setProfitLoss(rs.getDouble("profit_loss"));
                    portfolio.add(item);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return portfolio;
    }

    public void updatePortfolioAnalytics(int userId) {
        String call_sql = "{CALL Calculate_Portfolio_Performance(?)}";
        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement stmt = conn.prepareCall(call_sql)) {
            
            stmt.setInt(1, userId);
            stmt.execute();
            
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public java.util.Map<String, Object> getAdvancedAnalytics(int userId) {
        java.util.Map<String, Object> map = new java.util.HashMap<>();
        String call_sql = "{CALL Get_Ultimate_Analytics(?)}";
        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement stmt = conn.prepareCall(call_sql)) {
            
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    map.put("best_stock", rs.getString("best_stock") != null ? rs.getString("best_stock") : "N/A");
                    map.put("best_profit", rs.getDouble("best_profit"));
                    map.put("worst_stock", rs.getString("worst_stock") != null ? rs.getString("worst_stock") : "N/A");
                    map.put("worst_profit", rs.getDouble("worst_profit"));
                    map.put("concentration_risk_pct", rs.getDouble("concentration_risk_pct"));
                    map.put("turnover_ratio", rs.getDouble("turnover_ratio"));
                    map.put("roi_pct", rs.getDouble("roi_pct"));
                    map.put("avg_pe_ratio", rs.getDouble("avg_pe_ratio"));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return map;
    }
}
