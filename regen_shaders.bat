@echo off
setlocal enabledelayedexpansion
rem ---------------------------------------------------------------------------
rem Regenerates src/generated/*.cuh from src/shaders/*.slang.
rem
rem   regen_shaders.bat                 all of them
rem   regen_shaders.bat per_pixel_losses    just that one (plus its dependencies)
rem
rem WHY THIS EXISTS: those .cuh are committed but generated, so git happily
rem "resolves" them on a merge into something that matches NEITHER side and no
rem .slang at all. Never hand-merge one and never take a side: resolve the
rem .slang, then run this. See docs/codegen.md.
rem
rem The slangc CMake pins (SS_SLANG_VERSION, currently 2026.12.0.1) is for the
rem Vulkan SPIR-V build and produces structurally DIFFERENT CUDA -- it also
rem cannot compile primitive_3dgs.slang at all. These headers need 2026.2.1,
rem which is what src/shaders/build.bash was written against. Different jobs,
rem different compilers.
rem ---------------------------------------------------------------------------

cd /d "%~dp0"

set "SLANGC_DIR=%~dp0build\slang-2026.2.1-windows-x86_64\bin"
if not exist "%SLANGC_DIR%\slangc.exe" (
    echo ERROR: no encuentro slangc 2026.2.1 en:
    echo   %SLANGC_DIR%
    echo.
    echo Descargalo de:
    echo   https://github.com/shader-slang/slang/releases/tag/v2026.2.1
    echo   slang-2026.2.1-windows-x86_64.zip
    echo y descomprimelo ahi ^(debe quedar bin\slangc.exe dentro^).
    exit /b 1
)

rem Git Bash by an explicit path, never `where bash`: on a machine with WSL
rem installed that finds System32\bash.exe, which cannot run this at all and
rem fails with an execvpe error that says nothing about the real problem.
rem Derived from git.exe so it follows a non-default install.
set "GITBASH="
for /f "delims=" %%G in ('where git 2^>nul') do (
    if not defined GITBASH (
        for %%R in ("%%~dpG..") do (
            if exist "%%~fR\bin\bash.exe" set "GITBASH=%%~fR\bin\bash.exe"
        )
    )
)
if not defined GITBASH if exist "%ProgramFiles%\Git\bin\bash.exe" set "GITBASH=%ProgramFiles%\Git\bin\bash.exe"
if not defined GITBASH (
    echo ERROR: no encuentro el bash de Git for Windows.
    echo   src\shaders\build.bash es la unica fuente de verdad de este paso,
    echo   duplicarla en .bat solo crearia una segunda que se desincroniza.
    echo   Instala Git for Windows, o pon bash.exe en %%GITBASH%%.
    exit /b 1
)
where python3 >nul 2>&1
if errorlevel 1 (
    echo ERROR: hace falta python3 en el PATH ^(build_postprocess.py^).
    exit /b 1
)

rem Conflict markers in a .slang would be compiled as source and fail with a
rem confusing parser error 200 lines away. Say so here instead.
for %%F in (src\shaders\*.slang) do (
    findstr /b /c:"<<<<<<<" "%%F" >nul 2>&1
    if not errorlevel 1 (
        echo ERROR: %%F todavia tiene marcadores de conflicto.
        echo Resuelve el .slang PRIMERO, luego vuelve a lanzar esto.
        exit /b 1
    )
)

set "ONLY=%~1"

rem Snapshot so the "only this one" mode can put the others back: build.bash
rem always rebuilds all ten, and on Windows a few come out with independent
rem statements emitted in a different order than the committed (Linux) copies.
rem Semantically identical, but it is churn nobody wants in a merge diff.
rem
rem A plain copy, not `git checkout --`: that restores an unmerged file to its
rem CONFLICTED state, so with two conflicting .cuh it would put the markers back
rem into the one you were not regenerating.
set "SNAP=%TEMP%\spirula_regen_snap"
if not "%ONLY%"=="" (
    if not exist "src\generated\%ONLY%.cuh" (
        echo ERROR: src\generated\%ONLY%.cuh no existe.
        echo Nombres validos: el de un .slang sin extension, p.ej. per_pixel_losses
        exit /b 1
    )
    if exist "%SNAP%" rd /s /q "%SNAP%"
    mkdir "%SNAP%" 2>nul
    copy /y "src\generated\*.cuh" "%SNAP%\" >nul
    if errorlevel 1 (
        echo ERROR: no pude copiar src\generated\*.cuh a %SNAP%
        exit /b 1
    )
    echo Regenerando solo %ONLY% ^(el resto se restaura al terminar^).
)

echo.
echo Usando slangc 2026.2.1 de %SLANGC_DIR%
echo.

set "PATH=%SLANGC_DIR%;%PATH%"
pushd src
"%GITBASH%" shaders/build.bash
rem Captured immediately: any command after this one overwrites ERRORLEVEL.
set /a RC=%ERRORLEVEL%
popd

rem Leftover intermediates: build.bash only renames what it produced, and on a
rem failure the half-built .cu and the logs stay behind looking like sources.
del /q src\generated\*.cu >nul 2>&1
del /q src\generated\*.cu.log >nul 2>&1

if %RC% neq 0 (
    echo.
    echo FALLO: build.bash devolvio %RC%. Nada que hacer aqui, mira el error de arriba.
    exit /b %RC%
)

if not "%ONLY%"=="" (
    for %%F in ("%SNAP%\*.cuh") do (
        if /i not "%%~nF"=="%ONLY%" copy /y "%%F" "src\generated\%%~nxF" >nul
    )
    rd /s /q "%SNAP%" 2>nul
)

echo.
echo Listo. Lo que cambio:
git status --short src/generated/
echo.
echo Recuerda: si estabas en un merge, marca el fichero como resuelto con
echo   git add src/generated/^<fichero^>.cuh
exit /b 0
