package com.stockportfolio.app;

import com.stockportfolio.dao.*;
import com.stockportfolio.model.*;
import com.stockportfolio.util.DatabaseConnection;
import com.stockportfolio.api.WebServer;

import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.JTableHeader;
import java.awt.*;
import java.sql.Connection;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class StockPortfolioApp extends JFrame {

    private User currentUser;
    private UserDAO userDAO = new UserDAO();
    private StockDAO stockDAO = new StockDAO();
    private PortfolioDAO portfolioDAO = new PortfolioDAO();
    private TransactionDAO transactionDAO = new TransactionDAO();

    private double availableCash = 1000000.00;
    
    private JLabel netWorthLabel;
    private JLabel availableCashLabel;
    private JLabel holdingsValueLabel;
    
    private JTable portfolioTable;
    private DefaultTableModel portfolioTableModel;
    private JTable marketTable;
    private DefaultTableModel marketTableModel;
    
    private JComboBox<String> stockCombo;
    private JTextField quantityField;
    private JButton buyBtn;
    private JButton sellBtn;
    private JButton toggleAnalysisBtn;

    private JPanel centerPanel;
    private JPanel chartPanel;
    private JPanel analysisPanel;

    private JLabel topPerformerLabel;
    private JLabel totalProfitLabel;

    // Dark Mode Theme Colors
    private final Color bgColor = new Color(18, 18, 18);
    private final Color panelColor = new Color(30, 30, 30);
    private final Color headerColor = new Color(45, 45, 45);
    private final Color textColor = Color.WHITE;
    private final Color greenColor = new Color(0, 255, 0);
    private final Color redColor = new Color(255, 50, 50);

    // Chart Data
    private List<Double> netWorthHistory = new ArrayList<>();
    private Random random = new Random();

    public StockPortfolioApp() {
        setTitle("Bloomberg Terminal - Native Swing Simulator");
        setSize(1200, 800);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        getContentPane().setBackground(bgColor);

        setupMockEnvironment();
        initUI();
        startMarketSimulation();
    }

    private void setupMockEnvironment() {
        if (userDAO.getAllUsers().isEmpty()) {
            userDAO.addUser(new User(0, "Demo Swing User", "swing@bloomberg.com", "5555555555"));
        }
        currentUser = userDAO.getAllUsers().get(0);

        List<Stock> stocks = stockDAO.getAllStocks();
        if (stocks.size() < 20 || stocks.stream().noneMatch(s -> s.getStockSymbol().equals("RELIANCE"))) {
            try (Connection conn = DatabaseConnection.getConnection();
                 Statement stmt = conn.createStatement()) {
                stmt.execute("DELETE FROM Stocks"); 
            } catch (Exception e) {}

            stockDAO.addStock(new Stock("RELIANCE", "Reliance Industries", 2980.50));
            stockDAO.addStock(new Stock("TCS", "Tata Consultancy Services", 4120.00));
            stockDAO.addStock(new Stock("HDFCBANK", "HDFC Bank", 1430.25));
            stockDAO.addStock(new Stock("ICICIBANK", "ICICI Bank", 1080.00));
            stockDAO.addStock(new Stock("INFY", "Infosys Ltd", 1630.75));
            stockDAO.addStock(new Stock("SBIN", "State Bank of India", 760.30));
            stockDAO.addStock(new Stock("BHARTIARTL", "Bharti Airtel", 1120.00));
            stockDAO.addStock(new Stock("ITC", "ITC Limited", 410.60));
            stockDAO.addStock(new Stock("LT", "Larsen & Toubro", 3650.00));
            stockDAO.addStock(new Stock("HINDUNILVR", "Hindustan Unilever", 2400.00));
            stockDAO.addStock(new Stock("BAJFINANCE", "Bajaj Finance", 6600.50));
            stockDAO.addStock(new Stock("MARUTI", "Maruti Suzuki", 11500.00));
            stockDAO.addStock(new Stock("ASIANPAINT", "Asian Paints", 2850.75));
            stockDAO.addStock(new Stock("SUNPHARMA", "Sun Pharma", 1580.00));
            stockDAO.addStock(new Stock("TITAN", "Titan Company", 3700.25));
            stockDAO.addStock(new Stock("AXISBANK", "Axis Bank", 1050.50));
            stockDAO.addStock(new Stock("KOTAKBANK", "Kotak Mahindra Bank", 1750.80));
            stockDAO.addStock(new Stock("ONGC", "Oil and Nat. Gas", 280.90));
            stockDAO.addStock(new Stock("TATAMOTORS", "Tata Motors", 950.40));
            stockDAO.addStock(new Stock("HCLTECH", "HCL Technologies", 1600.20));
        }
    }

    private void initUI() {
        setLayout(new BorderLayout());

        // Header
        JPanel headerPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 30, 15));
        headerPanel.setBackground(headerColor);
        headerPanel.setBorder(BorderFactory.createMatteBorder(0, 0, 1, 0, Color.DARK_GRAY));

        netWorthLabel = createStyledLabel("Total Net Worth: ₹0.00", textColor, 18, true);
        availableCashLabel = createStyledLabel("Available Cash: ₹10,00,000.00", greenColor, 16, false);
        holdingsValueLabel = createStyledLabel("Holdings Value: ₹0.00", new Color(255, 170, 0), 16, false);

        toggleAnalysisBtn = new JButton("Toggle Analysis View");
        styleButton(toggleAnalysisBtn, new Color(0, 120, 215));
        toggleAnalysisBtn.addActionListener(e -> toggleCenterView());

        headerPanel.add(netWorthLabel);
        headerPanel.add(availableCashLabel);
        headerPanel.add(holdingsValueLabel);
        headerPanel.add(Box.createHorizontalStrut(100)); // Spacer
        headerPanel.add(toggleAnalysisBtn);
        add(headerPanel, BorderLayout.NORTH);

        // Center Views
        centerPanel = new JPanel(new CardLayout());
        centerPanel.setBackground(bgColor);
        chartPanel = createChartPanel();
        analysisPanel = createAnalysisPanel();
        centerPanel.add(chartPanel, "Chart");
        centerPanel.add(analysisPanel, "Analysis");
        add(centerPanel, BorderLayout.CENTER);

        // Right Panel (Tables)
        JPanel rightPanel = new JPanel(new GridLayout(2, 1, 0, 10));
        rightPanel.setBackground(bgColor);
        rightPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        rightPanel.setPreferredSize(new Dimension(500, 0));

        marketTableModel = new DefaultTableModel(new String[]{"Symbol", "Company", "Live Price"}, 0);
        marketTable = createDarkTable(marketTableModel);
        
        portfolioTableModel = new DefaultTableModel(new String[]{"Symbol", "Shares", "Avg Cost", "Value", "P/L"}, 0);
        portfolioTable = createDarkTable(portfolioTableModel);

        rightPanel.add(createDecoratedTablePanel("LIVE MARKET DATA", marketTable));
        rightPanel.add(createDecoratedTablePanel("YOUR PORTFOLIO", portfolioTable));
        add(rightPanel, BorderLayout.EAST);

        // Bottom Trading Panel
        JPanel tradingPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 20, 15));
        tradingPanel.setBackground(panelColor);
        tradingPanel.setBorder(BorderFactory.createMatteBorder(1, 0, 0, 0, Color.DARK_GRAY));

        stockCombo = new JComboBox<>();
        stockCombo.setBackground(Color.DARK_GRAY);
        stockCombo.setForeground(Color.WHITE);

        quantityField = new JTextField("1", 5);
        quantityField.setBackground(Color.DARK_GRAY);
        quantityField.setForeground(Color.WHITE);
        quantityField.setCaretColor(Color.WHITE);

        buyBtn = new JButton(" BUY ");
        styleButton(buyBtn, new Color(0, 180, 0));
        buyBtn.addActionListener(e -> handleTrade("BUY"));

        sellBtn = new JButton(" SELL ");
        styleButton(sellBtn, new Color(220, 0, 0));
        sellBtn.addActionListener(e -> handleTrade("SELL"));

        tradingPanel.add(createStyledLabel("TRADE DESK:", Color.GRAY, 14, true));
        tradingPanel.add(createStyledLabel("Select Stock:", textColor, 14, false));
        tradingPanel.add(stockCombo);
        tradingPanel.add(createStyledLabel("Qty:", textColor, 14, false));
        tradingPanel.add(quantityField);
        tradingPanel.add(buyBtn);
        tradingPanel.add(sellBtn);
        
        add(tradingPanel, BorderLayout.SOUTH);

        updateDashboard();
    }

    private JPanel createChartPanel() {
        return new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                setBackground(bgColor);
                Graphics2D g2 = (Graphics2D) g;
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

                g2.setColor(textColor);
                g2.setFont(new Font("Segoe UI", Font.BOLD, 16));
                g2.drawString("Net Worth Over Time (Live Chart)", 20, 30);

                if (netWorthHistory.size() < 2) return;

                double min = netWorthHistory.stream().min(Double::compare).orElse(0.0);
                double max = netWorthHistory.stream().max(Double::compare).orElse(1.0);
                if (min == max) { min -= 100; max += 100; }

                int w = getWidth() - 40;
                int h = getHeight() - 80;
                int yOffset = 50;

                int xStep = w / 50;
                if (xStep == 0) xStep = 1;

                // Draw Grid
                g2.setColor(new Color(50, 50, 50));
                for(int i=0; i<=10; i++) {
                    int yLine = yOffset + (i * h / 10);
                    g2.drawLine(20, yLine, w + 20, yLine);
                }

                // Draw Line
                g2.setColor(greenColor);
                g2.setStroke(new BasicStroke(2.5f));

                for (int i = 0; i < netWorthHistory.size() - 1; i++) {
                    int x1 = 20 + i * xStep;
                    int y1 = yOffset + h - (int) ((netWorthHistory.get(i) - min) / (max - min) * h);
                    int x2 = 20 + (i + 1) * xStep;
                    int y2 = yOffset + h - (int) ((netWorthHistory.get(i + 1) - min) / (max - min) * h);
                    g2.drawLine(x1, y1, x2, y2);
                }
            }
        };
    }

    private JPanel createAnalysisPanel() {
        JPanel panel = new JPanel(new GridLayout(4, 1, 10, 10));
        panel.setBackground(bgColor);
        panel.setBorder(BorderFactory.createEmptyBorder(50, 50, 50, 50));

        topPerformerLabel = createStyledLabel("Top Performer: N/A", greenColor, 20, false);
        totalProfitLabel = createStyledLabel("Total Profit/Loss: ₹0.00", textColor, 20, false);

        panel.add(createStyledLabel("PORTFOLIO ANALYSIS", textColor, 28, true));
        panel.add(topPerformerLabel);
        panel.add(totalProfitLabel);
        return panel;
    }

    private void toggleCenterView() {
        CardLayout cl = (CardLayout) (centerPanel.getLayout());
        if (toggleAnalysisBtn.getText().contains("Analysis")) {
            cl.show(centerPanel, "Analysis");
            toggleAnalysisBtn.setText("Toggle Chart View");
            updateAnalysis();
            updateDashboard(); // Ensure labels stay accurate
        } else {
            cl.show(centerPanel, "Chart");
            toggleAnalysisBtn.setText("Toggle Analysis View");
        }
    }

    private JTable createDarkTable(DefaultTableModel model) {
        JTable table = new JTable(model);
        table.setBackground(new Color(30, 30, 30));
        table.setForeground(Color.WHITE);
        table.setGridColor(Color.DARK_GRAY);
        table.setRowHeight(25);
        table.setFillsViewportHeight(true);

        JTableHeader th = table.getTableHeader();
        th.setBackground(new Color(45, 45, 45));
        th.setForeground(Color.WHITE);
        th.setFont(new Font("Segoe UI", Font.BOLD, 14));

        DefaultTableCellRenderer renderer = new DefaultTableCellRenderer();
        renderer.setHorizontalAlignment(JLabel.CENTER);
        table.setDefaultRenderer(Object.class, renderer);
        return table;
    }

    private JPanel createDecoratedTablePanel(String title, JTable table) {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(bgColor);
        JLabel titleLabel = createStyledLabel(title, Color.LIGHT_GRAY, 16, true);
        titleLabel.setBorder(BorderFactory.createEmptyBorder(0, 0, 5, 0));
        titleLabel.setHorizontalAlignment(SwingConstants.CENTER);
        panel.add(titleLabel, BorderLayout.NORTH);
        
        JScrollPane scroll = new JScrollPane(table);
        scroll.getViewport().setBackground(new Color(30, 30, 30));
        scroll.setBorder(BorderFactory.createLineBorder(Color.DARK_GRAY));
        panel.add(scroll, BorderLayout.CENTER);
        return panel;
    }

    private void handleTrade(String type) {
        String selectedStr = (String) stockCombo.getSelectedItem();
        if (selectedStr == null) return;
        
        String symbol = selectedStr.split(" ")[0];
        Stock stock = stockDAO.getAllStocks().stream().filter(s -> s.getStockSymbol().equals(symbol)).findFirst().orElse(null);
        if (stock == null) return;

        int qty;
        try {
            qty = Integer.parseInt(quantityField.getText().trim());
            if (qty <= 0) throw new NumberFormatException();
        } catch (NumberFormatException e) {
            JOptionPane.showMessageDialog(this, "Please enter a valid positive integer quantity.", "Invalid Quantity", JOptionPane.WARNING_MESSAGE);
            return;
        }

        double totalCost = stock.getCurrentPrice() * qty;

        if (type.equals("BUY")) {
            if (availableCash >= totalCost) {
                availableCash -= totalCost;
                recordAndRefresh(type, symbol, qty, stock.getCurrentPrice());
                JOptionPane.showMessageDialog(this, "Successfully bought " + qty + " shares of " + symbol, "Trade Executed", JOptionPane.INFORMATION_MESSAGE);
            } else {
                JOptionPane.showMessageDialog(this, "Insufficient Cash to buy " + qty + " shares.", "Warning", JOptionPane.WARNING_MESSAGE);
            }
        } else if (type.equals("SELL")) {
            List<PortfolioItem> items = portfolioDAO.getPortfolioByUserId(currentUser.getUserId());
            PortfolioItem item = items.stream().filter(p -> p.getStockSymbol().equals(symbol)).findFirst().orElse(null);
            
            if (item != null && item.getQuantity() >= qty) {
                availableCash += totalCost;
                recordAndRefresh(type, symbol, qty, stock.getCurrentPrice());
                JOptionPane.showMessageDialog(this, "Successfully sold " + qty + " shares of " + symbol, "Trade Executed", JOptionPane.INFORMATION_MESSAGE);
            } else {
                JOptionPane.showMessageDialog(this, "You don't own enough shares of " + symbol + " to sell.", "Warning", JOptionPane.WARNING_MESSAGE);
            }
        }
    }

    private void recordAndRefresh(String type, String symbol, int qty, double price) {
        Transaction t = new Transaction();
        t.setUserId(currentUser.getUserId());
        t.setStockSymbol(symbol);
        t.setTransactionType(type);
        t.setQuantity(qty);
        t.setPricePerShare(price);
        
        transactionDAO.recordTransaction(t);
        updateDashboard();
    }

    private void updateDashboard() {
        List<Stock> stocks = stockDAO.getAllStocks();
        List<PortfolioItem> portfolio = portfolioDAO.getPortfolioByUserId(currentUser.getUserId());

        // Update Stock Combo
        String currentSelection = (String) stockCombo.getSelectedItem();
        stockCombo.removeAllItems();
        for (Stock s : stocks) {
            stockCombo.addItem(s.getStockSymbol() + " (₹" + String.format("%,.2f", s.getCurrentPrice()) + ")");
        }
        if(currentSelection != null) stockCombo.setSelectedItem(currentSelection);

        // Update Tables
        marketTableModel.setRowCount(0);
        for(Stock s : stocks) {
            marketTableModel.addRow(new Object[]{s.getStockSymbol(), s.getCompanyName(), String.format("₹%,.2f", s.getCurrentPrice())});
        }

        portfolioTableModel.setRowCount(0);
        double holdingsValue = 0.0;
        for(PortfolioItem p : portfolio) {
            portfolioTableModel.addRow(new Object[]{
                p.getStockSymbol(), p.getQuantity(), String.format("₹%,.2f", p.getAvgBuyPrice()), 
                String.format("₹%,.2f", p.getCurrentValue()), String.format("₹%,.2f", p.getProfitLoss())
            });
            holdingsValue += p.getCurrentValue();
        }

        // Calculate Values
        double netWorth = availableCash + holdingsValue;

        // Update Labels
        availableCashLabel.setText(String.format("Available Cash: ₹%,.2f", availableCash));
        holdingsValueLabel.setText(String.format("Holdings Value: ₹%,.2f", holdingsValue));
        netWorthLabel.setText(String.format("Total Net Worth: ₹%,.2f", netWorth));

        // Chart Update
        netWorthHistory.add(netWorth);
        if(netWorthHistory.size() > 50) netWorthHistory.remove(0);
        chartPanel.repaint();

        if (toggleAnalysisBtn.getText().contains("Chart")) updateAnalysis();
    }

    private void updateAnalysis() {
        List<PortfolioItem> portfolio = portfolioDAO.getPortfolioByUserId(currentUser.getUserId());
        double totalPL = 0;
        PortfolioItem topPerformer = null;
        
        for (PortfolioItem p : portfolio) {
            totalPL += p.getProfitLoss();
            if (topPerformer == null || p.getProfitLoss() > topPerformer.getProfitLoss()) {
                topPerformer = p;
            }
        }

        if (totalPL >= 0) {
            totalProfitLabel.setForeground(greenColor);
            totalProfitLabel.setText(String.format("Total Profit/Loss: +₹%,.2f", totalPL));
        } else {
            totalProfitLabel.setForeground(redColor);
            totalProfitLabel.setText(String.format("Total Profit/Loss: -₹%,.2f", Math.abs(totalPL)));
        }

        if (topPerformer != null) {
            topPerformerLabel.setText("Top Performer: " + topPerformer.getStockSymbol() + " (₹" + String.format("%,.2f", topPerformer.getProfitLoss()) + ")");
        } else {
            topPerformerLabel.setText("Top Performer: N/A");
        }
    }

    private void startMarketSimulation() {
        Timer timer = new Timer(5000, e -> {
            List<Stock> stocks = stockDAO.getAllStocks();
            for (Stock stock : stocks) {
                // +/- 5% max random walk
                double volatility = (random.nextDouble() * 0.10) - 0.05;
                double newPrice = stock.getCurrentPrice() * (1 + volatility);
                stockDAO.updateStockPrice(stock.getStockSymbol(), newPrice);
            }
            updateDashboard();
        });
        timer.start();
    }

    private JLabel createStyledLabel(String text, Color color, int size, boolean bold) {
        JLabel label = new JLabel(text);
        label.setForeground(color);
        label.setFont(new Font("Segoe UI", bold ? Font.BOLD : Font.PLAIN, size));
        return label;
    }

    private void styleButton(JButton btn, Color bgColor) {
        btn.setBackground(bgColor);
        btn.setForeground(Color.WHITE);
        btn.setFocusPainted(false);
        btn.setFont(new Font("Segoe UI", Font.BOLD, 14));
        btn.setBorder(BorderFactory.createEmptyBorder(8, 15, 8, 15));
    }

    public static void main(String[] args) {
        System.out.println("Starting Headless Web Server Backend...");
        WebServer.start();
        
        StockPortfolioApp app = new StockPortfolioApp();
        // Hide the GUI but still run the background market simulation timers!
        app.setVisible(false);
    }
}
