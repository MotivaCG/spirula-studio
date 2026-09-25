# Battery B5 - where B4a's flicker comes from (pairs 49-65 at 35-61 vs C3 4-9).
# Hypothesis: the entry opacity boost causes it (each frame re-converges from x1.5 opacity).
# Frames 45-65, window W6, 4000 steps, first frame 8000, warps45/births45 as B4a.
#   B5a warp + births (no boost) | B5c warp only | B4a (reused, its 45-64 frames) = warp+births+boost.
# Decision: B5a flicker <= 10 -> drop the boost; B5c low and B5a high -> births cause it;
# all high -> start at 45 / first-frame steps.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
$t0 = Get-Date
$w = "$tc\window.ps1"
$base = @("--temporal-first-frame-steps", "8000", "--temporal-warp-dir", "$tc/warps45")
& $w B5a 45 65 6 4000 @base --temporal-birth-dir "$tc/births45" *> "$tc\B5_runs.log"
& $w B5c 45 65 6 4000 @base *>> "$tc\B5_runs.log"
python "$tc\b5_eval.py" *> "$tc\B5_table.txt"
"B5 done in $([int]((Get-Date) - $t0).TotalMinutes) min" | Add-Content "$tc\B5_table.txt"
