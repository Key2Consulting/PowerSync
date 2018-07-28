$ErrorActionPreference = "Stop"
$dataFolder = Resolve-Path -Path "$PSScriptRoot\Data"
$testFolder = Resolve-Path -Path "$PSScriptRoot\ManifestLocalDBTest"

. $PSScriptRoot\..\Script\PowerSync `
    -Manifest @{
        ConnectionString = "Provider=PSText;Data Source=$testFolder\Manifest.csv;Header=True;Format=CSV"
    } `
    -Log @{
        ConnectionString = "Provider=PSText;Data Source=$dataFolder\Log.csv;Header=True;Format=CSV"
    } `
    -Source @{
        # ConnectionString = "Provider=PSText;Data Source=$dataFolder\SampleIn.csv;Header=True;Format=CSV";
        ConnectionString = "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dataFolder\PowerSyncTestDB.mdf;";
        PrepareScript = "$testFolder\PrepareSource.sql";
        ExtractScript = "$testFolder\Extract.sql";
    } `
    -Target @{
        #ConnectionString = "Provider=PSText;Data Source=$dataFolder\SampleOut.csv;Header=True;Format=TAB";
        ConnectionString = "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dataFolder\PowerSyncTestDB.mdf;";
        PrepareScript = "$testFolder\PrepareTarget.sql";
        TransformScript = "$testFolder\Transform.sql";
        SchemaName="dbo";
        TableName = "MyTable";
        AutoIndex = $true;
        Overwrite = $true;
    }

#. "$PSScriptRoot\SingleCopyLocalDBTest\Test-SingleCopyLocalDBTest.ps1"
#. "$PSScriptRoot\ManifestLocalDBTest\Test-ManifestLocalDBTest.ps1"