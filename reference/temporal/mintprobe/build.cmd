@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
"C:\Qt\Qt6.8.1\6.8.0\msvc2022_64\bin\qmake.exe" mintprobe.pro -o Makefile
if errorlevel 1 exit /b 1
nmake /nologo /f Makefile > build.log 2>&1
if errorlevel 1 type build.log
