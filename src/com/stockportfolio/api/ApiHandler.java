package com.stockportfolio.api;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.stockportfolio.dao.*;
import com.stockportfolio.model.*;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.List;

public class ApiHandler {
    private static final Gson gson = new Gson();
    private static final int MOCK_USER_ID = 1; // Assuming 1 for the demo session
    
    private static final PortfolioDAO portfolioDAO = new PortfolioDAO();
    private static final TransactionDAO transactionDAO = new TransactionDAO();
    private static final StockDAO stockDAO = new StockDAO();

    private static void sendJsonResponse(HttpExchange exchange, int statusCode, Object data) throws IOException {
        String json = gson.toJson(data);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        byte[] bytes = json.getBytes("UTF-8");
        exchange.sendResponseHeaders(statusCode, bytes.length);
        OutputStream os = exchange.getResponseBody();
        os.write(bytes);
        os.close();
    }

    public static class PortfolioHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("GET".equals(exchange.getRequestMethod())) {
                try {
                    List<PortfolioItem> portfolio = portfolioDAO.getPortfolioByUserId(MOCK_USER_ID);
                    sendJsonResponse(exchange, 200, portfolio);
                } catch(Exception e) {
                    sendJsonResponse(exchange, 500, e.getMessage());
                }
            } else {
                exchange.sendResponseHeaders(405, -1);
            }
        }
    }

    public static class MarketHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("GET".equals(exchange.getRequestMethod())) {
                List<Stock> stocks = stockDAO.getAllStocks();
                sendJsonResponse(exchange, 200, stocks);
            }
        }
    }
    
    public static class HistoryHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("GET".equals(exchange.getRequestMethod())) {
                List<Transaction> transactions = transactionDAO.getTransactionsByUserId(MOCK_USER_ID);
                sendJsonResponse(exchange, 200, transactions);
            }
        }
    }

    public static class AnalyticsHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("GET".equals(exchange.getRequestMethod())) {
                try {
                    java.util.Map<String, Object> analytics = portfolioDAO.getAdvancedAnalytics(MOCK_USER_ID);
                    
                    JsonObject res = new JsonObject();
                    res.addProperty("topPerformerSymbol", (String) analytics.getOrDefault("best_stock", "N/A"));
                    res.addProperty("topPerformerProfit", (double) analytics.getOrDefault("best_profit", 0.0));
                    res.addProperty("worstPerformerSymbol", (String) analytics.getOrDefault("worst_stock", "N/A"));
                    res.addProperty("worstPerformerProfit", (double) analytics.getOrDefault("worst_profit", 0.0));
                    res.addProperty("concentrationRiskPct", (double) analytics.getOrDefault("concentration_risk_pct", 0.0));
                    res.addProperty("turnoverRatio", (double) analytics.getOrDefault("turnover_ratio", 0.0));
                    res.addProperty("roiPct", (double) analytics.getOrDefault("roi_pct", 0.0));
                    res.addProperty("avgPeRatio", (double) analytics.getOrDefault("avg_pe_ratio", 0.0));

                    sendJsonResponse(exchange, 200, res);
                } catch(Exception e) {
                    sendJsonResponse(exchange, 500, e.getMessage());
                }
            } else {
                exchange.sendResponseHeaders(405, -1);
            }
        }
    }

    public static class TradeHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if ("POST".equals(exchange.getRequestMethod())) {
                try {
                    JsonObject req = JsonParser.parseReader(new InputStreamReader(exchange.getRequestBody())).getAsJsonObject();
                    String symbol = req.get("ticker").getAsString().toUpperCase();
                    int qty = req.get("qty").getAsInt();
                    String type = req.get("type").getAsString().toUpperCase(); // BUY or SELL
                    
                    Stock stock = stockDAO.getAllStocks().stream()
                        .filter(s -> s.getStockSymbol().equals(symbol))
                        .findFirst().orElse(null);
                        
                    if (stock != null) {
                        Transaction t = new Transaction();
                        t.setUserId(MOCK_USER_ID);
                        t.setStockSymbol(symbol);
                        t.setTransactionType(type);
                        t.setQuantity(qty);
                        t.setPricePerShare(stock.getCurrentPrice());
                        
                        boolean success = transactionDAO.recordTransaction(t);
                        JsonObject res = new JsonObject();
                        res.addProperty("success", success);
                        sendJsonResponse(exchange, 200, res);
                    } else {
                        JsonObject res = new JsonObject();
                        res.addProperty("error", "Stock not found in market");
                        sendJsonResponse(exchange, 400, res);
                    }
                } catch(Exception e) {
                   JsonObject res = new JsonObject();
                   res.addProperty("error", e.getMessage());
                   sendJsonResponse(exchange, 500, res);
                }
            } else {
                 exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
                 exchange.getResponseHeaders().set("Access-Control-Allow-Methods", "POST");
                 exchange.sendResponseHeaders(204, -1);
            }
        }
    }
}
