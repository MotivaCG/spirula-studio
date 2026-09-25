# Battery B3 - births that keep identity, 2x2 on frames 50-60 (window W6, 4000 steps, no smoothing).
# Hypothesis: seeding the entering frame's subject SfM points into gaps restores covered
# surface lost to motion (B2) without adding flicker.
# Variants: Ws = warp (from B1, reused) | B3b = warp + boost 1.5 | B3c = warp + births |
#           B3d = warp + births + boost 1.5. Births: gap 1 cm, cap 2 % per frame.
# Metrics: coverage 50->60, fit, detail, regional flicker (+ counts).
# Accept births if vs Ws: coverage at 60 >= +2 points, fit and detail not below by > 0.2 dB,
# flicker not above by > 15 %. Otherwise record why and rethink before any full-take run.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
$SP = "C:\Users\Victor\AppData\Local\Temp\claude\D--Trabajos-FORMS-LichtFeld-Studio\94f3fca3-18b7-436e-85cc-dace05fd9989\scratchpad"
$t0 = Get-Date
Set-Location "D:\Dependencias\spirula-studio"
python tools/check_comment_length.py *> "$tc\B3_build.log"
& cmd.exe /c "`"$SP\build_tc.cmd`"" *>> "$tc\B3_build.log"
if ($LASTEXITCODE -ne 0) { "BUILD FAILED" | Set-Content "$tc\B3_table.txt"; (Select-String -Path "$tc\B3_build.log" -Pattern "error|budget" | Select-Object -First 8) | Add-Content "$tc\B3_table.txt"; exit 1 }
Copy-Item "build_tc\spirula.exe" "$tc\bin\spirula.exe" -Force
python "$tc\births.py" 50 60 "$tc\births50" *> "$tc\B3_births.log"
$w = "$tc\window.ps1"; $warp = @("--temporal-warp-dir", "$tc/warps50"); $born = @("--temporal-birth-dir", "$tc/births50")
& $w B3b 50 60 6 4000 @warp --temporal-entry-opacity-boost 1.5 *> "$tc\B3_runs.log"
& $w B3c 50 60 6 4000 @warp @born *>> "$tc\B3_runs.log"
& $w B3d 50 60 6 4000 @warp @born --temporal-entry-opacity-boost 1.5 *>> "$tc\B3_runs.log"
python "$tc\b3_eval.py" *> "$tc\B3_table.txt"
Select-String -Path "$tc\B3c.log","$tc\B3d.log" -Pattern "splats born" | ForEach-Object { $_.Line } | Add-Content "$tc\B3_table.txt"
"B3 done in $([int]((Get-Date) - $t0).TotalMinutes) min" | Add-Content "$tc\B3_table.txt"
