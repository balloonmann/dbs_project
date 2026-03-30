package com.stockportfolio.dao;

import com.stockportfolio.model.Transaction;
import com.stockportfolio.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class TransactionDAO {

    public boolean recordTransaction(Transaction transaction) {
        String sql = "INSERT INTO Transactions (user_id, stock_symbol, transaction_type, quantity, price_per_share) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, transaction.getUserId());
            stmt.setString(2, transaction.getStockSymbol());
            stmt.setString(3, transaction.getTransactionType());
            stmt.setInt(4, transaction.getQuantity());
            stmt.setDouble(5, transaction.getPricePerShare());
            
            return stmt.executeUpdate() > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<Transaction> getTransactionsByUserId(int userId) {
        List<Transaction> transactions = new ArrayList<>();
        String sql = "SELECT * FROM Transactions WHERE user_id = ? ORDER BY transaction_date DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Transaction t = new Transaction();
                    t.setTransactionId(rs.getInt("transaction_id"));
                    t.setUserId(rs.getInt("user_id"));
                    t.setStockSymbol(rs.getString("stock_symbol"));
                    t.setTransactionType(rs.getString("transaction_type"));
                    t.setQuantity(rs.getInt("quantity"));
                    t.setPricePerShare(rs.getDouble("price_per_share"));
                    t.setTransactionDate(rs.getTimestamp("transaction_date"));
                    transactions.add(t);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return transactions;
    }
}
