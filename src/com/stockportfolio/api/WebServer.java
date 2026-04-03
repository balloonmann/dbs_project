package com.stockportfolio.api;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.util.concurrent.Executors;

public class WebServer {
    private static HttpServer server;
    private static final int PORT = 8085;

    public static void start() {
        try {
            server = HttpServer.create(new InetSocketAddress(PORT), 0);
            
            // API Endpoints
            server.createContext("/api/portfolio", new ApiHandler.PortfolioHandler());
            server.createContext("/api/trade", new ApiHandler.TradeHandler());
            server.createContext("/api/market", new ApiHandler.MarketHandler());
            server.createContext("/api/history", new ApiHandler.HistoryHandler());
            server.createContext("/api/analytics", new ApiHandler.AnalyticsHandler());

            // Static Files
            server.createContext("/", new StaticFileHandler());

            server.setExecutor(Executors.newCachedThreadPool());
            server.start();
            System.out.println("Web Server started cleanly on http://localhost:" + PORT);
        } catch (IOException e) {
            System.err.println("Failed to start Web Server.");
            e.printStackTrace();
        }
    }

    static class StaticFileHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String path = exchange.getRequestURI().getPath();
            if (path.equals("/") || path.isEmpty()) {
                path = "/index.html";
            }
            
            File file = new File("web_dashboard" + path);
            if (file.exists() && !file.isDirectory()) {
                String extension = path.substring(path.lastIndexOf(".") + 1);
                String mimeType = "text/plain";
                if (extension.equals("html")) mimeType = "text/html";
                else if (extension.equals("css")) mimeType = "text/css";
                else if (extension.equals("js")) mimeType = "application/javascript";
                
                exchange.getResponseHeaders().set("Content-Type", mimeType);
                exchange.sendResponseHeaders(200, file.length());
                OutputStream os = exchange.getResponseBody();
                Files.copy(file.toPath(), os);
                os.close();
            } else {
                String response = "404 Not Found in web_dashboard directory";
                exchange.sendResponseHeaders(404, response.length());
                OutputStream os = exchange.getResponseBody();
                os.write(response.getBytes());
                os.close();
            }
        }
    }
}
