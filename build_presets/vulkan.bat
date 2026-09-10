@echo off
rem Vulkan backend, CLI + GUI. No CUDA toolkit needed.
rem Patent-encumbered modules stay out (see docs/build.md, SS_ENABLE_PATENTED).

setlocal
cd /d "%~dp0.."
if not defined SS_BUILD_DIR set "SS_BUILD_DIR=build_vulkan"
call build_develop.bat ^
    -DSS_BACKEND=vulkan ^
    -DSS_BUILD_GUI=ON ^
    -DSS_ENABLE_PATENTED=OFF ^
    %*
exit /b %errorlevel%
