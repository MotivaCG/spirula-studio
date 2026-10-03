param(
    [Parameter(Mandatory=$true)][string]$Name,
    [int]$First = 45,
    [int]$Last = 64,
    [int]$FrameSteps = 4000,
    [double]$ShLr = 0.000025,
    [string]$ExePath = '',
    [switch]$ValidateOnly
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../common.ps1"
if ($ExePath) { $Exe = $ExePath }
if ($Name -notmatch '^[A-Za-z0-9_-]+$') { throw 'Invalid run name' }
if ($First -ne 45 -or $Last -notin @(64, 76)) { throw 'Only validated 45:64 and 45:76 plans are supported' }
if (Get-Process -Name spirula -ErrorAction SilentlyContinue) { throw 'Another Spirula process is active' }
foreach ($path in @("$Out/$Name", "$Out/$Name.seq", "$Out/$Name.log", "$Out/$Name.inputs.json")) {
    if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite $path" }
}
foreach ($path in @($Exe, "$Take/ppisp.ckpt", "$Out/warps45", "$Out/births45")) {
    if (!(Test-Path -LiteralPath $path)) { throw "Missing $path" }
}
foreach ($frame in $First..$Last) {
    if (!(Test-Path -LiteralPath (FrameDir $frame))) { throw "Missing frame $frame" }
    if ($frame -gt $First) {
        $part = '{0:D3}.bin' -f ($frame - $First)
        foreach ($folder in @('warps45', 'births45')) {
            if (!(Test-Path -LiteralPath "$Out/$folder/$part")) { throw "Missing $folder/$part" }
        }
    }
}
$init = "$(ForgeCkpt $First)/splat.ply"
if (!(Test-Path -LiteralPath $init)) { throw 'Missing initial model' }
$frames = (($First + 1)..$Last | ForEach-Object { FrameDir $_ }) -join ';'
$warmFlags = @($Warm)
$shIndex = [Array]::IndexOf($warmFlags, '--features-sh-lr')
if ($shIndex -lt 0) { throw 'SH learning rate missing from common settings' }
$warmFlags[$shIndex + 1] = $ShLr.ToString('G', [Globalization.CultureInfo]::InvariantCulture)
$trainArgs = @('train', '--data', (FrameDir $First), '--temporal-frames', $frames,
    '--temporal-window', '6', '--temporal-frame-steps', "$FrameSteps", '--temporal-first-frame-steps', '8000',
    '--temporal-warp-dir', "$Out/warps45", '--temporal-birth-dir', "$Out/births45",
    '--temporal-entry-opacity-boost', '1', '--temporal-smooth-every', '0',
    '--scales-lr', '0.002', '--scales-lr-final', '0.0005',
    '--output-dir-prefix', $Out, '--output-dir-name', $Name) + $Common + $warmFlags + @('--init-ply', $init)
if ($ValidateOnly) {
    @{ status='PREFLIGHT_PASS'; name=$Name; frames=($Last-$First+1); steps=$FrameSteps; sh_lr=$ShLr } |
        ConvertTo-Json -Compress
    return
}
$hashedPaths = @($Exe, $init, "$Take/ppisp.ckpt", "$PSScriptRoot/../common.ps1")
foreach ($frame in ($First + 1)..$Last) {
    $part = '{0:D3}.bin' -f ($frame - $First)
    $hashedPaths += @("$Out/warps45/$part", "$Out/births45/$part")
}
$inputHashes = @($hashedPaths | ForEach-Object { Get-FileHash -LiteralPath $_ -Algorithm SHA256 } |
    Select-Object Path, Hash)
$datasetInventory = @($First..$Last | ForEach-Object {
    $datasetRoot = FrameDir $_
    foreach ($subdir in @('images', 'masks', 'sparse')) {
        Get-ChildItem -LiteralPath "$datasetRoot/$subdir" -File -Recurse |
            Select-Object FullName, Length, LastWriteTimeUtc
    }
})
@{ executable=$Exe; arguments=$trainArgs; sha256=$inputHashes; dataset_metadata=$datasetInventory;
    note='Image/mask/sparse inventory is size/mtime, not a content hash; freeze the dataset during execution.' } |
    ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 -LiteralPath "$Out/$Name.inputs.json"
& $Exe @trainArgs *> "$Out/$Name.log"
$trainingExit = $LASTEXITCODE
if ($trainingExit -ne 0) { throw "Training failed ($trainingExit); see $Out/$Name.log" }
foreach ($frame in $First..$Last) {
    $slot = '{0:D3}' -f ($frame - $First)
    if (!(Test-Path -LiteralPath "$Out/$Name/frames/$slot/splat.ply")) { throw "Missing output $slot" }
}
($First..$Last | ForEach-Object { "$_ $Name $($_ - $First)" }) |
    Set-Content -Encoding ascii -LiteralPath "$Out/$Name.seq"
Write-Output "$Name TRAIN_COMPLETE"
