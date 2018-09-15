# Introduction
PowerSync is a PowerShell based data integration system. It can be used as a complex and customizable data integration framework, or as a command-line option for administering data systems. It's based on similar design concepts found in commercial data integration products, like connections, variables, activities, and export/import operations. PowerSync adheres to the ELT model where transformations are best performed by the database system oppose to the integration framework. 

As its rooted in PowerShell, PowerSync natively supports the plethora of PowerShell commands/cmdlets found in the community and included by the PowerShell platform. PowerShell is known for it's convenient and simplistic API for managing vast numbers of resources. It's PowerSync's goal to provide that same simplistic API for managing data resources.

## Features
 - Portable by nature, so it can run on a desktop, server, Linux or Windows without much overhead.
 - Easily scales alongside it's hosting environment (e.g. Azure WebJobs).
 - High performance Exporters and Importers compatible with a wide range of data systems.
 - Sequential or parallel execution.
 - Activity model to organize work and isolate workloads.
 - Comprehensive logging system.
 - Process resiliency support (i.e. resume/retry).
 - State management system.
 - Highly customizable.

## Design Goals
 * Existing tools make it difficult to reuse code, where many times the majority of the work is repetitive. PowerSync should allow users to build upon prior work by creating compositions of new capablities using existing components, and conforming to the [DRY Principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself).
 * Procedural programming model with source control versioning that works (ever try to compare an SSIS package?).
 * Support weak typing of source and target schemas.
 * Reduce the overhead and complexity of performing simple tasks, providing users with a CLI option when needed.
 * Avoid vendor lock-in as much as possible.
 * Compatibility with most PowerShell libraries.
 * Provide a design model familiar to developers who've worked with commercial data integration tools before.

## The Syntax
Copies a table from one database to another database, creating the table if it doesn't exist.
```powershell
Copy-PSYTable `
    -SProvider SqlServer -SServer 'SourceServer' -SDatabase "DatabaseA" -STable "dbo.MyTable" `
    -TProvider SqlServer -TServer 'TargetServer' -TDatabase "DatabaseB" -TTable "dbo.MyTableCopy"
```
Import a CSV file into a database table, and then back out to a tab delimited file.
```powershell
Copy-PSYTable `
    -SProvider TextFile -SConnectionString "InputFile.csv" -SFormat CSV -SHeader `
    -TProvider SqlServer -TServer 'TargetServer' -TDatabase "DatabaseB" -TTable "dbo.MyTable"
Copy-PSYTable `
    -SProvider SqlServer -SServer 'TargetServer' -SDatabase "DatabaseB" -STable "dbo.MyTable" `
    -TProvider TextFile -TConnectionString "OutputFile.txt" -TFormat TSV -THeader
```
Orchestrate a parallel, multi-table copy between different database systems.
```powershell
# Connect to PowerSync repository (stores all our runtime and persisted state).
Connect-PSYJsonRepository 'PowerSyncRepo.json'

# Create source and target connections (only need to do this once).
Set-PSYConnection -Name "OracleSource" -Provider Oracle -ConnectionString "Data Source=MyOracleDB;Integrated Security=yes;"
Set-PSYConnection -Name "SqlServerTarget" -Provider SqlServer -ConnectionString "Server=TargetServer;Integrated Security=true;Database=DatabaseB"

# Start a parallel activity which copies the tables.
@('Table1', 'Table2', 'Table3') | Start-PSYForEachActivity -Name 'Multi-Table Copy' -Parallel -Throttle 3 -ScriptBlock {
        Export-PSYOracle -Connection "OracleSource" -Table $Input `
            | Import-PSYSqlServer -Connection "SqlServerTarget" -Table $Input -Create -Index
    }
```
## Installing and Importing
### Windows
There's essentially three ways to install and use PowerSync in a windows environment. All of these options require you to download PowerSync from GitHub, and extract the PowerSync folder (PowerSync is not available via a repository). After downloading, use a similar command to unblock the source files.
```PowerShell
Get-ChildItem -Path "$YourPathToPowerSyncFolder" -Recurse | Unblock-File
```

PowerSync requires a minimum of RemoteSigned execution policy.
```PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

You can also run the Install-PowerSync script included in the root of the GitHub project.
```PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned   # escalate execution policy
Unblock-File -Path '.\Install-PowerSync.ps1'        # in case it was just downloaded
.\Install-PowerSync.ps1                             # install for current user only
.\Install-PowerSync.ps1 -InstallForAllUsers         # OR install for all users (requires Run as Administrator)
```

See [Installing a PowerShell Module](https://docs.microsoft.com/en-us/powershell/developer/module/installing-a-powershell-module) for more information.

#### Copy to $PSHome
Copy PowerSync folder to $PSHome (%Windir%\System32\WindowsPowerShell\v1.0\Modules). This will enable PowerSync for all users of a machine, but requires local admin permssion. Use `Import-Module 'PowerSync'` in your script.
#### Copy to $Home\Documents\WindowsPowerShell\Modules
Copy PowerSync folder to $Home\Documents\WindowsPowerShell\Modules (%UserProfile%\Documents\WindowsPowerShell\Modules). This enables PowerSync for the current user only. This option isolates your version of PowerSync from others on the same machine, and does not require local admin permission. Use `Import-Module 'PowerSync'` in your script.
#### Include as Library in Broader Project
Include the PowerSync folder as part of a project folder structure, and import via it's relative path. This option is recommended for development projects, and may be the only option available for PaaS hosting scenarios. It ensures proper version control of PowerSync with your project. Use something like `Import-Module $PSScriptRoot\PowerSync'` in your script.
### PSY Command Prefix
All PowerSync commands use the 'PSY' prefix to ensure uniqueness with other modules (pronounces Sai).
## Choosing the Right Repository
## Copy a Table
### Linux
TODO
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
## Adding Resiliency
# References
 - ASCII based diagrams created with [asciiflow](http://asciiflow.com).