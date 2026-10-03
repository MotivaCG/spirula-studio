@echo off
setlocal
if not defined VCToolsInstallDir (
  call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
  if errorlevel 1 exit /b 2
)
python "%~dp0run_audit.py" %*
exit /b %errorlevel%
