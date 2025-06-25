# This module provides functions to read a Publish Profile from a database project, and export all DACPACs from the SQL Server instance.
# Requires dbatools module
function Connect-FromPublishProfile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PublishProfilePath
    )

    if (-not (Test-Path $PublishProfilePath)) {
        throw "The specified publish profile path does not exist: $PublishProfilePath"
    }

    try {
        [xml]$xml = Get-Content -Path $PublishProfilePath

        $connectionString = $xml.Project.PropertyGroup.TargetConnectionString
        $serverName = if ($connectionString) {
            $connectionString -replace '.*Data Source=([^;]+);.*', '$1'
        } else {
            $xml.Project.PropertyGroup.TargetServerName
        }

        $databaseName = $xml.Project.PropertyGroup.TargetDatabaseName

        if (-not $serverName -or -not $databaseName) {
            throw "Could not extract server or database name from the publish profile."
        }

        Write-Verbose "Connecting to SQL Server instance: $serverName"
        $instance = Connect-DbaInstance -SqlInstance $serverName

        Write-Verbose "Connected. Target database: $databaseName"
        return $instance
    }
    catch {
        throw "Failed to connect using publish profile: $_"
    }
}


#TODO: Update the Export-AllDacpacs function to use the Connect-FromPublishProfile function
# Export DACPACs from all user databases on a SQL Server instance
#TODO Update the path handling to match Export-DACPACs.ps1
# Requires dbatools module
function Export-AllDacpacs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SqlInstance,

        [Parameter(Mandatory = $true)]
        [string]$OutputFolder
    )
    # Usage: Export-AllDacpacs -SqlInstance "localhost" -OutputFolder "C:\Temp\Export-DACPACs"

    # Ensure dbatools is installed
    if (-not (Get-Module -ListAvailable -Name dbatools)) {
        Write-Host "Installing dbatools..."
        Install-Module -Name dbatools -Scope CurrentUser -Force
    }
    Import-Module dbatools

    # Ensure output folder exists
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder | Out-Null
    }

    # Create log file
    $logFile = Join-Path -Path $OutputFolder -ChildPath "ExportLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    "Export started at $(Get-Date)" | Out-File -FilePath $logFile

    # Get user databases and export DACPACs
    $databases = Get-DbaDatabase -SqlInstance $SqlInstance | Where-Object { -not $_.IsSystemObject }

    foreach ($db in $databases) {
        try {
            $dacpacPath = Join-Path -Path $OutputFolder -ChildPath "$($db.Name).dacpac"
            Export-DbaDacPackage -SqlInstance $SqlInstance -Database $db.Name -Path $dacpacPath -ErrorAction Stop
            "[$(Get-Date)] Exported $($db.Name) to $dacpacPath" | Out-File -FilePath $logFile -Append
        } catch {
            "[$(Get-Date)] Failed to export $($db.Name): $_" | Out-File -FilePath $logFile -Append
        }
    }

    "Export completed at $(Get-Date)" | Out-File -FilePath $logFile -Append
    Write-Host "Export complete. Log saved to $logFile"
}
