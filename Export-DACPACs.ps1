
# Configuration
$serverName = "localhost"  # Change to your SQL Server instance
$outputFolder = "C:\Temp\Export-DACPACs"
$appendDateToLog = $false # Set to $true if you want to append date to log file name
$debug = $true

# If $appendDateToLog is true, append date to log file name
if ($appendDateToLog) {
        $logFile = Join-Path -Path $outputFolder -ChildPath "ExportDACPACsLog_$(Get-Date -Format 'yyyyMMdd')"
}
else {
    $logFile = Join-Path -Path $outputFolder -ChildPath "ExportDACPACsLog.txt"
}

# Ensure dbatools is installed
if (-not (Get-Module -ListAvailable -Name dbatools)) {
    Write-Host "Installing dbatools..."
    Install-Module -Name dbatools -Scope CurrentUser -Force
}
Import-Module dbatools

# Ensure output folder exists
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Initialize log file
"Export started at $(Get-Date)" | Out-File -FilePath $logFile

# Avoid the "The certificate chain was issued by an authority that is not trusted." error
# This is a workaround for self-signed certificates or untrusted connections
Set-DbatoolsInsecureConnection -SessionOnly

$sqlInstance = Connect-DbaInstance -SqlInstance $serverName #-TrustServerCertificate
if (-not $sqlInstance) {
        "[$(Get-Date)] SQL Server instance $serverName not found." | Out-File -FilePath $logFile -Append
            Write-Host "SQL Server instance $serverName not found. Exiting script."
            exit 1
}

# Export DACPACs
$databases = Get-DbaDatabase -SqlInstance $sqlInstance | Where-Object { -not $_.IsSystemObject }

foreach ($db in $databases) {
    try {
        $dacpacPath = Join-Path -Path $outputFolder -ChildPath "" #"$($db.Name).dacpac"
        Export-DbaDacPackage -SqlInstance $serverName -Database $db.Name -Path $dacpacPath -ErrorAction Ignore
        "[$(Get-Date)] Exported $($db.Name) to $dacpacPath" | Out-File -FilePath $logFile -Append
    } catch {
        "[$(Get-Date)] Failed to export $($db.Name): $_" | Out-File -FilePath $logFile -Append
    }
    if ($debug) {
        Write-Host "Debug mode is ON. Exiting foreach loop after first iteration."
    }
}

"Export completed at $(Get-Date)" | Out-File -FilePath $logFile -Append
Write-Host "Export complete. Log saved to $logFile"
