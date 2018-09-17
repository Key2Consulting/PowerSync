######################################################
# Test Configuration
######################################################
$rootPath = Resolve-Path -Path "$PSScriptRoot\..\"
$jsonRepo = "$($rootPath)TempRepository.json"
$testDBServer = "(LocalDb)\MSSQLLocalDB"
$testDBPath = "$($rootPath)PowerSyncTestDB.MDF"

######################################################
# Initialize Tests
######################################################
$ErrorActionPreference = "Continue"     # we want to run through all tests

# Reset the source and target databases
Write-Host "Resetting test databases..."
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Remove Database.sql" -ServerInstance $testDBServer -Variable "DatabaseName=PowerSyncTestTarget"
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Remove Database.sql" -ServerInstance $testDBServer -Variable "DatabaseName=PowerSyncTestSource"
#Remove-Item -Path "$testDBPath" -Force -ErrorAction SilentlyContinue
#Remove-Item -Path "$testDBPath" -Force -ErrorAction SilentlyContinue
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Create Source Database.sql" -ServerInstance $testDBServer
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Create Target Database.sql" -ServerInstance $testDBServer

######################################################
# Run Tests
######################################################
# Import dependent modules
Import-Module "$rootPath\PowerSync"

# Initialize PowerSync repository
Write-Host "Resetting repository..."
Remove-PSYJsonRepository $jsonRepo
New-PSYJsonRepository $jsonRepo -ErrorAction SilentlyContinue
Connect-PSYJsonRepository $jsonRepo

Set-PSYConnection -Name "TestSqlServerTarget" -Provider SqlServer -ConnectionString "Server=$testDBServer;Integrated Security=true;Database=PowerSyncTestTarget"
Set-PSYConnection -Name "TestDbOleDb" -Provider OleDb -ConnectionString "Provider=SQLNCLI11;Server=$testDBServer;Database=PowerSyncTestTarget;Trusted_Connection=yes;"
Set-PSYConnection -Name "SampleFiles" -Provider TextFile -ConnectionString "$($rootPath)Test\SampleFiles"
Set-PSYConnection -Name "TestSqlServerSource" -Provider SqlServer -ConnectionString "Server=$testDBServer;Integrated Security=true;Database=PowerSyncTestSource"
Set-PSYVariable -Name 'PSYCmdPath' -Value $PSScriptRoot     # needed so Stored Command finds our custom scripts

# Run required tests
Write-Host "RUNNING Test Scripts"
.\Test\TestQuickCommand.ps1
.\Test\TestGeneral.ps1
.\Test\TestVariables.ps1
.\Test\TestConcurrency.ps1
.\Test\TestCSVToSQL.ps1
.\Test\TestSQLToSQL.ps1
Write-Host "FINISHED Runing Test Scripts"