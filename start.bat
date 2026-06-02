@echo off
REM Wyld Land - private/self-host launcher (Windows)
REM Double-click this file, then enter a name + password in the browser.
cd /d "%~dp0"

REM Stop any previous run still running, so your settings (and the ports) start clean.
taskkill /F /IM wyld-local-windows.exe >nul 2>&1
taskkill /F /IM gns-modified-windows.exe >nul 2>&1

REM Optional GM/admin. Set this to a username BEFORE that account is first created:
REM whoever first logs in with this name becomes GM, permanently. Setting or changing
REM it later does NOT promote an account that already exists.
set ADMIN=

echo Starting Wyld Land (local)...

if "%ADMIN%"=="" (
  start "wyld-local" wyld-local\wyld-local-windows.exe -client .\client -saves .\saves -secret-file .\secret.key
) else (
  start "wyld-local" wyld-local\wyld-local-windows.exe -client .\client -saves .\saves -secret-file .\secret.key -admin %ADMIN%
)

:waitsecret
if not exist secret.key ( timeout /t 1 >nul & goto waitsecret )
set /p SECRET=<secret.key

cd server
set WYLD_JWT_SECRET=%SECRET%
set SERVER_NUM=0
set AUTH_SERVER_ADDRESS=http://localhost:3000
start "wyld-server" gns-modified-windows.exe
cd ..

timeout /t 2 >nul
start "" http://localhost:3000/dev.html

echo.
echo Wyld Land is running.
echo   Game:  http://localhost:3000/dev.html  (click "Login")
echo   Two windows opened (wyld-local, wyld-server). Close them to stop.
pause
