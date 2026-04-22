#!/bin/bash
# ============================================================
# DBS Project — One-Click Launcher (macOS)
# Double-click this file to start the application.
# ============================================================

# Move to the project directory (where this script lives)
cd "$(dirname "$0")"

echo "=========================================="
echo "  DBS Project — Stock Portfolio System"
echo "=========================================="
echo ""

# ---------- 1. Check if MySQL is installed ----------
if ! command -v mysql &> /dev/null; then
    echo "ERROR: MySQL is not installed."
    echo "Install it with: brew install mysql"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# ---------- 2. Start MySQL if not running ----------
echo "[1/5] Checking MySQL service..."
if ! mysqladmin ping -u root -psamarthdbsproject --silent 2>/dev/null; then
    echo "       Starting MySQL..."
    brew services start mysql 2>/dev/null || mysql.server start 2>/dev/null
    sleep 3
fi
echo "       MySQL is running."

# ---------- 3. Set up the database ----------
echo "[2/5] Setting up database..."
mysql -u root -psamarthdbsproject -e "DROP DATABASE IF EXISTS stock_portfolio_db;" 2>/dev/null
mysql -u root -psamarthdbsproject < database/schema.sql 2>/dev/null
mysql -u root -psamarthdbsproject < database/seed_data.sql 2>/dev/null
mysql -u root -psamarthdbsproject < database/views.sql 2>/dev/null
mysql -u root -psamarthdbsproject < database/procedures.sql 2>/dev/null
mysql -u root -psamarthdbsproject < database/triggers.sql 2>/dev/null
echo "       Database ready (stock_portfolio_db)."

# ---------- 4. Install npm dependencies if needed ----------
echo "[3/5] Checking npm dependencies..."
if [ ! -d "server/node_modules" ]; then
    echo "       Installing dependencies..."
    cd server && npm install && cd ..
else
    echo "       Dependencies already installed."
fi

# ---------- 5. Start the server ----------
echo "[4/5] Starting server..."
cd server
node server.js &
SERVER_PID=$!
cd ..

# Wait for server to be ready
sleep 2

# ---------- 6. Open in browser ----------
echo "[5/5] Opening browser..."
open http://localhost:3000

echo ""
echo "=========================================="
echo "  App running at http://localhost:3000"
echo "  Press Ctrl+C to stop the server."
echo "=========================================="
echo ""

# Keep the terminal open and wait for the server process
wait $SERVER_PID
