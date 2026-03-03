@echo off
setlocal EnableExtensions

set "ROOT=P:\BSP_LocalDev\Manivannan.Mathialag"

echo ===============================================
echo FAST Git repo email scan (2 levels) under:
echo %ROOT%
echo ===============================================

for /d %%A in ("%ROOT%\*") do (
  if exist "%%A\.git\config" call :PRINT "%%A"
  for /d %%B in ("%%A\*") do (
    if exist "%%B\.git\config" call :PRINT "%%B"
    for /d %%C in ("%%B\*") do (
      if exist "%%C\.git\config" call :PRINT "%%C"
    )
  )
)

echo ===============================================
pause
exit /b

:PRINT
echo %~1 ^|
pushd "%~1" >nul
git config --get user.email
popd >nul
exit /b