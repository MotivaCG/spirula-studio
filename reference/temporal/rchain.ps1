# rchain.ps1 <name> <first> <last> <steps> [extra]: plain per-frame warm-start chain, no temporal code.
param([string]$Name, [int]$First, [int]$Last, [int]$Steps, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Extra)
. "$PSScriptRoot/common.ps1"
$scaler = ($Steps / 30000.0).ToString([Globalization.CultureInfo]::InvariantCulture)
$prev = "$(ForgeCkpt $First)/splat.ply"
$seq = @()
foreach ($f in $First..$Last) {
  $run = "{0}_{1}" -f $Name, $f
  if (Test-Path "$Out/$run") { Remove-Item -Recurse -Force "$Out/$run" }
  & $Exe train --data (FrameDir $f) --output-dir-prefix $Out --output-dir-name $run @Common @Warm `
    --steps-scaler $scaler --init-ply $prev @Extra *> "$Out/$run.log"
  if ($LASTEXITCODE -ne 0) { throw "$run failed" }
  $prev = (Get-ChildItem "$Out/$run" -Directory -Filter "step-*.ckpt" | Sort-Object Name | Select-Object -Last 1).FullName + "/splat.ply"
  $seq += "$f $run 0"
}
$seq | Set-Content -Encoding ascii "$Out/$Name.seq"
"$Name done"
