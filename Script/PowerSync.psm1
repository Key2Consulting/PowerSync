<#
.SYNOPSIS
PowerSync is a lightweight data synchronizing system.

.DESCRIPTION
This is the advanced CLI. For a simpler CLI, use one of the shortcut versions (i.e. PowerSync-Text2MSSQL). See examples for more information on usage.

PowerSync can handle basic data integration scenarios using an ELT strategy (Extract, Load, then Transform). The following data integration features are supported:
 - Copy a table or the results of a query into a new target database table. optionally creating target table dynamically.
 - Support a variety of sources and targets (CSV, SQL Server, MySQL, SQLDW).
 - Full or incremental extractions.
 - Supports logging, to a variety of targets (i.e. files, database tables).
 - Processing is data driven, so can add/remove data feeds with ease.
 - Highly customizable by client. PowerSync handles the heavy lifting, but leaves case specific requirements to its users.
 - Publish in a transactionally consistent manner (i.e. does not drop then recreate, but rather stages and swaps).

The key concepts in PowerSync are:
 - Manifest: Identifies all data feeds to process. Feeds include a source and target. Manifests can also be written back to, for instance to save last run date.
 - Source: The location where data is being extracted.
 - Target: The destination where data is being loaded and transformed.
 - Log: PowerSync includes a logging framework, which can be integrated into other logging frameworks.
 - Provider Configuration: The set of configurations defined and used by the different provider components (Source, Target, Manifest, Log), and can be set via command line, manifest, or both.
 - Project Configuration: The collection of customizations (scripts, manifests, etc) created and managed by client code.

Manifests are the workhorse of the process. Manifests identify each and every data feed, as well as provider configurations allowing each feed to be 
customized. The provider configuration passed into the command-line is overlayed with configuration retrieved from the manifest. PowerSync also supports 
writebacks to the manifest itself. This is useful for tracking runtime information like the last incremental extraction value or the last run date/time.

Events execute in the following order:
 1) Prepare (Source and Target)
 2) Extract (Source)
 3) Load (Target)
 4) Transform (Target)

Client provided scripts are used in each event to support customization. Each script is defined in separate .SQL files and (optionally) 
passed into PowerSync. PowerSync attempts to pass every field from the provider configuration into each script using SQMCMD :setvar syntax, and also applies 
SQLCMD variables that only exist in the script so that the script has no SQLCMD syntax prior to execution.
.PARAMETER Manifest
A hashtable defining the provider specific manifest configuration. See examples and online help for more information.
.PARAMETER Log
A hashtable defining the provider specific log configuration. See examples and online help for more information.
.PARAMETER Source
A hashtable defining the provider specific data configuration. See examples and online help for more information.
.PARAMETER Target
A hashtable defining the provider specific data configuration. See examples and online help for more information.
.EXAMPLE
PowerSync `
    -Source @{
        ConnectionString = "PSProvider=TextDataProvider;FilePath=$C:\Temp\TestCSVToSQL\Sample100.csv;Header=False;Format=CSV;Quoted=True";
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        Schema = "dbo"
        Table = "TestCSVToSQL100"
        AutoCreate = $true;
        Overwrite = $true;
    }
.EXAMPLE
PowerSync `
    -Manifest @{
        ConnectionString = "PSProvider=TextManifestProvider;Data Source=C:\Temp\TestSQLToSQL\Manifest.csv;Header=True;Format=CSV"
    } `
    -Log @{
      ConnectionString = "PSProvider=TextLogProvider;FilePath=$logFilePath;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        ExtractScript = "C:\Temp\TestSQLToSQL\Extract.sql";
        PrepareScript = "C:\Temp\TestSQLToSQL\PrepareSource.sql";
        Timeout = 3600;
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        PrepareScript = "C:\Temp\TestSQLToSQL\PrepareTarget.sql";
        TransformScript = "C:\Temp\TestSQLToSQL\Transform.sql";
    }
.LINK
https://github.com/Key2Consulting/PowerSync
.NOTES
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>
function PowerSync {
    param
    (
        [Parameter(HelpMessage = "Manifest configuration information.", Mandatory = $false)]
        [hashtable] $Manifest,
        [Parameter(HelpMessage = "Log configuration information.", Mandatory = $false)]
        [hashtable] $Log,
        [Parameter(HelpMessage = "Sourcexx configuration information.", Mandatory = $true)]
        [hashtable] $Source,
        [Parameter(HelpMessage = "Target configuration information.", Mandatory = $true)]
        [hashtable] $Target
    )

    # Module Initialization (TODO: CONVERT TO ACTUAL PSM1 FILES)
    Set-StrictMode -Version 2
    . "$PSScriptRoot\Provider\Provider.ps1"
    . "$PSScriptRoot\Provider\Log\LogProvider.ps1"
    . "$PSScriptRoot\Provider\Log\TextLogProvider.ps1"
    . "$PSScriptRoot\Provider\Log\MSSQLLogProvider.ps1"
    . "$PSScriptRoot\Provider\Manifest\ManifestProvider.ps1"
    . "$PSScriptRoot\Provider\Manifest\MSSQLManifestProvider.ps1"
    . "$PSScriptRoot\Provider\Manifest\TextManifestProvider.ps1"
    . "$PSScriptRoot\Provider\Manifest\NoManifestProvider.ps1"
    . "$PSScriptRoot\Provider\Data\DataProvider.ps1"
    . "$PSScriptRoot\Provider\Data\MSSQLDataProvider.ps1"
    . "$PSScriptRoot\Provider\Data\TextDataProvider.ps1"

    # A data factory to create the correct Provider implementation based on the ConnectionString
    function New-Provider([hashtable] $Configuration, [string] $Namespace = '') {
        # The provider instance
        $provider = $null
        
        # Extract PSProvider variables from connection string
        $sb = New-Object System.Data.Common.DbConnectionStringBuilder
        $sb.set_ConnectionString($Configuration."${Namespace}ConnectionString")
        $type = $sb.'PSProvider'

        # Create and return the specific provider type
        $null = $sb.Remove("PSProvider")        # must remove PSProvider since it's unsupported by many database connection strings
        $Configuration."${Namespace}ConnectionString" = $sb.ConnectionString
        $provider = (New-Object -TypeName "$type" -ArgumentList $Namespace, $Configuration)
        if ($provider -eq $null) {
            throw "No Provider available for connection string"
        }

        return $provider
    }

    # Process Manifest (primary execution loop)
    #
    try {
        # Create Log Provider. If none is specified, default to CSV in caller's directory.
        if ($Log -eq $null) {
            $x = $MyInvocation
            $Log = @{ ConnectionString = "PSProvider=TextLogProvider;FilePath=Log.csv;Header=True;Format=CSV" }
        }

        $global:pLog = New-Provider $Log
        $pLog.BeginLog()

        $pLog.WriteInformation("PowerSync Started")
        $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Process the manifest.  If it doesn't exist, we assume we're processing a single item,
        # and that the configuration for the source/target was set on the command line. We'll still 
        # need manifest provider so that downstream code works, it just won't be connected to anything.
        if ($Manifest -eq $null) {
            $Manifest = @{ConnectionString = "PSProvider=NoManifestProvider"}
        }
        $pManifest = New-Provider $Manifest
        $manifestContent = $pManifest.ReadManifest()
        
        foreach ($item in $manifestContent) {
            try {
                $pLog.BeginLog()
                $stopWatchStep = [System.Diagnostics.Stopwatch]::StartNew()
                
                # Caller sets default configuration on the command line, but the manifest can
                # override those settings.
                $sourceConfig = $pManifest.OverrideManifest("Source", $Source, "", $item)
                $targetConfig = $pManifest.OverrideManifest("Target", $Target, "", $item)
                
                # Create connections to source and destination for the current manifest item
                $pSource = New-Provider $sourceConfig 'Source'
                $pTarget = New-Provider $targetConfig 'Target'

                # Prepare Source
                $writeback = $pSource.Prepare()
                $pManifest.WriteManifestItem($writeback)
                
                # Prepare Target
                $writeback = $pTarget.Prepare()
                $pManifest.WriteManifestItem($writeback)

                # Extract and Load (writeback not supported)
                $extract = $pSource.Extract()
                [System.Data.IDataReader] $reader = $extract[0]
                [System.Collections.ArrayList] $schemaInfo = $extract[1]
                $pTarget.Load($reader, $schemaInfo)

                # Transform Target
                $writeback = $pTarget.Transform()
                $pManifest.WriteManifestItem($writeback)

                # Final logging. Note that the only field we know this item has is the RuntimeID. However, that's a sequential
                # number and not very informative, so we'll search the columns and attempt to identify something useful to display.
                # Yes, this is a bit hacky...
                $possibleFields = $targetConfig.Keys.Where({$_.Contains('Table')})
                $friendlyIdentifier = ""
                if ($possibleFields.Count -gt 0) {
                    $friendlyIdentifier = $targetConfig[$possibleFields[$possibleFields.Count - 1]]      # publish table names tend to be listed last
                    $friendlyIdentifier = "($friendlyIdentifier)"
                }
                $pLog.WriteInformation("Completed Processing item $($item.RuntimeID) $friendlyIdentifier in $($stopWatchStep.Elapsed.TotalSeconds) seconds.")
                $pLog.EndLog()
            }
            catch {
                $pLog.WriteException($_.exception, $false)
            }
            finally {
                if ($pSource) {
                    $pSource.Close()
                }
                if ($pTarget) {
                    $pTarget.Close()
                }
            }
        }
    }
    catch {
        $pLog.WriteException($_.exception, $true)
    }
    finally {
        if ($pManifest) {
            $pManifest.Close()
        }
        if ($pLog) {
            $pLog.Close()
        }
    }

    $pLog.WriteInformation("PowerSync-Manifest Completed in $($stopWatch.Elapsed.TotalSeconds) seconds.")
    $pLog.EndLog()
}

<#
.SYNOPSIS
Imports a single text file into a SQL Server database.

.EXAMPLE
PowerSync-CSV2MSSQL -Path "C:\Temp\Data.csv" -Server MYSERVER -Database MYDATABASE -Schema ""

.LINK
https://github.com/Key2Consulting/PowerSync
.NOTES
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>
function PowerSync-Text2MSSQL {
    param
    (
        [Parameter(HelpMessage = "The source CSV file to import.", Mandatory = $true)]
        [string] $Path,
        [Parameter(HelpMessage = "The target SQL Server name.", Mandatory = $true)]
        [string] $Server,
        [Parameter(HelpMessage = "The target SQL Server database.", Mandatory = $true)]
        [string] $Database,
        [Parameter(HelpMessage = "The fully qualified target table.", Mandatory = $true)]
        [string] $TableFQName,
        [Parameter(HelpMessage = "Format of the text file (CSV or Tab)", Mandatory = $false)]
        [string] $Format = "CSV",
        [Parameter(HelpMessage = "Indicates the first row of the CSV file does not contain header information.", Mandatory = $false)]
        [switch] $NoHeader,
        [Parameter(HelpMessage = "Disables dynamic target table creation based on the structure in the CSV file.", Mandatory = $false)]
        [switch] $NoAutoCreate,
        [Parameter(HelpMessage = "Disables the automatic creation of a columnstore index on the target.", Mandatory = $false)]
        [switch] $NoAutoIndex,
        [Parameter(HelpMessage = "Drops the target table if it already exists.", Mandatory = $false)]
        [switch] $Overwrite
    )
    
    # PowerSync options per command-line
    [bool] $header = $true
    if ($NoHeader) {
        $header = $false
    }
    [bool] $autoCreate = $true
    if ($NoAutoCreate) {
        $autoCreate = $false
    }
    [bool] $autoIndex = $true
    if ($NoAutoIndex) {
        $autoIndex = $false
    }
    [bool] $overwrite = $true
    if ($Overwrite) {
        $overwrite = $true
    }

    # Extract schema and table names from fully qualified name
    $schema = GetSchemaName($TableFQName)
    $table = GetTableName($TableFQName)

    PowerSync `
        -Source @{
            ConnectionString = "PSProvider=TextDataProvider;FilePath=$Path;Header=$header;Format=$Format;Quoted=True";
        } `
        -Target @{
            ConnectionString = "PSProvider=MSSQLDataProvider;Server=$Server;Integrated Security=true;Database=$Database;";
            Schema = $schema
            Table = $table
            AutoCreate = $autoCreate
            AutoIndex = $autoIndex
            Overwrite = $overwrite
        }
}

<#
.SYNOPSIS
Imports a data from one SQL Server database to another.

.EXAMPLE
PowerSync-MSSQL2MSSQL -Path "C:\Temp\Data.csv" -Server MYSERVER -Database MYDATABASE -Schema ""

.LINK
https://github.com/Key2Consulting/PowerSync
.NOTES
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>
function PowerSync-MSSQL2MSSQL {
    param
    (
        [Parameter(HelpMessage = "The source SQL Server name.", Mandatory = $true)]
        [string] $SourceServer,
        [Parameter(HelpMessage = "The source SQL Server database.", Mandatory = $true)]
        [string] $SourceDatabase,
        [Parameter(HelpMessage = "The target SQL Server name.", Mandatory = $true)]
        [string] $TargetServer,
        [Parameter(HelpMessage = "The target SQL Server database.", Mandatory = $true)]
        [string] $TargetDatabase,
        [Parameter(HelpMessage = "The extraction query.", Mandatory = $true)]
        [string] $ExtractQuery,
        [Parameter(HelpMessage = "The fully qualified target table.", Mandatory = $true)]
        [string] $TableFQName,
        [Parameter(HelpMessage = "Disables dynamic target table creation based on the structure in the CSV file.", Mandatory = $false)]
        [switch] $NoAutoCreate,
        [Parameter(HelpMessage = "Disables the automatic creation of a columnstore index on the target.", Mandatory = $false)]
        [switch] $NoAutoIndex,
        [Parameter(HelpMessage = "Drops the target table if it already exists.", Mandatory = $false)]
        [switch] $Overwrite
    )
    
    # PowerSync options per command-line
    [bool] $autoCreate = $true
    if ($NoAutoCreate) {
        $autoCreate = $false
    }
    [bool] $autoIndex = $true
    if ($NoAutoIndex) {
        $autoIndex = $false
    }
    [bool] $overwrite = $true
    if ($Overwrite) {
        $overwrite = $true
    }

    # Extract schema and table names from fully qualified name
    $schema = GetSchemaName($TableFQName)
    $table = GetTableName($TableFQName)

    PowerSync `
        -Source @{
            ConnectionString = "PSProvider=MSSQLDataProvider;Server=$SourceServer;Integrated Security=true;Database=$SourceDatabase;Type System Version=SQL Server 2012";
            ExtractScript = $ExtractQuery
        } `
        -Target @{
            ConnectionString = "PSProvider=MSSQLDataProvider;Server=$TargetServer;Integrated Security=true;Database=$TargetDatabase;Type System Version=SQL Server 2012";
            Schema = $schema
            Table = $table
            AutoCreate = $autoCreate
            AutoIndex = $autoIndex
            Overwrite = $overwrite
        }
}

function GetSchemaName([string]$TableName) {
    $parts = $TableName.Split('.').Replace('[', '').Replace(']', '')
    return $parts[0]
}
function GetTableName([string]$TableName) {
    $parts = $TableName.Split('.').Replace('[', '').Replace(']', '')
    return $parts[1]
}

Export-ModuleMember -Function 'PowerSync'
Export-ModuleMember -Function 'PowerSync-Text2MSSQL'
Export-ModuleMember -Function 'PowerSync-MSSQL2MSSQL'