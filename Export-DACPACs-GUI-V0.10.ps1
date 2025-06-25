Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "DACPAC Exporter"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

# SQL Server label and textbox
$labelServer = New-Object System.Windows.Forms.Label
$labelServer.Text = "SQL Server Instance:"
$labelServer.Location = New-Object System.Drawing.Point(10,20)
$labelServer.Size = New-Object System.Drawing.Size(150,20)
$form.Controls.Add($labelServer)

$textboxServer = New-Object System.Windows.Forms.TextBox
$textboxServer.Location = New-Object System.Drawing.Point(160,20)
$textboxServer.Size = New-Object System.Drawing.Size(400,20)
$form.Controls.Add($textboxServer)

# Output folder label and textbox
$labelFolder = New-Object System.Windows.Forms.Label
$labelFolder.Text = "Output Folder:"
$labelFolder.Location = New-Object System.Drawing.Point(10,60)
$labelFolder.Size = New-Object System.Drawing.Size(150,20)
$form.Controls.Add($labelFolder)

$textboxFolder = New-Object System.Windows.Forms.TextBox
$textboxFolder.Location = New-Object System.Drawing.Point(160,60)
$textboxFolder.Size = New-Object System.Drawing.Size(300,20)
$form.Controls.Add($textboxFolder)

$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Browse"
$buttonBrowse.Location = New-Object System.Drawing.Point(470,60)
$buttonBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $textboxFolder.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($buttonBrowse)

# Log output
$textboxLog = New-Object System.Windows.Forms.TextBox
$textboxLog.Multiline = $true
$textboxLog.ScrollBars = "Vertical"
$textboxLog.Location = New-Object System.Drawing.Point(10,100)
$textboxLog.Size = New-Object System.Drawing.Size(550,200)
$form.Controls.Add($textboxLog)

# Export button
$buttonExport = New-Object System.Windows.Forms.Button
$buttonExport.Text = "Export DACPACs"
$buttonExport.Location = New-Object System.Drawing.Point(230,320)
$buttonExport.Add_Click({
    $server = $textboxServer.Text
    $folder = $textboxFolder.Text
    $logFile = Join-Path $folder "ExportDACPACsGUILog__$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    if (-not (Get-Module -ListAvailable -Name dbatools)) {
        Install-Module -Name dbatools -Scope CurrentUser -Force
    }
    Import-Module dbatools

    if (-not (Test-Path -Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }

    "Export started at $(Get-Date)" | Out-File -FilePath $logFile

    $databases = Get-DbaDatabase -SqlInstance $server | Where-Object { -not $_.IsSystemObject }

    foreach ($db in $databases) {
        try {
            $dacpacPath = Join-Path -Path $folder -ChildPath "" #"$($db.Name).dacpac"
            Export-DbaDacPackage -SqlInstance $server -Database $db.Name -Path $dacpacPath -ErrorAction Stop
            $msg = "[$(Get-Date)] Exported $($db.Name) to $dacpacPath"
            $msg | Out-File -FilePath $logFile -Append
            $textboxLog.AppendText("$msg`r`n")
        } catch {
            $err = "[$(Get-Date)] Failed to export $($db.Name): $_"
            $err | Out-File -FilePath $logFile -Append
            $textboxLog.AppendText("$err`r`n")
        }
    }

    $textboxLog.AppendText("Export completed at $(Get-Date)`r`n")
})
$form.Controls.Add($buttonExport)

# Show form
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
