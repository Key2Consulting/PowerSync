# Introduction
PowerSync is a PowerShell 

## Examples
Quickly copies a table from one database to another database, creating the table if it doesn't exist.
```powershell
Copy-PSYTable `
    -SProvider SqlServer -SServer 'SourceServer' -SDatabase "DatabaseA" -STable "dbo.MyTable" `
    -TProvider SqlServer -TServer 'TargetServer' -TDatabase "DatabaseB" -TTable "dbo.MyTableCopy"
```
Quickly imports a CSV file into a database table, and then back out to a tab delimited file.
```powershell
Copy-PSYTable `
    -SProvider TextFile -SConnectionString "InputFile.csv" -SFormat CSV -SHeader `
    -TProvider SqlServer -TServer 'TargetServer' -TDatabase "DatabaseB" -TTable "dbo.MyTable"
Copy-PSYTable `
    -SProvider SqlServer -SServer 'TargetServer' -SDatabase "DatabaseB" -STable "dbo.MyTable" `
    -TProvider TextFile -TConnectionString "OutputFile.txt" -TFormat TSV -THeader
```
Orchestrates a parallel, multi-table copy between different database systems.
```powershell
# Connect to PowerSync repository (stores all our runtime and persisted state).
Connect-PSYJsonRepository 'PowerSyncRepo.json'

# Create source and target connections.
Set-PSYConnection -Name "OracleSource" -Provider Oracle -ConnectionString "Data Source=MyOracleDB;Integrated Security=yes;"
Set-PSYConnection -Name "SqlServerTarget" -Provider SqlServer -ConnectionString "Server=$testDBServer;Integrated Security=true;Database=PowerSyncTestTarget"

# Start a parallel activity which copies the tables.
@('Table1', 'Table2', 'Table3') | Start-PSYForEachActivity -Name 'Multi-Table Copy' -Parallel -Throttle 3 -ScriptBlock {
    Export-PSYOracle -Connection "OracleSource" -Table $Input `
        | Import-PSYSqlServer -Connection "SqlServerTarget" -Table $Input -Create -Index
    }
```
## Installing and Importing
## PSY Command Prefix
## Choosing the Right Repository
## Copy a Table
See [Quick Commands](#quick-commands) for more information.  
# Concepts
## The PowerSync Repository
### Json Repository
### OleDb Repository
## Logging
### Error Log
### Information and Verbose Log
### Debug Log
### Variable Log
## Activities
### Parallelism
## Connections
### Connection Security
## Stored Commands
## Exporters and Importers
## Variables
## Quick Commands
# Advanced Topics
## Type Conversion
## Multiple File Readers
# References
 - ASCII based diagrams created with [asciiflow](http://asciiflow.com).