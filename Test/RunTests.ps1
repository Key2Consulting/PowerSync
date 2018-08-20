Import-Module "$(Resolve-Path -Path ".\PowerSync")"

Start-PSYMainActivity -ConnectScriptBlock {
    #Connect-PSYOleDbRepository -ConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;Database=SqlServerKit"
    Connect-PSYJsonRepository
} -ScriptBlock {

<#     Use-PSYState 'MyControlState' 'defaultvalue' -Overwrite
    $Ctx.State.MyControlState = "Foo"
    Start-PSYActivity -ScriptBlock {
        $Ctx.State.MyControlState = "hello"
        Write-Host $Ctx.State.MyControlState
    }
    Write-Host $Ctx.State.MyControlState #>

    $s = Use-PSYState 'MyControlState' @{Step = 'zero'} -Overwrite
    $s.Step = "one"
    $abc = 123
    Start-PSYActivity -ScriptBlock {
        Write-Host $Ctx.State.MyControlState.Step
        $Ctx.State.MyControlState.Step = "two"
        Start-PSYActivity -ScriptBlock {
            Write-Host $Ctx.State.MyControlState.Step
            $Ctx.State.MyControlState.Step = "three"
        }
    }
    Write-Host $Ctx.State.MyControlState.Step
}


<#
######################################################
# Test Configuration
######################################################
$rootPath = Resolve-Path -Path "$PSScriptRoot"
$sqlServerInstance = "(LocalDb)\MSSQLLocalDB"
$testDBPath = "$rootPath\PowerSyncTestDB.MDF"
$logFilePath = "$rootPath\Log.csv"

######################################################
# Initialize Tests
######################################################
$ErrorActionPreference = "Stop"
Invoke-Sqlcmd -InputFile "$rootPath\Setup\Create Test Database.sql" -ServerInstance $sqlServerInstance -Variable "TestDB=$testDBPath"
Remove-Item -Path "$testDBPath" -Force -ErrorAction SilentlyContinue
Invoke-Sqlcmd -InputFile "$rootPath\Setup\Create Test Objects.sql" -ServerInstance $sqlServerInstance -Variable "TestDB=$testDBPath"

######################################################
# Run Tests
######################################################
Import-Module "$(Resolve-Path -Path "..\PowerSync\Script\PowerSync.psm1")"

PowerSync `
    -Source @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;Type System Version=SQL Server 2012";
        ExtractScript = "SELECT * FROM dbo.Geo";
        Timeout = 3600;
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;Type System Version=SQL Server 2012";
        Table = "GeoTarget"
        Schema  = "dbo"
        AutoIndex = $true;
        AutoCreate = $true;
    }

#.\Test\TestCSVToSQL\TestCSVToSQL.ps1
#.\Test\TestSQLToSQL\TestSQLToSQL.ps1
#.\Test\TestRepository\TestRepository.ps1
#.\Test\TestShortcutCLI\TestShortcutCLI.ps1

<#
FUTURE TESTS: 
 - AutoCreate false
 - Test no overwrite
 - File to file, change format
 - MultiSource Manifest Repository
    - Consider creating a PowerSync Data Integration Framework using Azure SQL as a manifest repository (separate project?)
#>
#>