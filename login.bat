@echo off
setlocal
cd /d "%~dp0"
if not exist "config.bat" (
  echo [x] config.bat not found.
  echo     copy config.example.bat config.bat  then edit it.
  pause
  exit /b 1
)
call "config.bat"

set "ACCT="
set /p "ACCT=QQ account [default %QQ_ACCOUNT%]: "
if "%ACCT%"=="" set "ACCT=%QQ_ACCOUNT%"

set "QPWD="
set /p "QPWD=QQ password [empty = QR login]: "

echo.
if "%QPWD%"=="" (
  echo Mode: QR login
  echo   The QR code is printed in this console and saved to:
  echo   %NAPCAT_DIR%\cache\qrcode.png
  echo   Optional viewer: python qrview\serve.py  then open http://127.0.0.1:8099/
  echo.
  call "%NAPCAT_DIR%\launcher-user.bat" -q %ACCT%
) else (
  echo Mode: password login
  set "NAPCAT_QUICK_ACCOUNT=%ACCT%"
  set "NAPCAT_QUICK_PASSWORD=%QPWD%"
  echo.
  call "%NAPCAT_DIR%\launcher-user.bat" -q %ACCT%
)

echo.
echo NapCat exited
pause
