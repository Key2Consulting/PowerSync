######################################################
# Test Configuration
######################################################
$rootPath = Resolve-Path -Path "$PSScriptRoot\..\"
$testSqlServer = "(LocalDb)\MSSQLLocalDB"
# $jsonRepoPath = "$PSScriptRoot\TempFiles\TempRepository.json"
$jsonRepoPath = "$PSScriptRoot\TempFiles\"
$oleDbRepoCS = "Provider=SQLNCLI11;Server=$testSqlServer;Database=PSYRepository;Trusted_Connection=yes;"

######################################################
# Initialize Tests
######################################################
$ErrorActionPreference = "Continue"     # we want to run through all tests
New-Item -Path "$PSScriptRoot\TempFiles\" -ErrorAction SilentlyContinue

# Import dependent modules
Import-Module "$rootPath\PowerSync"

# Reset the source and target databases
Write-PSYHost "Resetting test databases..."
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Remove Database.sql" -ServerInstance $testSqlServer -Variable "DatabaseName=PSYTestTarget"
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Remove Database.sql" -ServerInstance $testSqlServer -Variable "DatabaseName=PSYTestSource"
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Remove Database.sql" -ServerInstance $testSqlServer -Variable "DatabaseName=PSYRepository" -ErrorAction SilentlyContinue
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Create Source Database.sql" -ServerInstance $testSqlServer
Invoke-Sqlcmd -InputFile "$($rootPath)Test\Setup\Create Target Database.sql" -ServerInstance $testSqlServer
Invoke-Sqlcmd -Query "CREATE DATABASE [PSYRepository]" -ServerInstance $testSqlServer
Invoke-Sqlcmd -InputFile "$($rootPath)Kit\SqlServerRepository\CreateDatabase.sql" -ServerInstance $testSqlServer -Database "PSYRepository"

######################################################
# Run Tests
######################################################
function Invoke-Tests {
    [CmdletBinding()]
    param
    (
        [switch] $JsonDbRepository,
        [switch] $OleDbRepository
    )
    # Initialize PowerSync repository
    Write-PSYHost "Resetting repository..."
    if ($JsonDbRepository) {
        Connect-PSYJsonRepository -RootPath $jsonRepoPath -ClearLogs -ClearActivities -ClearConnections -ClearVariables
    }
    elseif ($OleDbRepository) {
        Connect-PSYOleDbRepository -ConnectionString $oleDbRepoCS -Schema '[PSY]'
        #$PSYCmdPath = "$rootPath" + "PowerSync\Asset\StoredQuery\Repository"
    }
    
    # Create default connections
    Set-PSYConnection -Name "TestSqlServerTarget" -Provider SqlServer -ConnectionString "Server=$testSqlServer;Integrated Security=true;Database=PSYTestTarget"
    Set-PSYConnection -Name "TestDbOleDb" -Provider OleDb -ConnectionString "Provider=SQLNCLI11;Server=$testSqlServer;Database=PSYTestTarget;Trusted_Connection=yes;"
    Set-PSYConnection -Name "SampleFiles" -Provider TextFile -ConnectionString "$($rootPath)Test\SampleFiles"
    Set-PSYConnection -Name "TestSqlServerSource" -Provider SqlServer -ConnectionString "Server=$testSqlServer;Integrated Security=true;Database=PSYTestSource"

    # Set environment variables
    Set-PSYVariable -Name 'PSYCmdPath' -Value $PSScriptRoot                         # needed so Stored Command finds our custom scripts

    # Run required tests
    Write-PSYHost "RUNNING Test Scripts"

    #.\Test\TestQuickCommand.ps1
    #.\Test\TestGeneral.ps1
    #.\Test\TestVariables.ps1
    .\Test\TestConcurrency.ps1
    #.\Test\TestCSVToSQL.ps1
    #.\Test\TestSQLToSQL.ps1
    #.\Test\TestAzure.ps1
    Write-PSYHost "FINISHED Runing Test Scripts"
}

# Invoke-Tests -JsonDbRepository
Invoke-Tests -OleDbRepository