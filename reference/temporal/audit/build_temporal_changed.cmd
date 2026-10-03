@echo off
setlocal
cd /d D:\Dependencias\spirula-studio
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 exit /b 1
set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8"
set "PATH=%CUDA_PATH%\bin;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%"
set "TARGET=build_tc"
if /i "%~1"=="build_vulkan" set "TARGET=build_vulkan"
if not "%~1"=="" if /i not "%~1"=="build_vulkan" exit /b 2
if /i "%~2"=="spirula" (
  cmake --build %TARGET% --target spirula -j 8
) else (
  if not "%~2"=="" exit /b 2
  cmake --build %TARGET% -j 8
)
exit /b %errorlevel%
