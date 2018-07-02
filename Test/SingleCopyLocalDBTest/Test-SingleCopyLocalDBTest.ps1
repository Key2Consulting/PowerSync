$dbPath = Resolve-Path -Path "$PSScriptRoot\..\Data\PowerSyncTestDB.mdf"

. $PSScriptRoot\..\..\Script\PSync-Object `
    -SrcConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -DstConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dbPath;" `
    -ExtractQuery "SELECT * FROM sys.objects" `
    -DstTableName "dbo.DstSingleCopyLocalDBTest" `
    -Overwrite -AutoIndex