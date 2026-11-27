# Battery KF (SPACETIME_KEYFRAMES.md): spirula's spacetime trainer from the keyframe seed KF_seed
# (st_keyframe_seed.py), life = alpha x Gaussian, need-driven relocation, frames 45-76.
# Success (fixed before, as T2C): VGSEditor export <= 45 MB; HP error 66/73/76 at most 3 % above
# TP2M (14.50 / 12.18 / 13.08); whole-mask error <= TP2M; light 0.97-1.02; vibration <= 0.5 mm;
# face 73, hand 73, back and hair as sharp as T2C, no streaks. -Smoke: train only.
param([string]$Name = "KF1", [int]$Steps = 96000, [int]$Every = 1600, [switch]$Smoke, [string]$Bin = "bin_kf", [string[]]$Drop = @(), [string[]]$Extra = @())
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
$log = "$tc\$($Name)_battery.log"
$py = "D:\Dependencias\ref4d\venv\Scripts\python.exe"
$work = "D:\Gracia4DGSConverter\VIDEOTIKI_CHUNK\output_fg10\.work"
$frames = (46..76 | ForEach-Object { "$work/{0:d8}/undistorted" -f $_ }) -join ";"
$base = @("--data", "$work/00000045/undistorted", "--output-dir-prefix", $tc,
  "--steps-scaler", "1", "--steps-per-save", "-1", "--sh-degree", "1",
  "--min-opacity", "0.005", "--mask-boundary-offset", "0.03", "--darkness-boost", "2", "--opacity-boost", "1.5",
  "--load-depths", "0", "--load-normals", "0", "--input-depth-is-ray-depth", "0",
  "--depth-supervision-weight", "0", "--normal-supervision-weight", "0",
  "--use-bilateral-grid", "0", "--use-bilateral-grid-for-geometry", "1", "--use-ppisp", "1",
  "--background-mode", "sh", "--disable-viewer", "1", "--keep-viewer-alive", "0",
  "--temporal-frames", $frames,
  "--scales-lr", "0.005", "--scales-lr-final", "0.005", "--refine-start-iter", "99999999",
  "--features-dc-lr", "0.005", "--features-sh-lr", "0.00025",
  "--export-keep-all-splats", "1",
  "--temporal-room-ply", "$work/00000045/undistorted/smn/frames/room.ply",
  "--ppisp-from", "D:/Gracia4DGSConverter/VIDEOTIKI_CHUNK/output_fg10/ppisp.ckpt",
  "--sh-decay", "0.04", "--overexposure-reg", "10",
  "--opacity-reg", "0.01", "--num-iterations", "$Steps", "--spacetime-batch", "8",
  "--spacetime-relocate", "1", "--spacetime-relocate-every", "$Every", "--cap-max", "1800000",
  "--spacetime-init", "$tc/KF_seed", "--output-dir-name", $Name)
# -Drop removes flags with their value from the KF1 recipe (one change per run).
$kept = @(); for ($i = 0; $i -lt $base.Count; $i++) { if ($Drop -contains $base[$i]) { $i++ } else { $kept += $base[$i] } }
$base = $kept + $Extra
"train start $(Get-Date) steps $Steps every $Every extra $Extra drop $Drop" | Add-Content $log
if (Test-Path "$tc\$Name") { Remove-Item -Recurse -Force "$tc\$Name" }
$t = Get-Date
& "$tc\$Bin\spirula.exe" train @base *> "$tc\$Name.log"
$code = $LASTEXITCODE
"$Name exit=$code $([int]((Get-Date) - $t).TotalMinutes) min" | Add-Content $log
Get-Content "$tc\$Name.log" -Encoding Unicode | Where-Object { $_ -match "spacetime: |error|Error" } | Select-Object -Last 8 | Add-Content $log
if ($code -ne 0 -or -not (Test-Path "$tc\$Name\frames\031\splat.ply")) { "STOP: $Name failed" | Add-Content $log; exit 1 }
if ($Smoke) { "smoke done $(Get-Date)" | Add-Content $log; exit 0 }

if (Test-Path "$tc\$($Name)_clean") { Remove-Item -Recurse -Force "$tc\$($Name)_clean" }
foreach ($k in 0..31) {
  $d = "$tc\$($Name)_clean\frames\{0:d3}" -f $k
  New-Item -ItemType Directory -Force $d | Out-Null
  python "$PSScriptRoot\subject_filter.py" (45 + $k) ("$tc\$Name\frames\{0:d3}\splat.ply" -f $k) "$d\splat.ply" --hide *>&1 | Select-Object -Last 1 | Add-Content $log
}
Copy-Item "$tc\$Name\frames\birth_events.tsv" "$tc\$($Name)_clean\frames\birth_events.tsv"
$seq = "$tc\$($Name)_clean_vgs_in"
if (Test-Path $seq) { Remove-Item -Recurse -Force $seq }
New-Item -ItemType Directory -Force $seq | Out-Null
foreach ($k in 0..31) { New-Item -ItemType HardLink -Path ("$seq\{0:d8}.ply" -f (45 + $k)) -Target ("$tc\$($Name)_clean\frames\{0:d3}\splat.ply" -f $k) | Out-Null }
Copy-Item "$tc\$Name\frames\birth_events.tsv" "$seq\birth_events.tsv"
& "D:\Dependencias\vgsplyseq_deploy\vgsplyseq.exe" $seq "$tc\VGSCMP\$($Name)_clean.vgs" --chunk 32 *> "$tc\$($Name)_vgs.log"
"$($Name)_clean vgsplyseq $((Get-Item "$tc\VGSCMP\$($Name)_clean.vgs").Length) bytes | " + ((& "D:\Trabajos\THE4DSCANNER\VGSFileFormat_ply\build_plyseq4\encoder\Release\vgsrecords.exe" "$tc\VGSCMP\$($Name)_clean.vgs") -join " ") | Add-Content $log
& $py -I -X utf8 "$PSScriptRoot\vgsedit_export.py" "$tc\VGS5_clean" "$Name=$tc/$($Name)_clean/frames/000/splat.ply" 2>&1 | ForEach-Object { "$_" } | Add-Content $log

Push-Location $env:TEMP
$env:TPE_RUNS = "ST7L_clean NAIF TP2M_clean TRIGS_T2C_clean KF1_clean $($Name)_clean"
& $py -I -X utf8 "$PSScriptRoot\transplant_eval.py" "$tc\$($Name)_FACE.png" 52 60 66 73 76 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch "Warning|warn|lambda a" } | Add-Content $log
& $py -I -X utf8 "$PSScriptRoot\hand_views.py" 45 28 71 560 980 720 1180 "$tc\$($Name)_HAND73.png" NAIF73 TRIGS_T2C_clean KF1_clean "$($Name)_clean" 2>&1 | Select-Object -Last 1 | ForEach-Object { "$_" } | Add-Content $log
$env:BFS_FRAMES = "45 52 66 73"
& $py -I -X utf8 "$PSScriptRoot\back_feet_sheet.py" "$tc\$($Name)_BACK_FEET.png" TRIGS_T2C_clean KF1_clean "$($Name)_clean" 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -notmatch "Warning|warn" } | Add-Content $log
Pop-Location
python "$PSScriptRoot\vib_runs.py" TRIGS_T2C KF1 $Name *>&1 | Add-Content $log
python "$PSScriptRoot\floor_dirt.py" TRIGS_T2C_clean KF1_clean "$($Name)_clean" *>&1 | Add-Content $log
"done $(Get-Date)" | Add-Content $log
