@echo off
setlocal enabledelayedexpansion
title QQ Bot Launcher (AstrBot + NapCat)
cd /d "%~dp0"

if not exist "config.bat" (
  echo [x] config.bat not found.
  echo     copy config.example.bat config.bat  then edit it.
  pause
  exit /b 1
)
call "config.bat"

if not exist "%NAPCAT_DIR%\launcher-user.bat" (
  echo [x] NapCat launcher not found: %NAPCAT_DIR%\launcher-user.bat
  echo     set NAPCAT_DIR in config.bat
  pause
  exit /b 1
)
if not exist "%ASTRBOT_EXE%" echo [x] warning: AstrBot not found at %ASTRBOT_EXE%

echo ============================================
echo   QQ Bot Launcher  (AstrBot + NapCat)
echo ============================================
echo.
echo [1/5] Stop existing QQ / NapCat ...
taskkill /f /im QQ.exe >nul 2>&1
taskkill /f /im NapCatWinBootMain.exe >nul 2>&1
ping -n 3 127.0.0.1 >nul

echo [2/5] Ensure AstrBot listens on 6199 ...
powershell -NoProfile -Command "if (-not (Get-NetTCPConnection -LocalPort 6199 -State Listen -ErrorAction SilentlyContinue)) { Start-Process '%ASTRBOT_EXE%' -WorkingDirectory (Split-Path '%ASTRBOT_EXE%') }" >nul 2>&1

set /a n=0
:wait_astrbot
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 6199 -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if not errorlevel 1 goto astrbot_ready
set /a n+=1
if %n% geq 60 goto astrbot_timeout
ping -n 2 127.0.0.1 >nul
goto wait_astrbot

:astrbot_timeout
echo       [x] timeout after ~90s, continuing anyway
goto astrbot_done

:astrbot_ready
echo       6199 is up

:astrbot_done
echo [3/5] Check loadNapCat.js ...
set "QAPP="
for /d %%D in ("%QQ_INSTALL_DIR%\*") do (
  if exist "%%D\resources\app\package.json" set "QAPP=%%D\resources\app"
)
if not defined QAPP (
  echo       [x] QQ app dir not found under %QQ_INSTALL_DIR%
  echo           set QQ_INSTALL_DIR in config.bat
) else (
  if not exist "%QAPP%\loadNapCat.js" (
    copy /y "%NAPCAT_DIR%\loadNapCat.js" "%QAPP%\" >nul
    echo       patched: %QAPP%
  ) else (
    echo       already present
  )
)

echo [4/5] Start QQ / NapCat (quick login %QQ_ACCOUNT%) ...
echo       Panel: http://127.0.0.1:6185   NapCat: http://127.0.0.1:6099/webui
echo.
call "%NAPCAT_DIR%\launcher-user.bat" -q %QQ_ACCOUNT%

echo.
echo [x] NapCat exited
pause
