@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=P:\BSP_LocalDev\Manivannan.Mathialag\zzzz_My_SAS_Files\My GitHub"
set "NEW_NAME=Coder_Mani"
set "NEW_EMAIL=manivannan.mathi@outlook.com"
set /a COUNT=0

echo ===============================================
echo Setting Git identity under:
echo %ROOT%
echo ===============================================

if not exist "%ROOT%\" (
  echo ERROR: Root not found: %ROOT%
  pause
  exit /b 1
)

for /d %%A in ("%ROOT%\*") do (
  if exist "%%A\.git\config" call :SETCFG "%%A"
)

for /d %%A in ("%ROOT%\*") do (
  for /d %%B in ("%%A\*") do (
    if exist "%%B\.git\config" call :SETCFG "%%B"
  )
)

echo ===============================================
echo Total Repositories Updated: %COUNT%
echo ===============================================
pause
exit /b 0

:SETCFG
set /a COUNT+=1
echo -----------------------------------------------
echo !COUNT!. Updating Repo: %~1

pushd "%~1" >nul

git config user.name "%NEW_NAME%"
git config user.email "%NEW_EMAIL%"

echo    Now set to:
git config --get user.name
git config --get user.email

popd >nul
exit /b 0