$dbPath = Resolve-Path -Path "$PSScriptRoot\..\Data\PowerSyncTestDB.mdf"
Set-Location $PSScriptRoot

# Test manifest extraction
. $PSScriptRoot\..\..\Script\PowerSync-Manifest `
    -SrcConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -DstConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -ManifestPath "$(Get-Location)\Manifest.csv" `
    -PrepareScriptPath "$(Get-Location)\Prepare.sql" `
    -ExtractScriptPath "$(Get-Location)\Extract.sql" `
    -TransformScriptPath "$(Get-Location)\Transform.sql" `
    -PublishScriptPath "$(Get-Location)\Publish.sql" `
    -Overwrite -AutoIndex

Write-Output "ManifestLocalDBTest.1 Passed"
