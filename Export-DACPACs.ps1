
# --- Configuration ---
$serverName = "localhost"  # Change to your SQL Server instance
$outputFolder = "C:\Temp\Export-DACPACs"
$logFile = Join-Path -Path $outputFolder -ChildPath "ExportLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# --- Ensure dbatools is installed ---
if (-not (Get-Module -ListAvailable -Name dbatools)) {
    Write-Host "Installing dbatools..."
    Install-Module -Name dbatools -Scope CurrentUser -Force
}
Import-Module dbatools

# --- Ensure output folder exists ---
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# --- Initialize log ---
"Export started at $(Get-Date)" | Out-File -FilePath $logFile

# --- Export DACPACs ---
$databases = Get-DbaDatabase -SqlInstance $serverName | Where-Object { -not $_.IsSystemObject }

foreach ($db in $databases) {
    try {
        $dacpacPath = Join-Path -Path $outputFolder -ChildPath "$($db.Name).dacpac"
        Export-DbaDacPackage -SqlInstance $serverName -Database $db.Name -Path $dacpacPath -ErrorAction Stop
        "[$(Get-Date)] Exported $($db.Name) to $dacpacPath" | Out-File -FilePath $logFile -Append
    } catch {
        "[$(Get-Date)] Failed to export $($db.Name): $_" | Out-File -FilePath $logFile -Append
    }
}

"Export completed at $(Get-Date)" | Out-File -FilePath $logFile -Append
Write-Host "Export complete. Log saved to $logFile"
