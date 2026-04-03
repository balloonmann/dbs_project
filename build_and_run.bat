@echo off
echo ====================================================
echo Building Swing Desktop Terminal...
echo ====================================================

if not exist "bin" mkdir bin

javac -cp "lib\*" -d bin src\com\stockportfolio\model\*.java src\com\stockportfolio\util\*.java src\com\stockportfolio\dao\*.java src\com\stockportfolio\api\*.java src\com\stockportfolio\app\StockPortfolioApp.java

if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed.
    pause
    exit /b
)

echo Compilation Successful!
java -cp "bin;lib\*" com.stockportfolio.app.StockPortfolioApp
