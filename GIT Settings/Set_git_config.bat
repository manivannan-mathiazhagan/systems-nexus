@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =========================================================
REM Root paths
REM =========================================================
set "ROOT=P:\BSP_LocalDev\Manivannan.Mathialag"
set "PERSONAL_ROOT=P:\BSP_LocalDev\Manivannan.Mathialag\zzzz_My_SAS_Files\My GitHub"

REM =========================================================
REM Personal Git identity
REM =========================================================
set "PERSONAL_NAME=Coder_Mani"
set "PERSONAL_EMAIL=manivannan.mathi@outlook.com"

REM =========================================================
REM Professional Git identity
REM =========================================================
set "WORK_NAME=Manivannan Mathialagan"
set "WORK_EMAIL=manivannan.mathialagan@veristat.com"

set /a COUNT_TOTAL=0
set /a COUNT_PERSONAL=0
set /a COUNT_WORK=0
set /a COUNT_SKIPPED=0

echo =========================================================
echo Git Identity Updater
echo Root           : %ROOT%
echo Personal Root  : %PERSONAL_ROOT%
echo =========================================================

if not exist "%ROOT%\" (
    echo ERROR: Root not found: %ROOT%
    pause
    exit /b 1
)

if not exist "%PERSONAL_ROOT%\" (
    echo WARNING: Personal root not found: %PERSONAL_ROOT%
    echo Personal repos will not be detected unless path exists.
)

REM =========================================================
REM Recursively scan all folders under ROOT
REM =========================================================
for /f "delims=" %%R in ('dir "%ROOT%" /ad /b /s 2^>nul') do (
    if exist "%%R\.git\config" call :PROCESS_REPO "%%R"
)

echo =========================================================
echo Completed
echo Total Repositories Updated : %COUNT_TOTAL%
echo Personal Repositories      : %COUNT_PERSONAL%
echo Professional Repositories  : %COUNT_WORK%
echo Skipped                    : %COUNT_SKIPPED%
echo =========================================================
pause
exit /b 0

:PROCESS_REPO
set "REPO=%~1"

REM ---------------------------------------------------------
REM Decide whether repo is personal or professional
REM ---------------------------------------------------------
echo "%REPO%" | find /I "%PERSONAL_ROOT%" >nul
if not errorlevel 1 (
    call :SETCFG "%REPO%" "%PERSONAL_NAME%" "%PERSONAL_EMAIL%" "PERSONAL"
) else (
    call :SETCFG "%REPO%" "%WORK_NAME%" "%WORK_EMAIL%" "WORK"
)

exit /b 0

:SETCFG
set "REPO=%~1"
set "GIT_NAME=%~2"
set "GIT_EMAIL=%~3"
set "TYPE=%~4"

set /a COUNT_TOTAL+=1
if /I "%TYPE%"=="PERSONAL" set /a COUNT_PERSONAL+=1
if /I "%TYPE%"=="WORK" set /a COUNT_WORK+=1

echo ---------------------------------------------------------
echo Updating %TYPE% repo:
echo %REPO%

pushd "%REPO%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Could not access repo: %REPO%
    set /a COUNT_SKIPPED+=1
    exit /b 0
)

git config user.name "%GIT_NAME%"
git config user.email "%GIT_EMAIL%"

echo   Name : 
git config --get user.name
echo   Email:
git config --get user.email

popd >nul
exit /b 0