# Battery B2 - repeated-frame control.
# Hypothesis: if frame 50 repeated as a motionless 11-frame sequence (RF1, RF3) also loses
# subject splats, part of the death comes from re-optimizing, not from following motion.
# Compare: RF1 vs Wd (same window, real frames), RF3 vs R1 (same plain chain), RF2 = one
# continuous training of frame 50 with the window's total budget.
# Decision: RF1/RF3 losing >= half of what Wd/R1 lose -> re-optimization is a main cause,
# births alone will not fix it; otherwise motion is the cause, go to births (B3).
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
$t0 = Get-Date
& "$tc\repeat.ps1" *> "$tc\B2_runs.log"
python "$tc\b2_eval.py" *> "$tc\B2_table.txt"
"B2 done in $([int]((Get-Date) - $t0).TotalMinutes) min" | Add-Content "$tc\B2_table.txt"
