$dbPath = Resolve-Path -Path "$PSScriptRoot\..\Data\PowerSyncTestDB.mdf"

# Test single extraction with Overwrite and AutoIndex
. $PSScriptRoot\..\..\Script\PowerSync `
    -SrcConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -DstConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -ExtractQuery "SELECT * FROM sys.objects" `
    -LoadTableName "dbo.DstSingleCopyLocalDBTest" `
    -Overwrite -AutoIndex

Write-Output "SingleCopyLocalDBTest.1 Passed"

# Test single extraction without Overwrite (should fail)    
try {
    . $PSScriptRoot\..\..\Script\PowerSync `
        -SrcConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
        -DstConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
        -ExtractQuery "SELECT * FROM sys.objects" `
        -LoadTableName "dbo.DstSingleCopyLocalDBTest" `
        -AutoIndex
}
catch {
    Write-Output "SingleCopyLocalDBTest.2 Passed"
}