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
}
