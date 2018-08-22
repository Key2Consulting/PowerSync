######################################################
# Test Configuration
######################################################
$rootPath = Resolve-Path -Path "$PSScriptRoot\..\"
$sourceSqlServerInstance = "(LocalDb)\MSSQLLocalDB"
$sourceTestDBPath = "$rootPath\PowerSyncSourceDB.MDF"
$targetSqlServerInstance = "(LocalDb)\MSSQLLocalDB"
$targetTestDBPath = "$rootPath\PowerSyncTargetDB.MDF"

######################################################
# Initialize Tests
######################################################
$ErrorActionPreference = "Stop"
# Clean up prior JSON repository files
Clear-Content "$rootPath\Log.json" -ErrorAction SilentlyContinue
Clear-Content "$rootPath\Configuration.json" -ErrorAction SilentlyContinue

# Reset the source and target databases
#Invoke-Sqlcmd -InputFile "$rootPath\Setup\Create Test Database.sql" -ServerInstance $sqlServerInstance -Variable "TestDB=$testDBPath"
#Remove-Item -Path "$testDBPath" -Force -ErrorAction SilentlyContinue
#Invoke-Sqlcmd -InputFile "$rootPath\Setup\Create Test Objects.sql" -ServerInstance $sqlServerInstance -Variable "TestDB=$testDBPath"

######################################################
# Run Tests
######################################################
# Import dependent modules
Import-Module "$rootPath\PowerSync"

.\Test\TestConcurrency\TestConcurrency.ps1

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