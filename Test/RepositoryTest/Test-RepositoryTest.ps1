# Set Connection to Local DB
$dbPath = Resolve-Path -Path "$PSScriptRoot\..\Data\PowerSyncTestDB.mdf"
Set-Location $PSScriptRoot

# Test manifest extraction
. $PSScriptRoot\..\..\Script\PowerSync-Repository `
    -SrcConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -DstConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -LogConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -ManifestConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -ManifestTableName "dbo.Manifest" `
    -ManifestScriptLibrary "$(Get-Location)\Scripts" `
    -PrepareScriptPath "$(Get-Location)\Prepare.sql" `
    -ExtractScriptPath "$(Get-Location)\Extract.sql" `
    -TransformScriptPath "$(Get-Location)\Transform.sql" `
    -PublishScriptPath "$(Get-Location)\Publish.sql" `
    -Overwrite -AutoIndex

Write-Output "RepositoryLocalDBTest.1 Passed"

