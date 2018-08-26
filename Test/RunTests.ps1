######################################################
# Test Configuration
######################################################
$rootPath = Resolve-Path -Path "$PSScriptRoot\..\"
$jsonRepo = "$rootPath\Repository.json"
$sourceSqlServerInstance = "(LocalDb)\MSSQLLocalDB"
$sourceTestDBPath = "$rootPath\PowerSyncSourceDB.MDF"
$targetSqlServerInstance = "(LocalDb)\MSSQLLocalDB"
$targetTestDBPath = "$rootPath\PowerSyncTargetDB.MDF"

######################################################
# Initialize Tests
######################################################
$ErrorActionPreference = "Stop"

# Reset the source and target databases
#Invoke-Sqlcmd -InputFile "$rootPath\Setup\Create Test Database.sql" -ServerInstance $sqlServerInstance -Variable "TestDB=$testDBPath"
#Remove-Item -Path "$testDBPath" -Force -ErrorAction SilentlyContinue
#Invoke-Sqlcmd -InputFile "$rootPath\Setup\Create Test Objects.sql" -ServerInstance $sqlServerInstance -Variable "TestDB=$testDBPath"

######################################################
# Run Tests
######################################################
# Import dependent modules
Import-Module "$rootPath\PowerSync"

# Clean up prior JSON repository files
Remove-PSYJsonRepository $jsonRepo
New-PSYJsonRepository $jsonRepo
Connect-PSYJsonRepository $jsonRepo

Start-PSYActivity -Verbose -Debug -Name 'Test Concurrency' -ScriptBlock {
    Start-PSYForEachActivity -Name 'Test ForEach Incorrect Concurrency Execution' -InputObject (1..5) -Parallel -ScriptBlock {
        Write-PSYVerboseLog "foo actual $Input"
        "hello"
        "world"
    }
}

#.\Test\TestConcurrency\TestConcurrency.ps1
#.\Test\TestStateTypes\TestStateTypes.ps1

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