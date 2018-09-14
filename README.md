# Introduction
PowerSync is a PowerShell based data integration system. It can be used as a complex and customizable data integration framework, or as a command-line option for administering data systems. It's based on similar design concepts found in commercial data integration products, like connections, variables, activities, and export/import operations. PowerSync adheres to the ELT model where transformations are best performed by the database system oppose to the integration framework. 

As its rooted in PowerShell, PowerSync natively supports the plethora of PowerShell commands/cmdlets found in the community and included by the PowerShell platform. PowerShell is known for it's convenient and simplistic API for managing vast numbers of resources. It's PowerSync's goal to provide that same simplistic API for managing data resources.

PowerSync features:
 - Portable by nature, so it can run on a desktop, server, Linux or Windows without much overhead.
 - Can scale within any compatible hosting environment (e.g. Azure WebJobs).
 - High performance Exporters and Importers compatible with a wide range of data systems.
 - Sequential or parallel execution models.
 - Activity model to organize work and isolate workloads.
 - Comprehensive logging system.
 - Supports process resiliency (i.e. resume/retry).
 - State management system.
 - Highly customizable.

## Design Goals
 * Existing tools make it difficult to reuse code, where many times the majority of the work is repetitive. PowerSync should allow users to build upon prior work by creating compositions of new capablities using existing components, and conforming to the [DRY principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself).
 * Procedural programming model with source control versioning that works (ever tried to compare an SSIS package?).
 * Support loose or dynamic typing of source and target schemas.
 * Reduce the overhead and complexity of performing simple tasks, providing users with a CLI option when needed.
 * Avoid vendor lock-in as much as possible.
 * Compatibility with most PowerShell libraries.
 * Provide a design model familiar to developers who've worked with commercial data integration tools before.

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
Set-PSYConnection -Name "SqlServerTarget" -Provider SqlServer -ConnectionString "Server=TargetServer;Integrated Security=true;Database=DatabaseB"

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