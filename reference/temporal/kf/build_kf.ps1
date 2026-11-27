# spirula (build_tc) with the keyframe spacetime engine; text checks first.
$ErrorActionPreference = "Continue"
$SP = "D:\Dependencias\spirula-studio"
& 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1' -Arch amd64 -HostArch amd64 -SkipAutomaticLocation *> $null
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch '\\Git\\(usr\\bin|mingw64\\bin|bin)' }) -join ';'
$env:PATH = "D:\Dependencias\vcpkg\downloads\tools\ninja\1.13.2-windows;C:\Program Files\CMake\bin;" + $env:PATH
Push-Location $SP
python tools/check_comment_length.py
"comment check exit $LASTEXITCODE"
python tools/check_ui_text.py
"ui text check exit $LASTEXITCODE"
& "C:\Program Files\CMake\bin\cmake.exe" --build build_tc --target spirula 2>&1 | Select-String -Pattern "error|warning C|FAILED|Linking|ninja: no work" | Select-Object -First 40
"build exit $LASTEXITCODE"
Pop-Location
