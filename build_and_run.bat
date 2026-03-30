@echo off
echo ====================================================
echo Building Swing Desktop Terminal...
echo ====================================================

if not exist "bin" mkdir bin

javac -d bin src\com\stockportfolio\model\*.java src\com\stockportfolio\util\*.java src\com\stockportfolio\dao\*.java src\com\stockportfolio\app\StockPortfolioApp.java

if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed.
    pause
    exit /b
)

echo Compilation Successful!
set FOUND_JAR=0
for %%i in (lib\mysql-connector-j-*.jar) do (
    set FOUND_JAR=1
    java -cp "bin;%%i" com.stockportfolio.app.StockPortfolioApp
    goto end
)
if %FOUND_JAR%==0 (
    echo [ERROR] Could not find 'mysql-connector-j-8.0.x.jar' in the 'lib' folder!
    pause
    exit /b
)
:end
