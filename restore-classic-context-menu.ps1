<#
Restores the classic Windows 10-style context menu on Windows 11.
Designed to work for Intune Win32 deployments that run under SYSTEM.
#>
$ErrorActionPreference = "Stop"

$clsidGuid = "{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"

function Enable-ClassicContextMenuForHive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RegistryRoot
    )

    $clsidPath = Join-Path $RegistryRoot "Software\Classes\CLSID\$clsidGuid"
    $inprocPath = Join-Path $clsidPath "InprocServer32"

    if (-not (Test-Path $inprocPath)) {
        New-Item -Path $inprocPath -Force | Out-Null
    }

    Set-ItemProperty -Path $inprocPath -Name "(Default)" -Value "" -Force
}

$systemSid = "S-1-5-18"
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value

if ($currentIdentity -eq $systemSid) {
    $userSids = Get-ChildItem -Path Registry::HKEY_USERS `
        | Where-Object { $_.PSChildName -match "^S-1-5-21-\\d+-\\d+-\\d+-\\d+$" } `
        | Select-Object -ExpandProperty PSChildName

    foreach ($sid in $userSids) {
        Enable-ClassicContextMenuForHive -RegistryRoot "Registry::HKEY_USERS\\$sid"
    }

    Write-Host "Classic context menu enabled for all loaded user profiles."
} else {
    Enable-ClassicContextMenuForHive -RegistryRoot "HKCU:"
    Write-Host "Classic context menu enabled for current user."
}

$explorerProcesses = Get-Process explorer -ErrorAction SilentlyContinue
if ($explorerProcesses) {
    Write-Host "Restarting Explorer to apply changes..."
    $explorerProcesses | Stop-Process -Force
    Start-Process explorer
} else {
    Write-Host "Explorer not running; changes will apply at next sign-in."
}
