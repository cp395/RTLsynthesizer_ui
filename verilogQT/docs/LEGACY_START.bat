@echo off
REM FPGA UI Designer - Quick Start Script
REM Windows Batch File

echo ================================================
echo FPGA UI Designer - Quick Start
echo ================================================
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found!
    echo Please install Python 3.8+ from python.org
    pause
    exit /b 1
)

echo [OK] Python found

REM Check dependencies
echo.
echo Checking dependencies...
python -c "import PySide6" >nul 2>&1
if errorlevel 1 (
    echo [WARN] PySide6 not installed
    echo Installing dependencies...
    pip install PySide6 pillow numpy
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
)

echo [OK] Dependencies installed
echo.

REM Menu
:menu
echo ================================================
echo Choose an option:
echo ================================================
echo.
echo 1. Launch UI Designer (Visual Editor)
echo 2. Generate RTL from DX7 example
echo 3. Test renderer (generate reference PNG)
echo 4. Open project folder
echo 5. Exit
echo.
set /p choice="Enter choice (1-5): "

if "%choice%"=="1" goto designer
if "%choice%"=="2" goto generate
if "%choice%"=="3" goto test
if "%choice%"=="4" goto folder
if "%choice%"=="5" goto end

echo Invalid choice!
goto menu

:designer
echo.
echo Launching UI Designer...
cd designer
python ui_designer.py
cd ..
goto menu

:generate
echo.
echo Generating RTL from DX7 Synth example...
cd examples
python generate_dx7_rtl.py
cd ..
echo.
echo [SUCCESS] RTL prototype files generated in examples\generated_rtl\
echo.
pause
goto menu

:test
echo.
echo Running renderer test...
cd testbench
python test_renderer.py
cd ..
echo.
echo Check testbench/reference_frame.png
pause
goto menu

:folder
echo.
echo Opening project folder...
start .
goto menu

:end
echo.
echo Goodbye!
