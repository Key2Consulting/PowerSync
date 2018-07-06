$dbPath = Resolve-Path -Path "$PSScriptRoot\..\Data\PowerSyncTestDB.mdf"
Set-Location $PSScriptRoot

# Test manifest extraction
. $PSScriptRoot\..\..\Script\PowerSync-Manifest `
    -SrcConnectionString "Server=.\SQL2016;Integrated Security=true;database=AdventureWorksDW2014;" `
    -DstConnectionString "Server=.\SQL2016;Integrated Security=true;database=NewDB;" `
    -ManifestPath "$(Get-Location)\Manifest.csv" `
    -PrepareScriptPath "$(Get-Location)\Prepare.sql" `
    -ExtractScriptPath "$(Get-Location)\Extract.sql" `
    -TransformScriptPath "$(Get-Location)\Transform.sql" `
    -PublishScriptPath "$(Get-Location)\Publish.sql" `
    -Overwrite -AutoIndex

Write-Output "ManifestLocalDBTest.1 Passed"
