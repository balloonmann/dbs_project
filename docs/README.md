# Stock Portfolio Management & Analytics System

## Abstract

The **Stock Portfolio Management & Analytics System** is a full-stack database application designed as an academic mini-project for a Database Systems Lab. It features a 7-table normalized relational schema (3NF) built on MySQL, encompassing users, stocks, portfolios, transactions, historical price data, watchlists, and audit logs. The system demonstrates advanced SQL concepts including stored procedures for atomic trade execution and portfolio analytics, triggers for automated audit logging, views for real-time portfolio insights, and a rich collection of queries spanning joins, aggregates, window functions, and correlated subqueries. A Node.js/Express REST API serves data to a premium single-page frontend built with vanilla HTML/CSS/JS, featuring a dark-themed glassmorphism UI with interactive charts and real-time trade execution.

---

## Key Features

### Database Design
- **7 normalized tables** following 3NF with proper primary keys, foreign keys, unique constraints, check constraints, and indexes
- **Referential integrity** with CASCADE/SET NULL policies
- **Generated columns** (computed `total_amount` in transactions)
- **JSON data type** for flexible audit log storage

### SQL Implementation
- **21+ queries** covering: basic CRUD, INNER/LEFT joins, SUM/AVG/COUNT aggregates, GROUP BY/HAVING, window functions (LAG, RANK, OVER), correlated subqueries, derived tables
- **4 stored procedures**: portfolio summary, P&L report, investment analysis, atomic trade execution with rollback
- **4 triggers**: BUY/SELL audit logging, portfolio update/delete audit trail
- **3 views**: portfolio overview, sector allocation, top performers ranking

### Backend API
- RESTful Express.js server with 15 endpoints
- MySQL connection pooling via `mysql2/promise`
- Stored procedure invocation from application code
- Error handling and input validation

### Frontend
- Single-page application with sidebar navigation
- Dark-themed glassmorphism design with gradient accents
- Interactive canvas-based donut charts for allocation
- Real-time trade form with preview
- Responsive layout

---

## Design Choices

### Why 7 Tables?
| Table | Purpose |
|---|---|
| `users` | Account management with balance tracking |
| `stocks` | Master market data (real tickers: AAPL, GOOGL, etc.) |
| `portfolios` | Current holdings with weighted avg cost basis |
| `transactions` | Immutable trade ledger (BUY/SELL) |
| `stock_prices` | Historical OHLC data for trend analysis |
| `watchlist` | User-tracked stocks with alert prices |
| `audit_log` | Compliance audit trail (JSON old/new values) |

### Normalization (3NF)
- **No repeating groups** (1NF) — all attributes are atomic
- **No partial dependencies** (2NF) — composite key tables have no partial FDs
- **No transitive dependencies** (3NF) — price history is separated from stock master; audit logs are independent of transactions

### Why Stored Procedures for Trades?
The `sp_execute_trade` procedure wraps buy/sell operations in a MySQL `START TRANSACTION` block, ensuring:
1. Balance validation before deduction
2. Share availability check for sells
3. Weighted-average price recalculation
4. Atomic commit or full rollback on failure

### Why Triggers for Auditing?
Rather than relying on application code (which may bypass rules), **database-level triggers** guarantee that every portfolio modification is logged — regardless of whether the change comes from the app, a script, or direct SQL.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Database | MySQL 8.0+ |
| Backend | Node.js, Express.js, mysql2 |
| Frontend | Vanilla HTML5, CSS3, JavaScript (ES6+) |
| Charts | Canvas 2D API (no external library) |
| Fonts | Inter, JetBrains Mono (Google Fonts) |

---

## Setup Instructions

### Prerequisites
- **Node.js** (v18+)
- **MySQL** (v8.0+) running locally

### 1. Database Setup
```bash
# Connect to MySQL
mysql -u root -p

# Run the SQL files in order:
source database/schema.sql;
source database/seed_data.sql;
source database/views.sql;
source database/procedures.sql;
source database/triggers.sql;
```

### 2. Backend Setup
```bash
cd server
cp .env.example .env        # Edit with your MySQL credentials
npm install
npm start
```

### 3. Access the Application
Open your browser to: **http://localhost:3000**

---

## Sample Query Outputs

### Portfolio Summary (User: Aditya Sharma)
```
┌──────────┬────────────┬─────────────┬─────────────┬──────────────┬────────────┐
│ Ticker   │ Company    │ Qty         │ Avg Cost    │ Market Value │ P&L        │
├──────────┼────────────┼─────────────┼─────────────┼──────────────┼────────────┤
│ NVDA     │ NVIDIA     │ 5           │ $780.00     │ $4,376.40    │ +$476.40   │
│ AAPL     │ Apple      │ 25          │ $175.50     │ $4,746.00    │ +$358.50   │
│ MSFT     │ Microsoft  │ 10          │ $350.20     │ $3,789.10    │ +$287.10   │
└──────────┴────────────┴─────────────┴─────────────┴──────────────┴────────────┘
```

### Stored Procedure Execution
```sql
-- Execute a buy trade
CALL sp_execute_trade(1, 'GOOGL', 'BUY', 10);
-- Result: Trade executed successfully. New balance: $77,082.00

-- Get portfolio summary
CALL sp_portfolio_summary(1);
-- Returns: 2 result sets (header info + detailed holdings)
```

### Trigger Demonstration
```sql
-- After executing the trade above, check audit log:
SELECT * FROM audit_log ORDER BY performed_at DESC LIMIT 1;
-- Shows: Automatic INSERT audit entry with JSON containing trade details
```

---

## Project Structure
```
Dbs_Project/
├── database/
│   ├── schema.sql          # DDL — 7 tables with constraints
│   ├── seed_data.sql       # Sample data (8 users, 12 stocks, 28 txns)
│   ├── queries.sql         # 21 analytical queries
│   ├── procedures.sql      # 4 stored procedures
│   ├── triggers.sql        # 4 triggers
│   └── views.sql           # 3 database views
├── server/
│   ├── server.js           # Express REST API (15 endpoints)
│   ├── package.json        # Node dependencies
│   ├── .env                # Database config
│   └── .env.example        # Config template
├── frontend/
│   ├── index.html          # SPA structure
│   ├── css/styles.css      # Premium dark theme (600+ lines)
│   └── js/app.js           # App logic with charts (550+ lines)
└── docs/
    └── README.md           # This documentation
```

---

## ER Diagram (Textual)

```
USERS (1) ────── (N) PORTFOLIOS (N) ────── (1) STOCKS
  │                       │                       │
  │                       │(1)                    │
  │                    (N)│                       │(1)
  │               TRANSACTIONS                    │
  │                                          (N)  │
  │(1)                                   STOCK_PRICES
  │
  ├──── (N) WATCHLIST (N) ────── (1) STOCKS
  │
  └──── (N) AUDIT_LOG

Cardinality:
  - One user can have many portfolio entries (1:N)
  - One stock can appear in many portfolios (1:N)
  - One portfolio entry can have many transactions (1:N)
  - One stock has many historical prices (1:N)
  - One user can watch many stocks (M:N via watchlist)
  - One user can have many audit log entries (1:N)
```

---

*Developed as an academic project for Database Systems Lab — demonstrating proficiency in relational database design, SQL programming, and full-stack integration.*
