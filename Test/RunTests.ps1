######################################################
# Test Configuration
######################################################
$rootPath = Resolve-Path -Path "$PSScriptRoot\..\"
$jsonRepo = "$($rootPath)Repository.json"
$testDBServer = "(LocalDb)\MSSQLLocalDB"
$testDBPath = "$($rootPath)PowerSyncTestDB.MDF"

######################################################
# Initialize Tests
######################################################
$ErrorActionPreference = "Stop"

# Reset the source and target databases
Write-Host "Resetting test databases..."
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Remove Database.sql" -ServerInstance $testDBServer -Variable "DatabaseName=PowerSyncTestDb"
Remove-Item -Path "$testDBPath" -Force -ErrorAction SilentlyContinue
Invoke-Sqlcmd -Query "CREATE DATABASE [PowerSyncTestDb]" -ServerInstance $testDBServer

######################################################
# Run Tests
######################################################
# Import dependent modules
Import-Module "$rootPath\PowerSync"

# Initialize PowerSync repository
Write-Host "Resetting repository..."
Remove-PSYJsonRepository $jsonRepo
New-PSYJsonRepository $jsonRepo
Connect-PSYJsonRepository $jsonRepo

Set-PSYConnection -Name "TestDbSqlServer" -Provider SqlServer -ConnectionString "Server=$testDBServer;Integrated Security=true;Database=PowerSyncTestDb"
Set-PSYConnection -Name "TestDbOleDb" -Provider OleDb -ConnectionString "Provider=SQLNCLI11;Server=$testDBServer;Database=$testDBPath;Trusted_Connection=yes;"
Set-PSYConnection -Name "SampleFiles" -Provider TextFile -ConnectionString "$($rootPath)Test\SampleFiles"

# Run required tests
# TODO: MIGRATE THIS TO PESTER?
#.\Test\TestGeneral\TestGeneral.ps1
#.\Test\TestVariables\TestVariables.ps1
#.\Test\TestConcurrency\TestConcurrency.ps1
.\Test\TestCSVToSQL\TestCSVToSQL.ps1

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