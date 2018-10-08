# Introduction
PowerSync is a PowerShell based data integration system. It can be used as a complex and customizable data integration framework, or as a command-line option for synchronizing data between platforms. It's based on similar design concepts found in commercial data integration products, like connections, variables, activities, and export/import operations. PowerSync adheres to the ELT philosophy where transformations are best performed by the database system oppose to the integration framework.

As it's rooted in PowerShell, PowerSync natively supports the plethora of PowerShell commands/cmdlets found in the community and included by the PowerShell platform. PowerShell is known for it's convenient and simplistic API for managing vast numbers of resources. It's PowerSync's goal to provide that same simplistic API for managing data resources.

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
Connect-PSYJsonRepository -Path 'PowerSyncRepo.json' -Create

# Create source and target connections (only need to do this once).
Set-PSYConnection -Name "OracleSource" -Provider Oracle -ConnectionString "Data Source=MyOracleDB;Integrated Security=yes;"
Set-PSYConnection -Name "SqlServerTarget" -Provider SqlServer -ConnectionString "Server=TargetServer;Integrated Security=true;Database=DatabaseB"

# Start a parallel activity which copies the tables.
('Table1', 'Table2', 'Table3') | Start-PSYActivity -Name 'Multi-Table Copy' -Parallel -Throttle 3 -ScriptBlock {
        Export-PSYOracle -Connection "OracleSource" -Table $_ `
            | Import-PSYSqlServer -Connection "SqlServerTarget" -Table $_ -Create -Index
    }
```
## Installing and Importing the Module
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
#### Project Library
Include the PowerSync folder as part of a project folder structure, and import via it's relative path. This option is recommended for development projects, and may be the only option available for PaaS hosting scenarios. It ensures proper version control of PowerSync with your project. Use something like `Import-Module "$PSScriptRoot\PowerSync"` in your script.
### Linux
TODO
## PSY Command Prefix
All PowerSync commands use the 'PSY' prefix to ensure uniqueness with other modules (pronounces *Sigh*).

# Concepts
## The PowerSync Repository
The PowerSync Repository is a data store PowerSync uses to store all of its internal persisted state and runtime information. The repository should not be confused with source and target data sources (i.e. Connections) used for data integration purposes. For a given project, you would have one and only one repository.

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

## Activities
PowerSync activities organize your data integration workload into atomic units of work. You execute an Activity with the `Start-PSYActivity` function. Although activities are not required, they provide certain benefits:
 - Log operations performed during an activity are associated to that activity.
 - Automatic logging of errors.
 - Sequential or parallel execution (using remote jobs).
 - Scalable and decoupled execution of activities on remote servers using queues.

Activities are nestable, giving projects the ability to decompose complex workloads into smaller, simpler units of work. You can even pass parameters to activities and reference it within activity using the `$_` variable, and get results back.
```PowerShell
Start-PSYActivity -Name 'Outer Activity' -ScriptBlock {
    Start-PSYActivity -Name 'Inner Activity' -ScriptBlock {
        Write-Host "Hello World"
    }
}

'Hello World' | Start-PSYActivity -Name 'Outer Activity' -ScriptBlock {
    $out = $_ | Start-PSYActivity -Name 'Inner Activity' -ScriptBlock {
        "$($_) Inner"
    }
    Write-Host "$out from Outer"
}
```

Activities are synchronous unless you set the `-Async` switch, which you can await later on. 
```PowerShell
# Async with parameter but no return value
$async = 'Hello World' | Start-PSYActivity -Name 'Asynchronous Activity' -Async -ScriptBlock {
    Write-Host $_
}
Write-Host 'Some long running task'
$async | Wait-PSYActivity       # echos any log information collected during the activity

# Async with parameter and return value
$async = 'Hello World' | Start-PSYActivity -Name 'Asynchronous Activity' -Async -ScriptBlock {
    "$($_) Async"
}
Write-Host 'Some long running task'
$x = $async | Wait-PSYActivity       # equals Hello World Async

# Async with parameter, but returns full activity information after await
$activity = 'Hello World' | Start-PSYActivity -Name 'Asynchronous Activity' -Async -ScriptBlock {
    "$($_) Async"
} | Wait-PSYActivity -Passthru
Write-Host $activity.OutputObject

# Executes several script blocks asynchronously
$out = (
    ("input 1" | Start-PSYActivity -Name 'Asynchronous Activity 1' -Async -ScriptBlock {
        "Hello 1"
    }),
    ("input 2" | Start-PSYActivity -Name 'Test Queued Activity Execution 2' -Async -ScriptBlock {
        "Hello 2"
    }),
    ("input 3" | Start-PSYActivity -Name 'Test Queued Activity Execution 3' -Async -ScriptBlock {
        "Hello 3"
    })
) | Wait-PSYActivity
```

You can execute the same activity for a list of items, foreach style (use the variable `$_` to retrieve the current item).
```PowerShell
(1, 2, 3) | Start-PSYActivity -Name 'ForEach Activity' -ScriptBlock {
    Write-Host "Hello Item $($_)"
}
```

ForEach activities execute in a sequential manner by default. However, setting the `-Parallel` switch will execute the activity in parallel (where applicable) and can be throttled via the `-Throttle` parameter.
```PowerShell
# Prints 1, 2, 3
(1, 2, 3) | Start-PSYActivity -Name 'Multiple Activities' -ScriptBlock {
    Start-Sleep -Seconds (3 - $_)
    Write-Host $_
}
# Prints 3, 2, 1
(1, 2, 3) | Start-PSYActivity -Name 'Multiple Activities' -Parallel -Throttle 5 -ScriptBlock {
    Start-Sleep -Seconds (3 - $_)
    Write-Host $_
}
```

Parallel activities do not support the `-Async` switch since there's no way to throttle the execution of each enumerated value. Upon completion of a ForEach, you are guaranteed all its activities have completed, even though within the ForEach the activities may have executed asynchronously.

Activities can be placed in a queue and executed by remote servers monitoring the queue. This allows for scalable execution of activities, while retaining centralization of your application logic.
```PowerShell
'Foo' | Start-PSYActivity -Name 'Queued Activity' -Queue 'MyWorkQueue' -ScriptBlock {
    Write-Host 'Some long running task: ' + $_
} | Wait-PSYActivity

(1..1000) | Start-PSYActivity -Name 'Queued Activity' -Queue 'MyWorkQueue' -ScriptBlock {
    Write-Host 'This may take a while: Item' + $_
} | Wait-PSYActivity
```

Processing of queued activities takes place on any remote server by monitoring the queue and receiving the activity.
```PowerShell
Receive-PSYQueuedActivity -Queue 'MyWorkQueue' -Continous       # never exits
```

You can also simulate a remote receiver in your application.
```PowerShell
$receiver = Start-PSYActivity -Name 'Self-Hosted Receiver' -Async -ScriptBlock {
    Receive-PSYQueuedActivity -Queue 'MyWorkQueue' -Continous
}

# ...do lots of stuff

Stop-PSYActivity $receiver
```

### Debugging Parallel Processes
Debugging parallel execution in PowerShell is tricky. Enabling parallel execution disables breakpoints in most IDEs. You can leverage the PowerSync logs to help pinpoint the issue, but sometimes stepping through the code is the best and only option. When initially developing or debugging an issue, consider disabling parallel execution by temporarily removing the `-Parallel` switch. If the problem only occurs during parallel execution, the `WaitDebugger` switch will force each remote job to break in the debugger. Howevever, it will break within an internal PowerSync function so you'll need to step through until you reach your code.

## State Variables
PowerSync State Variables are discrete state managed by PowerSync. State Variables are simple name/value pairs which are stored in the repository. The value can be a primitive type (e.g. numbers or text), or complex types (e.g. hashtables or arrays). The primary benefits of using State Variables over only using native PowerShell variables is that they are
 - Persisted
 - Work with asynchronous/parallel processes
 - State changes are logged

```PowerShell
Set-PSYVariable -Name 'MyVar' -Value 'Hello World'                          # scalar
Set-PSYVariable -Name 'MyComplexVar' -Value @{Hello = 'World'; Abc = 123}   # hashtable
Set-PSYVariable -Name 'MyComplexListVar' -Value (                           # array of hashtables
        @{Prop1 = 123; Prop2 = 'ABC'},
        @{Prop1 = 456; Prop2 = 'DEF'},
        @{Prop1 = 789; Prop2 = 'GHI'}
    )
Write-Host "$(Get-PSYVariable -Name 'MyVar')"
```
`Get-PSYVariable` and `Remove-PSYVariable` support the wildcards `*` and `?`.
```PowerShell
Remove-PSYVariable -Name 'My*' -Wildcards
```
An important consideration is that State Variable read/write operations are performed as a single atomic unit of work. In other words, there's no way to update just part of a variable when performing concurrent updates. If you require a multi-row variable where each row is independently updatable, consider creating multiple variables with a name differing by an index and using wildcards.
```PowerShell
Set-PSYVariable -Name 'MyVar[0]' -Value 'Blue'
Set-PSYVariable -Name 'MyVar[1]' -Value 'Red'
Set-PSYVariable -Name 'MyVar[2]' -Value 'Green'
foreach ($var in (Get-PSYVariable -Name 'MyVar[*]' -Wildcards)) {
    Write-Host "Color is $($var)"
}
```
State Variable access can also be synchronized across parallel processes via Lock-PSYVariable. Locking a variable establishes exclusive access so no other process can read or write to the same variable. An exclusive lock blocks other processes, so the duration of the lock should minimized. Locking uses Mutexes to ensure synchronization, so it's limited to parallel processes executing on the same server.
```PowerShell
Lock-PSYVariable 'TestVariable' {
        Set-PSYVariable 'TestVariable' ((Get-PSYVariable 'TestVariable') + 1)
    }
```
If PowerSync State Variables don't meet your requirements, look to using [Stored Commands](#stored-commands) instead and creating your own data structures within your repository.
### State Management and Concurrency
Native PowerShell variables (i.e. `$myVar = 123`) have limited use in data integration systems because those systems are inherintely designed to be long running (and susceptible to failures) and recurring, picking up where it left off. These capabilities require persisted state, which PowerShell variables do not provide. In addition, many of these processes will execute in parallel so state mechanisms must support concurrency. PowerSync provides several concurrent, state management constructs, like [State Variables](#state-variables) and [Stored Commands](#stored-commands). You also have the option of managing state yourself outside PowerSync. You could use a custom database or even a web service.

Since remote jobs are used for parallel execution, any PowerShell variable passed into the parallel activity must support PowerShell serialization (primitives, hashtables, arrays). Otherwise, the data won't get marshalled across correctly and you'll get unexpected results. You may want to avoid using PowerShell classes altogether as these can be difficult to serialize (it's worth mentioning they also have notorious thread safety issues). 

One very important point is that PowerShell variables are not automatically marshalled across to parallel processes. Although, *sequential* activities do retain visibility to these variables. Furthermore, changes to enumerated objects during asynchronous or parallel execution (`-Async` & `-Parallel`) will not affect the copy in the caller's process space. To communicate with asynchronous activities, pipe data into the activity (i.e. parameters) and return data from the activity.

Alternatively, you can pass variables into and get results back out of activities. In this approach, state is managed by the main activity/thread. However, in the case of a system crash, you might lose all state information.

```PowerShell
$readMe = 123
Start-PSYActivity -ScriptBlock {
    $x = $readMe     # $x equals 123
}
Start-PSYActivity -Parallel -ScriptBlock {
    $x = $readMe     # $x equals null
}
Start-PSYActivity -Async -ScriptBlock {
    $x = $readMe     # $x equals null
} | Wait-PSYActivity
```
Here's the correct way to pass data (or use PowerSync variables).
```PowerShell
$x = $x | Start-PSYActivity -Async -ScriptBlock {
    $_ + 1
} | Wait-PSYActivity
```
## Connections
Connections define all of the required information required to establish a connection to a source or target system. Connections are persisted in the repository, only need to be created once, and then referenced by name in downstream functions.

Connections definitions are fairly generic and platform agnostic. The specific properties required to establish a connection to a data system depend on the provider of a connection, but most providers support the notion of a Connection String.

```PowerShell
Set-PSYConnection -Name "MyConnection" -Provider SqlServer -ConnectionString "Server=MyServer;Integrated Security=true;Database=MyDatabase"      # creates or overwrites
Get-PSYConnection -Name "MyConnection"       # you would rarely use this function
Remove-PSYConnection -Name "MyConnection"
```
### File Connections
File based connections use the ConnectionString property as the base path to the file. When the connection is used within an importer, the full path to the file is a combination of the ConnectionString and the Path passed into the importer. Either of those could be omitted, as long as the other supplies the full path. So technically speaking, file importers do not require a connection.

### Connection Examples
```PowerShell
Set-PSYConnection -Name "SqlServerConnection" -Provider SqlServer -ConnectionString "Server=MyServer;Integrated Security=true;Database=MyDatabase"
Set-PSYConnection -Name "OleDbConnection" -Provider OleDb -ConnectionString "Provider=SQLNCLI11;Server=MyServer;Database=MyDatabase;Trusted_Connection=yes;"
Set-PSYConnection -Name "FolderConnection" -Provider TextFile -ConnectionString "D:\MyFiles\"
Set-PSYConnection -Name "FileConnection" -Provider TextFile -ConnectionString "D:\MyFiles\File1.csv"
```

### Connection Security
Data systems enforce some level of access security, whether via integrated security of the current principle, a user name and password, or certificates. PowerSync only supports integrated security, and user name / password defined within the connection string. It is generally recommended to handle authorization from within your hosting environment such that the credentials executing your PowerSync application are authorized to access backend data systems.

## Stored Commands
Stored Commands are SQL files defined as part of a PowerSync project with the purpose of executing a TSQL command against a database connection. PowerSync will attempt to locate the script (via the `-Name` param) in the Working Folder, which defaults to the location of the script that imported PowerSync. Additional folders can be specified by updating the `PSYCmdPath` environment variable (each path separated by a semicolon).
> Specifying the file extension in the script name is optional.

Alternatively, you can use an explicit query defined in your script instead of a separate file by specifying the `-CommandText` parameter.

Stored Commands accept parameters using the SQLCMD Mode syntax of :setvar and $(VarName). All SQLCMD Mode syntax is removed prior to execution, so Stored Commands work against non-SQL Server databases. Any defined variable reference that's not explicitly passed in as a parameter gets replaced with the :setvar's value defined in the script (i.e. a default). In addition to simple scalar values, lists of hashtables can be passed into scripts as well. The list will be converted into the INSERT VALUES format i.e. ('Field', Field), ('Field', Field).

If the Stored Command returns a resultset, it is converted into an ArrayList of hashtables and returned to the caller. A single row just returns a hashtable.

Sophisticated projects requiring complex configuration structures and custom workflows should leverage Stored Commands for state management. PowerSync [State Variables](#state-variables) could also be used, but are simplistic and do not provide a rich data model.

Example using a custom table in the PowerSync repository to retrieve list of tables to extract.
```PowerShell
# Use a custom script. The parameter Frequency is passed into the script, but Category is not.
$ExcludeList = @(
    [ordered]@{TableName = 'Table1'},
    [ordered]@{TableName = 'Table2'})
$extractWorkload = Invoke-PSYCmd -Connection 'MyConnection' -Name "GetExtractWorkload.sql" -Param @{Frequency = 'Daily'; ExcludeList = $ExcludeList}

# Do extraction and loading...

# Update the high water mark for next extraction. Although using a script is recommended, it's not 
# required (and PowerShell makes it easy to pass parameters).
Invoke-PSYCmd -Connection 'MyConnection' -CommandText "UPDATE dbo.MyDataFeed WHERE HighWaterMark = '$maxModifiedDateTime'"
```
*GetExtractWorkload.sql*
```SQL
:setvar Frequency "Monthly"
:setvar Category "All"      -- not passed so $(Category) defaults to All
:setvar ExcludeList ""
DECLARE @ExcludeList TABLE([TableName] VARCHAR(128))
INSERT INTO @ExcludeList([TableName]) VALUES $(ExcludeList)

SELECT ExtractTableName, LoadTableName, HighWaterMark
FROM dbo.MyDataFeed
WHERE 
    Frequency = '$(Frequency)'
    AND (Category = '$(Category)' OR '$(Category)' = 'All')
    AND TableName NOT IN (SELECT TableName FROM @ExcludeList)
```

## Exporters and Importers
Exporters and Importers together create flows of data from a source target to a target. An export function is always paired with an import function using the pipe `|` command, but they can each point to different data platforms.

The following exports data from a CSV file and imports it into a SQL Server table, creating the table if it doesn't exist.
```PowerShell
Export-PSYTextFile -Connection "MySourceConnection" -Path "MySourceFile.csv" -Format CSV -Header `
    | Import-PSYSqlServer -Connection "MyTargetConnection" -Table "dbo.MyTargetTable" -Create
```

Although the `|` command is used, data does not flow from exporters to importers row-by-row using PowerShell's piping system. Instead, the exporter returns one or more DataReaders, which are then consumed by the importer. Using .NET readers and writers are much faster than PowerShell piping.

The following Exporters/Importers are currently implemented:
 - **TextFile**: CSV or TSV formatted text files, with support for Gzip compression.
 - **AzureBlobTextFile**: Same as TextFile, except stored in Azure Blob Storage.
 - **SqlServer**: Microsoft SQL Server database, with options to automatically create/provision target table and add CCIX indexes.
 - **OleDb**: Generic OleDb database (still in development).

## Logging
Enterprise integration systems are inherently complex, with many moving parts and potential points of failure. Logging of a large-scale data integration system is one of the most important, and often overlooked capabilities. Comprehensive logging provides projects with insight into the runtime state of the framework, and is critical for monitoring, debugging, and performance tuning.

PowerSync builds upon the logging concepts baked into PowerShell, and adds additional logs to support data integration specific requirements.

### Error Log
The error log records unexpected exceptions and logs them to the repository using `Write-PSYErrorLog`. The error log is used with Try/Catch blocks, which is the recommended method for handling exceptions. `Write-PSYErrorLog` will honor the current Error Action Preference.
```PowerShell
try {
    $x = 1 / 0
}
catch {
    Write-PSYErrorLog $_
}
```

### Information and Verbose Log
The Information and Verbose logs record similar information. The information log narrates the work being performed at a high level. The Verbose Log logs similar information, except at a more detailed level. You can enable verbose logging using the `-Verbose` common parameter.
```PowerShell
Write-PSYInformationLog -Message "Completed synchronization of source and target."
$workItems | ForEach-Object { Write-PSYVerboseLog -Message "Exported $($_.$RowCount) data from $($_.$TableName)." }
```

### Debug Log
The Debug Log should be used to log technical operations internal to the system, and useful for debugging purposes. You can enable debug logging using the `-Debug` common parameter.
```PowerShell
Write-PSYDebugLog -Message "Process $PID could not find table '$tableName', initiating table creation."
```
### Variable Log
The Variable Log is used to capture the state changes of PowerSync State Variables. Tracking state changes is important when trying to debug an issue due to dynamic nature of integration systems. Use of `Set-PSYVariable` automatically writes to this log.
```PowerShell
Write-PSYVariableLog -Name 'My Variable Name' -Value 'New Value'
```
### Query Log
The Query Log captures the execution of Stored Commands and their parameters. It provides insight into the queries that extract, load, or transform data, as well as custom state tables applications create in the PowerSync repository. If you use Stored Commands exclusive to execute queries, then the Query Log is already written to for you. Otherwise, use the following syntax to write to the log.

```PowerShell
Write-PSYQueryLog -Name 'Transform Target' -Query 'UPDATE MyTable SET Abc = 123'
```

### Reading the Logs
PowerSync logs are searchable using `Search-PSYLog`, which executes a holistc search across all log types. Search terms support the use of wildcards (e.g. `*` and `?`). Of course, projects using a database repository are free to use whatever RDBMS tools are provided to search the log tables.

```PowerShell
Search-PSYLog -Search '*MyTable*' -StartDate '1/1/2018'   # search all logs for MyTable reference
Search-PSYLog -Type 'ErrorLog' -Search '*MyTable*'        # search just error log for MyTable reference
```

## Quick Commands
Quick Commands are operationally focused shortcuts for performing specific and common tasks. They are designed in the spirit of PowerShell one-liner commands. Unlike all other PowerSync functions, Quick Commands do not require the explicit configuration of a repository, but will create one internally for the duration of the command execution. Use a Quick Command when you simply need to copy some data leveraging the PowerSync framework capabilities.

Imports CSV and TSV files into Sql Server.
```PowerShell
Copy-PSYTable -SProvider TextFile -SConnectionString "MyTextFile.csv" -SFormat CSV -SHeader `
    -TProvider SqlServer -TServer 'MyServer' -TDatabase "MyDatabase" -TTable "dbo.QuickCSVCopy"

Copy-PSYTable -SProvider TextFile -SConnectionString "MyTextFile.txt" -SFormat TSV -SHeader `
    -TProvider SqlServer -TServer 'MyServer' -TDatabase "MyDatabase" -TTable "dbo.QuickTSVCopy"
```

Copies a table from one database to another, automatically creating the target table and adding a CCIX index.
```PowerShell
Copy-PSYTable -SProvider SqlServer -SServer 'MySourceServer' -SDatabase "MySourceDatabase" -STable "dbo.QuickTypedCSVCopy" `
    -TProvider SqlServer -TServer 'MyTargetServer' -TDatabase "MyTargetDatabase" -TTable "dbo.QuickTypedCSVCopyOfCopy"
```