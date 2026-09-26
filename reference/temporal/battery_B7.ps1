# Battery B7 - shared-scale drift in the window (B5a: scale of a splat changes ~15 % between
# consecutive written frames; 0 inside a C3 chunk). Hypothesis: that drift is the window's
# remaining flicker. B5a recipe (warp + births, no boost, no smoothing), frames 45-65:
#   B7a scale frozen (--scales-lr 0) | B7b scale learning rate / 10.
# Accept if flicker <= 8 with fit >= 30.3 dB and coverage at 64 >= 90 %.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
$t0 = Get-Date
$w = "$tc\window.ps1"
$base = @("--temporal-first-frame-steps", "8000", "--temporal-warp-dir", "$tc/warps45", "--temporal-birth-dir", "$tc/births45")
& $w B7a 45 65 6 4000 @base --scales-lr 0 --scales-lr-final 0 *> "$tc\B7_runs.log"
& $w B7b 45 65 6 4000 @base --scales-lr 0.002 --scales-lr-final 0.0005 *>> "$tc\B7_runs.log"
(Get-Content "$tc\b5_eval.py") -replace '\["C3.seq", "B4a.seq", "B5a.seq", "B5c.seq"\]', '["B5a.seq", "B7a.seq", "B7b.seq"]' | Set-Content "$tc\b7_eval.py"
python "$tc\b7_eval.py" *> "$tc\B7_table.txt"
"B7 done in $([int]((Get-Date) - $t0).TotalMinutes) min" | Add-Content "$tc\B7_table.txt"
