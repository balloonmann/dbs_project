# dbs_project

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Java Version](https://img.shields.io/badge/Java-8%2B-orange)
![MySQL Version](https://img.shields.io/badge/MySQL-8.0%2B-blue)

## Table of Contents
- [About The Project](#about-the-project)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [License](#license)

## About The Project
This project is a standalone Java desktop application designed for stock portfolio tracking and analytics. It utilizes a MySQL database to handle core financial calculations and a Swing-based graphical user interface for data visualization and transaction management. The system is built to demonstrate the integration of database automation (triggers and stored procedures) with a specialized client-side dashboard.

## Tech Stack
- **Language**: Java 8+
- **Database**: MySQL 8.0+
- **Frameworks/Libraries**:
  - Java Swing (GUI)
  - JDBC (MySQL Connector/J)
  - Native Graphics2D (Charting)

## Features
- **Database-Driven Portfolio Automation**: Automatically updates held quantities, average buy prices, and total investment values through MySQL triggers whenever a transaction is recorded.
- **Analytical Stored Procedures**: Implements logic within the database to calculate real-time profit and loss status for all held assets.
- **Market Simulation**: A multi-threaded simulation engine that generates fluctuating market prices for 20 unique stock symbols.
- **Real-time Visualization**: Provides a custom-rendered charting component that tracks total net worth over time.
- **Transactional Integrity**: Supports BUY and SELL operations with verification of available cash and sufficient holdings.
- **Dark Mode Interface**: A specialized desktop terminal layout designed for high-contrast visibility.

## Getting Started

### Prerequisites
- Java Development Kit (JDK) 8 or higher.
- MySQL Server 8.0 or higher.
- MySQL Connector/J driver (must be placed in the `lib` folder).

### Installation
1. **Initialize Database**:
   - Execute `db_schema.sql` to create the database structure and tables.
   - Execute `db_logic.sql` to initialize the triggers and stored procedures.
2. **Configure Connection**:
   - Open `src/com/stockportfolio/util/DatabaseConnection.java`.
   - Update the `USER` and `PASSWORD` constants to match your MySQL server configuration.
3. **Verify Library**:
   - Ensure a MySQL Connector `.jar` file exists within the `lib/` directory.

## Usage
The project includes a Windows batch script to automate compilation and execution.

1. Open a terminal in the project root directory.
2. Run the build script:
   ```powershell
   ./build_and_run.bat
   ```
The script will compile all source files into the `bin/` directory and launch the `StockPortfolioApp` class.

## License
Distributed under a standard license placeholder.
