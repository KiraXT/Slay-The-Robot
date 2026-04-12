@echo off
chcp 65001 > nul
echo ========================================
echo Slay the Robot - 游戏配置转换器
echo ========================================
echo 支持: 卡牌 | 遗物 | 事件
echo.

REM Change to script directory to ensure correct paths
cd /d "%~dp0"

REM Check if Python is installed
python --version > nul 2>&1
if errorlevel 1 (
    echo 错误: 未检测到Python，请安装Python 3.8+
    echo 下载地址: https://python.org
    pause
    exit /b 1
)

REM Check for command line arguments
if "%~1"=="--create-sample" (
    echo 正在创建示例文件...
    python "convert.py" --create-sample
    pause
    exit /b 0
)

if "%~1"=="--cards" (
    echo 正在转换卡牌配置...
    python "convert.py" --cards
    pause
    exit /b 0
)

if "%~1"=="--artifacts" (
    echo 正在转换遗物配置...
    python "convert.py" --artifacts
    pause
    exit /b 0
)

if "%~1"=="--events" (
    echo 正在转换事件配置...
    python "convert.py" --events
    pause
    exit /b 0
)

REM Default: convert all
echo 正在转换所有配置...
python "convert.py"

if errorlevel 1 (
    echo.
    echo 转换完成，但存在错误
) else (
    echo.
    echo 转换成功完成！
)

echo.
echo 使用方式:
echo   convert.bat              - 转换所有配置
echo   convert.bat --cards      - 仅转换卡牌
echo   convert.bat --artifacts  - 仅转换遗物
echo   convert.bat --events     - 仅转换事件
echo   convert.bat --create-sample - 创建示例文件
echo.
pause
