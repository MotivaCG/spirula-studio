# KF4-KF6, one change each against KF1 (SPACETIME_KEYFRAMES.md section 8):
# KF4 = no PPISP; KF5 = constant DC colour; KF6 = without spirula's extra losses
# (darkness boost, opacity boost, overexposure reg, SH decay), as T2c trains.
$tc = "D:\Dependencias\spirula-studio\outputs\tc"
& "$PSScriptRoot\battery_KF.ps1" -Name KF4 -Bin bin_kf -Drop @("--use-ppisp", "--ppisp-from") -Extra @("--use-ppisp", "0")
& "$PSScriptRoot\battery_KF.ps1" -Name KF5 -Bin bin_kf3 -Extra @("--spacetime-constant-color", "1")
& "$PSScriptRoot\battery_KF.ps1" -Name KF6 -Bin bin_kf -Drop @("--darkness-boost", "--opacity-boost", "--overexposure-reg", "--sh-decay")
"chain done $(Get-Date)" | Add-Content "$tc\KF456_chain.log"
