# evalply.ps1 <ply> <frame> <outname>: renders of trained views (every 8th camera), no training.
param([string]$Ply, [int]$Frame, [string]$Name)
. "$PSScriptRoot/common.ps1"
if (Test-Path "$Out/q/$Name") { Remove-Item -Recurse -Force "$Out/q/$Name" }
& $Exe train --data (FrameDir $Frame) --output-dir-prefix "$Out/q" --output-dir-name $Name @Common `
  --init-ply $Ply --num-iterations 0 --steps-per-save 0 --eval-mode interval --eval-interval 8 --save-eval-images 1 *> "$Out/q/$Name.log"
"exit=$LASTEXITCODE"
