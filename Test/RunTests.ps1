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
.\Test\TestCSVToSQL\TestCSVToSQL.ps1
.\Test\TestSQLToSQL\TestSQLToSQL.ps1
.\Test\TestRepository\TestRepository.ps1
.\Test\TestShortcutCLI\TestShortcutCLI.ps1

<#
FUTURE TESTS: 
 - AutoCreate false
 - Test no overwrite
 - File to file, change format
 - MultiSource Manifest Repository
    - Consider creating a PowerSync Data Integration Framework using Azure SQL as a manifest repository (separate project?)
#>