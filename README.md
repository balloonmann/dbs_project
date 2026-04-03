# DBS Project: Stock Portfolio Engine

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Java Version](https://img.shields.io/badge/Java-8%2B-orange)
![MySQL Version](https://img.shields.io/badge/MySQL-8.0%2B-blue)

## About The Project
This project is an advanced, headless execution engine and dashboard for intelligent stock portfolio tracking. What began as a local desktop tool has been entirely refactored into a **Modern Web Application** powered by a highly optimized Java REST API backend connecting to a MySQL Database capable of rendering complex, institutional risk metrics natively.

The platform provides users with an aesthetic, highly analytical trading dashboard built entirely under the rigid parameters of the **GitHub Dark Dimmed** UI paradigm.

## Tech Stack
- **Backend Core**: Java (Headless HTTP REST Server)
- **Database Engine**: MySQL 8.0+ (Stored Procedures, Advanced Triggers)
- **Frontend Dashboard**: Vanilla HTML5, Advanced CSS3, Asynchronous JavaScript

## Core Features
1. **GitHub Dark Aesthetic UI**: A sophisticated, strain-free dark-mode web dashboard modeled exactly after enterprise software interfaces.
2. **"Super-Grid" Quantitative Analytics**: Features a massive 6-card layout pulling in professional statistics natively calculated by the database without stressing the JVM.
3. **`Get_Ultimate_Analytics` Procedure**: 
   - **Average P/E Portfolio Weighting**
   - **Concentration Risk (%)**
   - **Portfolio Turnover Velocity (x)**
   - **Performance Indexing (Best/Worst Performers & ROI)**
4. **Trigger-Based Transaction Integrity**: Pure database level automation processing trades against floating cash margins flawlessly.

## Getting Started

### Prerequisites
- Java Development Kit (JDK) 8+
- MySQL Server 8.0+
- MySQL Connector/J driver (must exist in the `lib` folder)

### Installation
1. **Initialize Database Structures**:
   - Execute `db_schema.sql` to build the foundational architecture (includes new `pe_ratio` column).
   - Execute `db_logic.sql` to initialize triggers and the unified analytical Stored Procedure.
2. **Configure Connection**:
   - Update `src/com/stockportfolio/util/DatabaseConnection.java` to match your local SQL root password.

## Execution
We provide an automated compilation tool for the HTTP server:

1. Double click or run the batch execution interface inside your terminal:
   ```powershell
   ./build_and_run.bat
   ```
2. The headless backend will boot on Port `8085`.
3. Open `web_dashboard/index.html` in your modern web browser of choice, or load via `localhost:8085` to interface directly with the RESTful API endpoints.

## License
Distributed under an Open License format.
