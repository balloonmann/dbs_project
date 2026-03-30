# 📈 Stock Portfolio Management & Analytics System
### *A "Bloomberg Terminal" Style Desktop Simulator*

---

## 🌟 Overview
The **Stock Portfolio Management & Analytics System** is a sophisticated database-driven desktop application designed for real-time stock investment tracking. Built to fulfill advanced DBMS requirements, it features a robust MySQL backend with automated business logic (Triggers & Procedures) and a premium, dark-themed Java Swing frontend that simulates a professional trading terminal.

## 🚀 Key Features

### 💎 Premium Terminal Experience
- **Dark Mode UI**: Professional "Bloomberg Terminal" aesthetic using a custom-styled Swing interface.
- **Real-Time Market Simulation**: Live price fluctuations (random walk algorithm) every 5 seconds.
- **Dynamic Charting**: A custom-rendered "Net Worth Over Time" line chart that updates in real-time.

### ⚙️ Deep Database Integration
- **Automated Portfolio Management**: MySQL Triggers handle all balance, quantity, and average cost calculations instantly upon transaction.
- **Performance Analytics**: Stored Procedures calculate real-time Profit/Loss based on current market volatility.
- **ACID Compliant Transactions**: Ensures data integrity during high-frequency simulated trades.

### 📊 Portfolio Insights
- **Live Market Feed**: Track price movements across a diverse range of top-tier stocks (RELIANCE, TCS, INFY, etc.).
- **Trade Desk**: Seamlessly execute BUY and SELL orders with instant feedback.
- **Top Performer Analysis**: Intelligent identification of your best-performing assets.

---

## 🛠️ Tech Stack
- **Frontend**: Java Swing (Native Graphics2D for charting)
- **Backend**: MySQL 8.0+
- **Connectivity**: JDBC (Java Database Connectivity)
- **Architecture**: DAO (Data Access Object) Pattern

---

## 📂 Project Structure
```text
dbs_project/
├── db_schema.sql        # Database tables and relationships
├── db_logic.sql         # Triggers and Stored Procedures
├── build_and_run.bat    # Automation script for compilation & execution
├── lib/                 # External dependencies (MySQL Connector)
├── src/                 # Java Source Code
│   └── com/stockportfolio/
│       ├── app/         # Main GUI Application
│       ├── dao/         # Data Access Objects (SQL Logic)
│       ├── model/       # Data Models (POJOs)
│       └── util/        # Database Connection Utilities
└── bin/                 # Compiled bytecode files (Auto-generated)
```

---

## ⚙️ Installation & Setup

### 1. Prerequisites
- **Java JDK 8 or higher** installed and added to PATH.
- **MySQL Server** installed and running on `localhost:3306`.
- **MySQL Connector/J**: Ensure the `.jar` file is placed in the `lib` directory.

### 2. Database Initialization
Execute the following scripts in your MySQL client to build the environment:
1. `db_schema.sql` (Initializes tables: Users, Stocks, Portfolio, Transactions)
2. `db_logic.sql` (Initializes Triggers for automated logic)

### 3. Application Configuration
If your MySQL credentials differ from the default (`root` / `password`), update the connection string in:
`src/com/stockportfolio/util/DatabaseConnection.java`

---

## 🏃 Running the Application
The project includes a `build_and_run.bat` script specifically for Windows users to simplify the process:

1. **Open the project folder** in your terminal or file explorer.
2. **Execute the batch file**:
   ```bash
   ./build_and_run.bat
   ```
3. The script will automatically compile all source files, link the MySQL library, and launch the terminal UI.

---

## 🛠️ Database Schema Highlights
- **Users**: Unique identifiers and contact info.
- **Stocks**: Tracks ticker symbols, company names, and live market prices.
- **Portfolio**: Aggregated view of holdings, calculated dynamically by DB triggers.
- **Transactions**: History of all buy/sell actions with timestamping.

---

## 📜 License
This project is developed for academic purposes as part of a Database Management Systems laboratory project.
