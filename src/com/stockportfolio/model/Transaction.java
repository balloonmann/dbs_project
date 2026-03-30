package com.stockportfolio.model;

import java.sql.Timestamp;

public class Transaction {
    private int transactionId;
    private int userId;
    private String stockSymbol;
    private String transactionType;
    private int quantity;
    private double pricePerShare;
    private Timestamp transactionDate;

    public Transaction() {}

    public int getTransactionId() { return transactionId; }
    public void setTransactionId(int transactionId) { this.transactionId = transactionId; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getStockSymbol() { return stockSymbol; }
    public void setStockSymbol(String stockSymbol) { this.stockSymbol = stockSymbol; }

    public String getTransactionType() { return transactionType; }
    public void setTransactionType(String transactionType) { this.transactionType = transactionType; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public double getPricePerShare() { return pricePerShare; }
    public void setPricePerShare(double pricePerShare) { this.pricePerShare = pricePerShare; }

    public Timestamp getTransactionDate() { return transactionDate; }
    public void setTransactionDate(Timestamp transactionDate) { this.transactionDate = transactionDate; }
}
