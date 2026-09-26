# Battery B8 - candidate recipe B7b over the whole take 45-76, twice (seed spread).
# Recipe: window W6, 4000 steps/frame, first 8000, warp + births, scale lr / 10, no boost,
# no smoothing. Accept as the new best if both runs: fit mean >= 30.5 and at 76 >= 30.0,
# coverage at 76 >= 88 %, flicker <= 9.5 (Gracia), and the two runs agree within 10 %.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
$t0 = Get-Date
$w = "$tc\window.ps1"
$base = @("--temporal-first-frame-steps", "8000", "--temporal-warp-dir", "$tc/warps45",
          "--temporal-birth-dir", "$tc/births45", "--scales-lr", "0.002", "--scales-lr-final", "0.0005")
& $w B8a 45 76 6 4000 @base *> "$tc\B8_runs.log"
& $w B8b 45 76 6 4000 @base *>> "$tc\B8_runs.log"
(Get-Content "$tc\b4_eval.py") -replace '\("B4a.seq", \[f"B4a.seq_\{f\}" for f in e.FRAMES\], pop.plys_of\("B4a.seq", 45\)\)', '("B8a.seq", [f"B8a.seq_{f}" for f in e.FRAMES], pop.plys_of("B8a.seq", 45))' -replace '\("B4b.seq", \[f"B4b.seq_\{f\}" for f in e.FRAMES\], pop.plys_of\("B4b.seq", 45\)\)', '("B8b.seq", [f"B8b.seq_{f}" for f in e.FRAMES], pop.plys_of("B8b.seq", 45))' | Set-Content "$tc\b8_eval.py"
python "$tc\b8_eval.py" *> "$tc\B8_table.txt"
python "$tc\make_gif.py" B8a.seq "$tc\B8a_45_76.gif" *>> "$tc\B8_gif.log"
"B8 done in $([int]((Get-Date) - $t0).TotalMinutes) min" | Add-Content "$tc\B8_table.txt"
