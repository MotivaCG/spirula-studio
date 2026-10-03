param([string]$Ply, [int]$Frame, [string]$Root, [string]$Name)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../common.ps1"
if (Test-Path -LiteralPath "$Root/$Name") { throw 'Render output already exists' }
& $Exe train --data (FrameDir $Frame) --output-dir-prefix $Root --output-dir-name $Name @Common `
  --init-ply $Ply --num-iterations 0 --steps-per-save 0 --eval-mode interval --eval-interval 8 --save-eval-images 1
if ($LASTEXITCODE -ne 0) { throw "Renderer failed: $LASTEXITCODE" }
if (!(Test-Path -LiteralPath "$Root/$Name/eval_views.txt")) { throw 'Renderer did not produce evaluation views' }
