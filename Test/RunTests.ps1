######################################################
# Test Configuration
######################################################
$rootPath = Resolve-Path -Path "$PSScriptRoot\..\"
$jsonRepo = "$PSScriptRoot\TempFiles\TempRepository.json"
$testDBServer = "(LocalDb)\MSSQLLocalDB"
$testDBPath = "$($rootPath)PowerSyncTestDB.MDF"

######################################################
# Initialize Tests
######################################################
$ErrorActionPreference = "Continue"     # we want to run through all tests

# Import dependent modules
Import-Module "$rootPath\PowerSync"

# Reset the source and target databases
Write-PSYHost "Resetting test databases..."
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Remove Database.sql" -ServerInstance $testDBServer -Variable "DatabaseName=PowerSyncTestTarget"
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Remove Database.sql" -ServerInstance $testDBServer -Variable "DatabaseName=PowerSyncTestSource"
#Remove-Item -Path "$testDBPath" -Force -ErrorAction SilentlyContinue
#Remove-Item -Path "$testDBPath" -Force -ErrorAction SilentlyContinue
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Create Source Database.sql" -ServerInstance $testDBServer
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Create Target Database.sql" -ServerInstance $testDBServer

######################################################
# Run Tests
######################################################

# Initialize PowerSync repository
Write-PSYHost "Resetting repository..."
Connect-PSYJsonRepository -Path $jsonRepo -Recreate

# Create default connections
Set-PSYConnection -Name "TestSqlServerTarget" -Provider SqlServer -ConnectionString "Server=$testDBServer;Integrated Security=true;Database=PowerSyncTestTarget"
Set-PSYConnection -Name "TestDbOleDb" -Provider OleDb -ConnectionString "Provider=SQLNCLI11;Server=$testDBServer;Database=PowerSyncTestTarget;Trusted_Connection=yes;"
Set-PSYConnection -Name "SampleFiles" -Provider TextFile -ConnectionString "$($rootPath)Test\SampleFiles"
Set-PSYConnection -Name "TestSqlServerSource" -Provider SqlServer -ConnectionString "Server=$testDBServer;Integrated Security=true;Database=PowerSyncTestSource"

# Set environment variables
Set-PSYVariable -Name 'PSYCmdPath' -Value $PSScriptRoot                         # needed so Stored Command finds our custom scripts

# Run required tests
Write-PSYHost "RUNNING Test Scripts"
.\Test\TestQuickCommand.ps1
.\Test\TestGeneral.ps1
.\Test\TestVariables.ps1
.\Test\TestConcurrency.ps1
.\Test\TestCSVToSQL.ps1
.\Test\TestSQLToSQL.ps1
#.\Test\TestAzure.ps1
Write-PSYHost "FINISHED Runing Test Scripts"