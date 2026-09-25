# Battery B4 - full take 45-76 with the B3d recipe, with and without smoothing.
# Hypothesis: births keep covered surface over 32 frames, so fit no longer decays
# (C3: 30.3 -> 27.2 dB); smoothing on top lowers flicker towards Gracia.
# Variants (window W6, 4000 steps/frame, first frame 8000, warp + births + boost 1.5):
#   B4a no smoothing | B4b + smoothing every 50 (position/rotation 1, opacity/colour 1).
# References reused: C3, Forge, Gracia (45-76 renders exist).
# Accept as the new best if vs C3: fit at 76 >= 29.5 dB and mean fit >= C3's, coverage at 76
# >= 85 %, regional flicker <= 9.5 (Gracia's). Then: seeds + GIF. Else record and rethink.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
$t0 = Get-Date
python "$tc\warps.py" 45 76 "$tc\warps45" *> "$tc\B4_prep.log"
python "$tc\births.py" 45 76 "$tc\births45" *>> "$tc\B4_prep.log"
$w = "$tc\window.ps1"
$base = @("--temporal-first-frame-steps", "8000", "--temporal-warp-dir", "$tc/warps45",
          "--temporal-birth-dir", "$tc/births45", "--temporal-entry-opacity-boost", "1.5")
& $w B4a 45 76 6 4000 @base *> "$tc\B4_runs.log"
& $w B4b 45 76 6 4000 @base --temporal-smooth-every 50 --temporal-smooth-position 1 `
  --temporal-smooth-rotation 1 --temporal-smooth-opacity 1 --temporal-smooth-color 1 *>> "$tc\B4_runs.log"
python "$tc\b4_eval.py" *> "$tc\B4_table.txt"
"B4 done in $([int]((Get-Date) - $t0).TotalMinutes) min" | Add-Content "$tc\B4_table.txt"
