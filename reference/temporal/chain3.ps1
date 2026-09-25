# chain2.ps1 <prefix> <first> <last> <chunk_frames> <steps_per_trained_frame> [extra spirula args...]
# Each chunk trains one frame past its end, which is dropped. The next chunk starts
# from the previous chunk's last kept frame and trains it again (not held); the
# sequence keeps the previous chunk's copy of that frame.
# Writes <prefix>.seq: "frame run index" for every frame of the sequence.
param([string]$Prefix, [int]$First, [int]$Last, [int]$Len, [int]$Steps,
      [Parameter(ValueFromRemainingArguments = $true)][string[]]$Extra)
. "$PSScriptRoot/common.ps1"
$inv = [Globalization.CultureInfo]::InvariantCulture
$a = $First; $k = 0; $prev = $null; $seq = @()
while ($a -lt $Last) {
  $b = [Math]::Min($a + $Len - 1, $Last)
  if ($Last - $b -lt 2) { $b = $Last }
  $c = [Math]::Min($b + 1, $Last)                 # context frame, trained then dropped
  $name = "{0}_{1:d2}" -f $Prefix, $k
  $frames = (($a + 1)..$c | ForEach-Object { FrameDir $_ }) -join ";"
  $trained = $c - $a + 1
  $scaler = ($trained * $Steps / 30000.0).ToString($inv)
  if ($prev) {
    $init = "$Out/$prev/frames/{0:d3}/splat.ply" -f $prevIdx
    $more = @()
  } else {
    $init = "$(ForgeCkpt $a)/splat.ply"; $more = @()
  }
  if (-not (Test-Path "$Out/$name/frames/frames.txt")) {
    if (Test-Path "$Out/$name") { Remove-Item -Recurse -Force "$Out/$name" }
    & $Exe train --data (FrameDir $a) --temporal-frames $frames --output-dir-prefix $Out --output-dir-name $name `
      @Common @Warm --steps-scaler $scaler --init-ply $init @more @Extra *> "$Out/$name.log"
    if ($LASTEXITCODE -ne 0) { throw "$name failed" }
  }
  $from = if ($prev) { $a + 1 } else { $a }
  foreach ($f in $from..$b) { $seq += "$f $name $($f - $a)" }
  "$name trained $a..$c keeps ..$b"
  $prevIdx = $b - $a; $prev = $name; $a = $b; $k++
}
$seq | Set-Content -Encoding ascii "$Out/$Prefix.seq"
"CHAIN $Prefix.seq"
