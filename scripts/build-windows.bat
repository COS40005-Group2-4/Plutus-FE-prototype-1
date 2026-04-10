@echo off
setlocal enabledelayedexpansion

echo === Plutus Windows Build ===

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "BACKEND_DIR=%PROJECT_DIR%\plutus-backend"

:: Check prerequisites
where go >nul 2>&1 || (echo ERROR: Go is not installed & exit /b 1)
where flutter >nul 2>&1 || (echo ERROR: Flutter is not installed & exit /b 1)
where gcc >nul 2>&1 || (echo ERROR: mingw-w64 GCC is not installed. Install via: choco install mingw & exit /b 1)

:: Step 1: Compile Go backend
echo --- Compiling Go backend (windows/amd64) ---
cd /d "%BACKEND_DIR%"
set CGO_ENABLED=1
set GOOS=windows
set GOARCH=amd64
go build -o "%PROJECT_DIR%\libplutus.dll" -buildmode=c-shared .
if errorlevel 1 (echo ERROR: Go build failed & exit /b 1)
echo Built libplutus.dll

:: Step 2: Flutter build
echo --- Building Flutter Windows app ---
cd /d "%PROJECT_DIR%"
call flutter pub get
call flutter build windows --release --dart-define-from-file=app.env
if errorlevel 1 (echo ERROR: Flutter build failed & exit /b 1)

:: Output
set "OUTPUT_DIR=%PROJECT_DIR%\build\windows\x64\runner\Release"
if exist "%OUTPUT_DIR%\plutus.exe" (
    echo.
    echo === Build successful ===
    echo Output: %OUTPUT_DIR%
    echo To run: %OUTPUT_DIR%\plutus.exe
) else (
    echo ERROR: Build output not found at %OUTPUT_DIR%
    exit /b 1
)

endlocal
