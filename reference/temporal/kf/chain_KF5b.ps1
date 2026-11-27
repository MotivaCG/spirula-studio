# KF5 again (constant DC colour) once KF4-KF6 is done: the first run died at 84 %
# with a CUDA illegal access no other run has shown; a second crash rules it out.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
while (-not ((Test-Path "$tc\KF456_chain.log") -and (Select-String -Path "$tc\KF456_chain.log" -Pattern "chain done" -Quiet))) { Start-Sleep 60 }
& "$PSScriptRoot\battery_KF.ps1" -Name KF5b -Bin bin_kf3 -Extra @("--spacetime-constant-color", "1")
"chain done $(Get-Date)" | Add-Content "$tc\KF5b_chain.log"
