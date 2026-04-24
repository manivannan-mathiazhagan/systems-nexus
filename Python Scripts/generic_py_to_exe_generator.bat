@echo off
setlocal enabledelayedexpansion
title Python Standalone EXE Generator

echo =====================================================
echo Python Standalone EXE Generator
echo =====================================================
echo.

set /p APPNAME=Enter App Name without .exe: 
set /p PYSCRIPT=Enter full Python script path: 
set /p PNGICON=Enter full PNG icon path: 

set "PYSCRIPT=%PYSCRIPT:"=%"
set "PNGICON=%PNGICON:"=%"

if not exist "%PYSCRIPT%" (
    echo.
    echo ERROR: Python script not found:
    echo %PYSCRIPT%
    pause
    exit /b
)

if not exist "%PNGICON%" (
    echo.
    echo ERROR: PNG icon not found:
    echo %PNGICON%
    pause
    exit /b
)

for %%F in ("%PYSCRIPT%") do set "BASEDIR=%%~dpF"
for %%F in ("%PNGICON%") do set "ICONDIR=%%~dpF"
for %%F in ("%PNGICON%") do set "ICONNAME=%%~nF"

set "ICOICON=%ICONDIR%%ICONNAME%.ico"

echo.
echo Installing required packages...
python -m pip install --upgrade pip
python -m pip install --upgrade pyinstaller pillow PyMuPDF PyQt5

echo.
echo Creating ICO from PNG...

python -c "from PIL import Image; import sys; img=Image.open(r'%PNGICON%').convert('RGBA'); img.save(r'%ICOICON%', sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])"

if not exist "%ICOICON%" (
    echo.
    echo ERROR: ICO creation failed.
    pause
    exit /b
)

echo.
echo Building standalone EXE...

python -m PyInstaller ^
 --noconfirm ^
 --clean ^
 --onefile ^
 --windowed ^
 --name "%APPNAME%" ^
 --icon "%ICOICON%" ^
 --add-data "%PNGICON%;." ^
 --add-data "%ICOICON%;." ^
 --hidden-import fitz ^
 --hidden-import PyQt5.QtCore ^
 --hidden-import PyQt5.QtGui ^
 --hidden-import PyQt5.QtWidgets ^
 --distpath "%BASEDIR%dist" ^
 --workpath "%BASEDIR%build" ^
 "%PYSCRIPT%"

echo.
echo =====================================================
echo DONE
echo EXE created at:
echo %BASEDIR%dist\%APPNAME%.exe
echo =====================================================
echo.

pause
endlocal