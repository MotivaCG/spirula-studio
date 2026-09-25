# Shared settings for the chunk-training experiments on VIDEOTIKI frames 45-50.
$Take = "C:/Users/Victor/Documents/Gracia4DGSConverter/VIDEOTIKI/output"
$Work = "$Take/.work"
$Out = "D:/Dependencias/spirula-studio/outputs/tc"
# Experiments run a copy, so build_tc can be rebuilt while one is running.
$Exe = "$Out/bin/spirula.exe"
function FrameDir($f) { "$Work/000000$f/undistorted" }
function ForgeCkpt($f) { (Get-ChildItem (FrameDir $f) -Recurse -Directory -Filter "step-*.ckpt" | Sort-Object Name | Select-Object -Last 1).FullName }
# Forge's per-frame flags (depth/normal files exist for frame 45 only, so off).
$Common = @(
  "--steps-per-save", "-1", "--cap-max", "395204", "--sh-degree", "1", "--min-opacity", "0.01",
  "--mask-boundary-offset", "0.03", "--darkness-boost", "2",
  "--load-depths", "0", "--load-normals", "0",
  "--use-bilateral-grid", "0", "--use-bilateral-grid-for-geometry", "1", "--background-mode", "sh",
  "--disable-viewer", "1", "--keep-viewer-alive", "0", "--use-ppisp", "1", "--ppisp-from", "$Take/ppisp.ckpt",
  "--export-keep-all-splats", "1", "--sh-decay", "0.04", "--overexposure-reg", "10")
# Forge's warm-start extras (ReusePrevious).
$Warm = @("--init-ply-add-points", "0", "--refine-start-iter", "99999999", "--opacity-reg", "0",
          "--features-dc-lr", "0.0005", "--features-sh-lr", "0.000025")
