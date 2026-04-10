@echo off
echo ========================================
echo Slay the Robot - CSV to JSON Converter
echo ========================================
echo.

REM Change to script directory to ensure correct paths
cd /d "%~dp0"

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://python.org
    pause
    exit /b 1
)

REM Check if cards.csv exists
if not exist "..\config\cards.csv" (
    echo CSV file not found. Creating from template...
    python "csv_to_json.py" --create-sample
    if errorlevel 1 (
        pause
        exit /b 1
    )
    echo.
    echo Please edit external/config/cards.csv and run this script again.
    pause
    exit /b 0
)

echo Running converter...
python "csv_to_json.py" %*

if errorlevel 1 (
    echo.
    echo Conversion completed with ERRORS
) else (
    echo.
    echo Conversion completed SUCCESSFULLY
)

echo.
pause