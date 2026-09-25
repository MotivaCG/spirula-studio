# window.ps1 <name> <first> <last> <window> <frame_steps> [extra]: sliding window from Forge's first frame.
param([string]$Name, [int]$First, [int]$Last, [int]$Window, [int]$FrameSteps,
      [Parameter(ValueFromRemainingArguments = $true)][string[]]$Extra)
. "$PSScriptRoot/common.ps1"
$frames = (($First + 1)..$Last | ForEach-Object { FrameDir $_ }) -join ";"
if (Test-Path "$Out/$Name") { Remove-Item -Recurse -Force "$Out/$Name" }
& $Exe train --data (FrameDir $First) --temporal-frames $frames --temporal-window $Window `
  --temporal-frame-steps $FrameSteps --output-dir-prefix $Out --output-dir-name $Name `
  @Common @Warm --init-ply "$(ForgeCkpt $First)/splat.ply" @Extra *> "$Out/$Name.log"
"$Name exit=$LASTEXITCODE"
($First..$Last | ForEach-Object { "$_ $Name $($_ - $First)" }) | Set-Content -Encoding ascii "$Out/$Name.seq"
