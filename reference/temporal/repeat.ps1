# Repeated-frame controls: frame 50 as an 11-frame "sequence" with no motion.
. "$PSScriptRoot/common.ps1"
$f50 = FrameDir 50
$init = "$(ForgeCkpt 50)/splat.ply"
# RF1: the same window as Wd, frames 50..60 all being frame 50.
if (Test-Path "$Out/RF1") { Remove-Item -Recurse -Force "$Out/RF1" }
& $Exe train --data $f50 --temporal-frames ((1..10 | ForEach-Object { $f50 }) -join ";") `
  --temporal-window 6 --temporal-frame-steps 4000 --output-dir-prefix $Out --output-dir-name RF1 `
  @Common @Warm --init-ply $init *> "$Out/RF1.log"
"RF1 exit=$LASTEXITCODE"
(0..10 | ForEach-Object { "$(50 + $_) RF1 $_" }) | Set-Content -Encoding ascii "$Out/RF1.seq"
# RF2: one continuous training of frame 50 with the window's total budget (64000 steps).
if (Test-Path "$Out/RF2") { Remove-Item -Recurse -Force "$Out/RF2" }
& $Exe train --data $f50 --output-dir-prefix $Out --output-dir-name RF2 @Common @Warm `
  --init-ply $init --steps-scaler 2.133333 *> "$Out/RF2.log"
"RF2 exit=$LASTEXITCODE"
# RF3: frame 50 re-trained 11 times in a chain through the normal path (as R1, no motion).
$prev = $init; $seq = @()
foreach ($k in 0..10) {
  $run = "RF3_$k"
  if (Test-Path "$Out/$run") { Remove-Item -Recurse -Force "$Out/$run" }
  & $Exe train --data $f50 --output-dir-prefix $Out --output-dir-name $run @Common @Warm `
    --steps-scaler 0.133333 --init-ply $prev *> "$Out/$run.log"
  $prev = (Get-ChildItem "$Out/$run" -Directory -Filter "step-*.ckpt" | Sort-Object Name | Select-Object -Last 1).FullName + "/splat.ply"
  $seq += "$(50 + $k) $run 0"
}
$seq | Set-Content -Encoding ascii "$Out/RF3.seq"
"RF3 done"
