# "C:\Users\jwk6\source\repos\SQLScripts\ADS Data Project\Test\PublishProfiles\Test_1.publish.xml"

# Define the path to the publish profile
$publishProfilePath = "C:\Github\ExportDACPAC\Test.publish.xml"

# Load the XML content
[xml]$xml = Get-Content -Path $publishProfilePath

# Extract server and database names
$serverName = $xml.Project.PropertyGroup.TargetConnectionString -replace '.*Data Source=([^;]+);.*', '$1'
$databaseName = $xml.Project.PropertyGroup.TargetDatabaseName

# Output for verification
Write-Host "Server: $serverName"
Write-Host "Database: $databaseName"

# Avoid the "The certificate chain was issued by an authority that is not trusted." error
# This is a workaround for self-signed certificates or untrusted connections
Set-DbatoolsInsecureConnection -SessionOnly

# Connect to the SQL Server instance
$instance = Connect-DbaInstance -SqlInstance $serverName

# Optional: Confirm connection and list databases
$instance.Databases | Where-Object { $_.Name -eq $databaseName }
