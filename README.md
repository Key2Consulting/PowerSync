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
# Create and Connect to PowerSync repository (stores all our runtime and persisted state).
New-PSYJsonRepository 'PowerSyncRepo.json'
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
There's essentially three ways to install and use PowerSync in a windows environment. All of these options require you to download PowerSync from GitHub, and extract the PowerSync folder (PowerSync is not available via a repository). 

PowerSync requires a minimum of RemoteSigned execution policy.
```PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

After downloading, use must unblock the source files.
```PowerShell
Get-ChildItem -Path "$YourPathToPowerSyncFolder" -Recurse | Unblock-File
```

You can also run the Install-PowerSync script included in the root of the GitHub project.
```PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned   # escalate execution policy
Unblock-File -Path '.\Install-PowerSync.ps1'        # in case it was just downloaded
.\Install-PowerSync.ps1                             # install for current user only
.\Install-PowerSync.ps1 -InstallForAllUsers         # OR install for all users (requires Run as Administrator)
Import-Module PowerSync
```

See [Installing a PowerShell Module](https://docs.microsoft.com/en-us/powershell/developer/module/installing-a-powershell-module) for more information.

#### Copy to $PSHome
Copy PowerSync folder to $PSHome (*%Windir%\System32\WindowsPowerShell\v1.0\Modules*). This will enable PowerSync for all users of a machine, but requires local admin permssion. Use `Import-Module PowerSync` in your script.
#### Copy to $Home\Documents\WindowsPowerShell\Modules
Copy PowerSync folder to $Home\Documents\WindowsPowerShell\Modules (*%UserProfile%\Documents\WindowsPowerShell\Modules*). This enables PowerSync for the current user only. This option isolates your version of PowerSync from others on the same machine, and does not require local admin permission. Use `Import-Module PowerSync` in your script.
#### Include as Library in Broader Project
Include the PowerSync folder as part of a project folder structure, and import via it's relative path. This option is recommended for development projects, and may be the only option available for PaaS hosting scenarios. It ensures proper version control of PowerSync with your project. Use something like `Import-Module "$PSScriptRoot\PowerSync"` in your script.
### Linux
TODO
## PSY Command Prefix
All PowerSync commands use the 'PSY' prefix to ensure uniqueness with other modules (pronounces *Sigh*).

# Concepts
## The PowerSync Repository
The PowerSync Repository is a data store PowerSync uses to store all of its internal persisted state and runtime information. The repository should not be confused with source and target data sources (i.e. Connections) used for data integration purposes. For a given project, you would have one and only one repository. Except for [Quick Commands](#quick-commands), PowerSync commands require a connection to a repository to function.
> Quick Commands do not require the explicit configuration of a repository, but will create one internally for the duration of the command execution.

There are two types of repositories: file and database. Currently, Json and OleDb are the only file and database repository options.

### Json Repository
The Json file repository is the quickest and easiest way to start using PowerSync. It uses a single Json formatted text file stored on the local file system. One of the downsides to using a Json repository is that Json files can be difficult to read and query. It also does not scale well under heavy usage, since reading/writing to a single text file can become a bottleneck. However, it's a great choice for small projects or workflows that don't need a full-fledged database.

The following is an example of creating, connecting, and then removing a Json repository (of course, in a real project you probably wouldn't create and then immediately remove a repository).
```PowerShell
New-PSYJsonRepository '.\MyPSYRepo.json'
Connect-PSYJsonRepository '.\MyPSYRepo.json'
# Do some work
Remove-PSYJsonRepository '.\MyPSYRepo.json'
```

### OleDb Repository
An OleDb database repository is more complex option, but also more robust. It also provides additional persistent (i.e. custom tables) to manage custom configuration specific to your project. It also allows for more complex querying, monitoring, and reporting of the runtime state of your project. The downside is it requires a database system, and lacks the portability of files.

The OleDb provider can use any OleDb compatible database. However, the use of a database repository requires the creation of a database which conforms to the structures and capabilities required by PowerSync. Since database systems and their proprietary syntax can vary significantly, PowerSync delegates creation and management of the database repository to your project. However, PowerSync does include *Kits* which contain pre-packaged and fully functional database repository projects ready to use. Once deployed, maintaining and upgrading database repositories based on those kits is the responsibility of the developer.

TODO: We may need to reconsider this, since we want use to be as simple as possible.
#### Usage
TODO

## Logging
Enterprise integration systems are inherently complex, with many moving parts and potential points of failure. Logging of a large-scale data integration system is one of the most important, and often overlooked capabilities. Comprehensive logging provides projects with insight into the runtime state of the framework, and is critical for monitoring, debugging, and performance tuning.

PowerSync builds upon the logging concepts baked into PowerShell, and adds additional logs to support data integration specific requirements.

### Error Log
The error log records unexpected exceptions and logs them to the repository using `Write-PSYErrorLog`. The error log is used with Try/Catch blocks, which are highly promoted by the PowerSync framework. `Write-PSYErrorLog` will honor the current Error Action Preference. See the [API](TODO) for more information.
```PowerShell
try {
    $x = 1 / 0
}
catch {
    Write-PSYErrorLog $_
}
```
### Information and Verbose Log
The Information and Verbose logs record similar information. The information log should be to narrate the work being performed at a high level. The Verbose Log is similar to the Information Log, in that it should narrate the work being performed, but at a more detailed level. The verbose log provides an extra level of detail the information log does not. You can enable verbose logging using the `-Verbose` common parameter.
```PowerShell
# Do some work
Write-PSYInformationLog -Message "Completed synchronization of source and target."
Write-PSYVerboseLog -Message "Exported $rowCount data from $tableName"
```

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