# KF2 and KF3, one change each against KF1 (SPACETIME_KEYFRAMES.md section 7):
# KF2 = record batch from 8 cameras of one frame; KF3 = depth-normal consistency 0.04 -> 0.1.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
& "$PSScriptRoot\battery_KF.ps1" -Name KF2s -Steps 400 -Smoke -Bin bin_kf2 -Extra @("--spacetime-same-frame", "1")
if (-not (Select-String -Path "$tc\KF2s_battery.log" -Pattern "smoke done" -Quiet)) { "STOP: smoke failed" | Add-Content "$tc\KF23_chain.log"; exit 1 }
& "$PSScriptRoot\battery_KF.ps1" -Name KF2 -Bin bin_kf2 -Extra @("--spacetime-same-frame", "1")
& "$PSScriptRoot\battery_KF.ps1" -Name KF3 -Bin bin_kf2 -Extra @("--normal-reg-weight", "0.1")
"chain done $(Get-Date)" | Add-Content "$tc\KF23_chain.log"
