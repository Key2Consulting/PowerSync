######################################################
# Initialize Tests
######################################################
$ErrorActionPreference = "Stop"
$dataFolder = Resolve-Path -Path "$PSScriptRoot\Data"
$testFolder = Resolve-Path -Path "$PSScriptRoot"

# TODO: RESET DATABASE

######################################################
# Run Tests
######################################################

# Test manifest file extraction from CSV to SQL

. $PSScriptRoot\..\Script\PowerSync `
    -Log @{
        ConnectionString = "PSProvider=TextLogProvider;FilePath=$testFolder\Log.csv;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "PSProvider=TextDataProvider;FilePath=$dataFolder\Sample2.csv;Header=True;Format=CSV;Quoted=True";
        PrepareScript = "$testFolder\Package\PrepareSource.sql";
        ExtractScript = "$testFolder\Package\Extract.sql";
        Timeout = 3600;
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dataFolder\PowerSyncTestDB.mdf;";
        PrepareScript = "$testFolder\Package\PrepareTarget.sql";
        TransformScript = "$testFolder\Package\Transform.sql";
        TableName = "dbo.ManifestLocalDBTest1"
        AutoIndex = $true;
        AutoCreate = $true;
        Overwrite = $true;
        BatchSize = 10000;
    }

# Test manifest file extraction from SQL to SQL
<#
. $PSScriptRoot\..\Script\PowerSync `
    -Manifest @{
        ConnectionString = "Provider=PSText;Data Source=$testFolder\Package\Manifest.csv;Header=True;Format=CSV"
    } `
    -Log @{
        ConnectionString = "Provider=PSText;Data Source=$testFolder\Log.csv;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dataFolder\PowerSyncTestDB.mdf;";
        PrepareScript = "$testFolder\Package\PrepareSource.sql";
        ExtractScript = "$testFolder\Package\Extract.sql";
        Timeout = 3600;
    } `
    -Target @{
        ConnectionString = "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dataFolder\PowerSyncTestDB.mdf;";
        PrepareScript = "$testFolder\Package\PrepareTarget.sql";
        TransformScript = "$testFolder\Package\Transform.sql";
        AutoIndex = $true;
        AutoCreate = $true;
        Overwrite = $true;
        BatchSize = 10000;
    }
#>
<#
FUTURE TESTS: 
 - AutoCreate false
 - Test no overwrite
 - File to file, change format
#>

<#
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
        Timeout = 3600;
    } `
    -Target @{
        #ConnectionString = "Provider=PSText;Data Source=$dataFolder\SampleOut.csv;Header=True;Format=TAB";
        ConnectionString = "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=$dataFolder\PowerSyncTestDB.mdf;";
        PrepareScript = "$testFolder\PrepareTarget.sql";
        TransformScript = "$testFolder\Transform.sql";
        AutoIndex = $true;
        AutoCreate = $true;
        Overwrite = $true;
        BatchSize = 10000;
    }
#>
#. "$PSScriptRoot\SingleCopyLocalDBTest\Test-SingleCopyLocalDBTest.ps1"
