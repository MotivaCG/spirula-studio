# Battery B6 - smoothing on the best-quality recipe (B5a: warp + births, no boost), 45-65.
# Hypothesis: the flicker gap to C3 (15 vs 6) is the missing temporal smoothing.
#   B6a smoothing every 50 (position/rotation/opacity/colour 1) | B6b every 25.
# Accept if flicker <= 8 with fit >= 30.3 dB and coverage at 64 >= 90 %: then full take + seeds.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
$t0 = Get-Date
$w = "$tc\window.ps1"
$base = @("--temporal-first-frame-steps", "8000", "--temporal-warp-dir", "$tc/warps45",
          "--temporal-birth-dir", "$tc/births45", "--temporal-smooth-position", "1",
          "--temporal-smooth-rotation", "1", "--temporal-smooth-opacity", "1", "--temporal-smooth-color", "1")
& $w B6a 45 65 6 4000 @base --temporal-smooth-every 50 *> "$tc\B6_runs.log"
& $w B6b 45 65 6 4000 @base --temporal-smooth-every 25 *>> "$tc\B6_runs.log"
(Get-Content "$tc\b5_eval.py") -replace '\["C3.seq", "B4a.seq", "B5a.seq", "B5c.seq"\]', '["B5a.seq", "B6a.seq", "B6b.seq"]' | Set-Content "$tc\b6_eval.py"
python "$tc\b6_eval.py" *> "$tc\B6_table.txt"
"B6 done in $([int]((Get-Date) - $t0).TotalMinutes) min" | Add-Content "$tc\B6_table.txt"
