package com.stockportfolio.model;

public class PortfolioItem {
    private int portfolioId;
    private int userId;
    private String stockSymbol;
    private int quantity;
    private double avgBuyPrice;
    private double totalInvestment;
    private double currentValue;
    private double profitLoss;

    public PortfolioItem() {}

    public int getPortfolioId() { return portfolioId; }
    public void setPortfolioId(int portfolioId) { this.portfolioId = portfolioId; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getStockSymbol() { return stockSymbol; }
    public void setStockSymbol(String stockSymbol) { this.stockSymbol = stockSymbol; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public double getAvgBuyPrice() { return avgBuyPrice; }
    public void setAvgBuyPrice(double avgBuyPrice) { this.avgBuyPrice = avgBuyPrice; }

    public double getTotalInvestment() { return totalInvestment; }
    public void setTotalInvestment(double totalInvestment) { this.totalInvestment = totalInvestment; }

    public double getCurrentValue() { return currentValue; }
    public void setCurrentValue(double currentValue) { this.currentValue = currentValue; }

    public double getProfitLoss() { return profitLoss; }
    public void setProfitLoss(double profitLoss) { this.profitLoss = profitLoss; }
}
