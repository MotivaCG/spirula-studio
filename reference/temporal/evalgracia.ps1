# evalgracia.ps1 <frame>: renders of Gracia's tiki frame from our cameras (moved into its frame).
param([int]$Frame)
. "$PSScriptRoot/common.ps1"
$name = "gracia_$Frame"
if (Test-Path "$Out/q/$name") { Remove-Item -Recurse -Force "$Out/q/$name" }
$fd = FrameDir $Frame
& $Exe train --data "$Out/gracia/data" --image-dir "$fd/images" --mask-dir "$fd/masks" `
  --output-dir-prefix "$Out/q" --output-dir-name $name --init-ply "$Out/gracia/gracia_$Frame.ply" `
  --sh-degree 3 --use-ppisp 0 --use-bilateral-grid 0 --load-depths 0 --load-normals 0 --background-mode sh `
  --disable-viewer 1 --keep-viewer-alive 0 --export-keep-all-splats 1 --cap-max 400000 `
  --num-iterations 0 --steps-per-save 0 --eval-mode interval --eval-interval 8 --save-eval-images 1 *> "$Out/q/$name.log"
"exit=$LASTEXITCODE"
