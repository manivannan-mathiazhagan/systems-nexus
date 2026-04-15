@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "verisas=C:\Program Files\SASHome\SASFoundation\9.4\sas.exe"
set "sascfg=C:\Program Files\SASHome\SASFoundation\9.4\nls\en\sasv9.cfg"

set "workdir=%~dp0"

REM Run all .sas files in alphabetical order
for /f "delims=" %%F in ('dir /b /a:-d "%workdir%*.sas" ^| sort') do (
  echo Running: %%F
  "%verisas%" -CONFIG "%sascfg%" -SYSIN "%workdir%%%F"
)

exit /b
