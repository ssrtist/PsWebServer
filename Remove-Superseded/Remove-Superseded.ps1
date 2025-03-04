param(
    [string]$wimFile = "C:\path\to\your\install.wim",
    [string]$mountDir = "C:\mount"
)

# Mount the WIM file 
dism /Mount-Wim /WimFile:"$wimFile" /Index:1 /MountDir:"$mountDir"

# Check if mount succeeded
if (-not (Test-Path "$mountDir\Windows")) {
    Write-Error "Mounting failed. Exiting script."
    exit 1
}

# Parse package information to find superseded packages
$output = dism /Image:"$mountDir" /Get-Packages | Out-String
$packageList = @()
$currentIdentity = $null

$output -split "`r`n" | ForEach-Object {
    if ($_ -match 'Package Identity : (.*)') {
        $currentIdentity = $matches[1].Trim()
    } elseif ($_ -match 'State : (.*)') {
        $state = $matches[1].Trim()
        if ($state -eq 'Superseded') {
            $packageList += $currentIdentity
        }
    }
}

# Remove superseded packages
foreach ($package in $packageList) {
    dism /Image:"$mountDir" /Remove-Package /PackageName:"$package"
}

# Commit changes and unmount
dism /Unmount-Image /MountDir:"$mountDir" /Commit
