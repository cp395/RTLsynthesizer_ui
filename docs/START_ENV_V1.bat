@echo off
setlocal
cd /d "%~dp0"
set "APP_PYTHON=%~dp0.venv\Scripts\python.exe"

if not exist "%APP_PYTHON%" (
    echo [ERROR] Virtual environment not found: .venv
    echo Run: python -m venv .venv
    echo Then: .venv\Scripts\python.exe -m pip install -r requirements.txt
    pause
    exit /b 1
)

"%APP_PYTHON%" -c "import PySide6, numpy, PIL" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Dependencies are missing from .venv
    echo Run: .venv\Scripts\python.exe -m pip install -r requirements.txt
    pause
    exit /b 1
)

:menu
echo.
echo FPGA UI Designer
echo 1. Launch UI Designer
echo 2. Generate RTL from DX7 example
echo 3. Generate Python reference frame
echo 4. Open project folder
echo 5. Exit
set /p choice="Choose 1-5: "
if "%choice%"=="1" (
    "%APP_PYTHON%" run.py
    goto menu
)
if "%choice%"=="2" (
    "%APP_PYTHON%" examples\generate_dx7_rtl.py
    goto menu
)
if "%choice%"=="3" (
    "%APP_PYTHON%" testbench\test_renderer.py
    goto menu
)
if "%choice%"=="4" (
    start "" "%~dp0"
    goto menu
)
if "%choice%"=="5" exit /b 0
echo Invalid choice.
goto menu
