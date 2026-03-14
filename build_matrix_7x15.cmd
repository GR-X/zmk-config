@echo off
chcp 65001 >nul
REM Build matrix_7x15 locally. Run from thinkpad repo root.

cd /d "%~dp0"

if not exist "config\west.yml" (
    echo Error: config\west.yml not found. Run from thinkpad repo root.
    pause
    exit /b 1
)

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "CONFIG=%ROOT%\config"
set "BUILD=%ROOT%\build\matrix_7x15"

set "ZMK_APP=zmk\app"
if not exist "zmk\app\CMakeLists.txt" (
    if exist ".zmk\zmk\app\CMakeLists.txt" set "ZMK_APP=.zmk\zmk\app"
)

set "EXTRA=%ROOT%"
if exist "%ROOT%\kb_zmk_ps2_mouse_trackpoint_driver" set "EXTRA=%ROOT%;%ROOT%\kb_zmk_ps2_mouse_trackpoint_driver"

echo ZMK app: %ZMK_APP%
echo ZMK_CONFIG: %CONFIG%
echo Build dir: %BUILD%
echo.

REM Must run west FROM zmk/app so Zephyr "build" extension is available
cd /d "%ROOT%\%ZMK_APP%"
if %ERRORLEVEL% neq 0 (
    echo Error: cannot cd to %ZMK_APP%
    pause
    exit /b 1
)

echo Running west build (pristine) ...
west build -d "%BUILD%" -p -b nice_nano -- -DZMK_CONFIG="%CONFIG%" -DSHIELD=matrix_7x15 -DZMK_EXTRA_MODULES="%EXTRA%"

if %ERRORLEVEL% neq 0 (
    echo Build failed.
    cd /d "%ROOT%"
    pause
    exit /b %ERRORLEVEL%
)

cd /d "%ROOT%"
if exist "%BUILD%\zephyr\zmk.uf2" (
    echo.
    echo Build OK. UF2: %BUILD%\zephyr\zmk.uf2
) else (
    echo Build finished but zmk.uf2 not found.
)
pause
