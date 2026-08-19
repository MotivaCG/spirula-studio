@echo off
rem CUDA backend, CLI only, fat binary: Turing through Blackwell plus PTX.
rem Patent-encumbered modules stay out (see docs/build.md, SS_ENABLE_PATENTED).

setlocal
cd /d "%~dp0.."
if not defined SS_BUILD_DIR set "SS_BUILD_DIR=build_cuda_fatbin"
set "SS_CUDA_FATBIN=1"
call build_develop.bat ^
    -DSS_BACKEND=cuda ^
    -DSS_BUILD_CLI=ON ^
    -DSS_BUILD_GUI=OFF ^
    -DSS_ENABLE_PATENTED=OFF ^
    %*
exit /b %errorlevel%
