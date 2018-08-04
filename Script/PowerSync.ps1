<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
The main entry point for the PowerSync command line. PowerSync can handle basic data integration scenarios using an ELT strategy (Extract, 
Load, THEN Transform). The following data integration features are supported:
 - Copy a table or the results of a query into a new target database table.
 - Support a variety of sources and targets. For instance, can copy from CSV files to MySQL, or SQL to SQLDW.
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
 - Provider Model: The primary components driving PowerSync are based on a provider model, which can be extended with new storage platforms. Each provider 
   defines the common interface all providers must support.
 - Provider Configuration: The set of configurations defined and used by the different provider components (i.e. Source, Target, Manifest, Log), and can be set via command line, manifest, or both.
 - Package Configuration: The collection of customizations (scripts, manifests, etc) created and managed by client code.

Manifests are the workhorse of the process. Manifests identify each and every data feed, as well as provider configurations allowing each feed to be 
customized. The provider configuration passed into the command-line is overlayed with configuration retrieved from the manifest (must include namespace 
i.e. SourceTableName instead of just TableName). PowerSync also supports writebacks to the manifest itself. This is useful for tracking runtime 
information like the last incremental extraction value (for incremental loads), the last run date/time, or count of extracted records. Operations are also 
logged to a file.

Evens execute in the following order:
 1) Prepare (Source and Target)
 2) Extract (Source)
 3) Load (Target)
 4) Transform (Target)

Client provided scripts are used in each event to support customization. Each script is defined in separate .SQL files and (optionally) 
passed into PowerSync. PowerSync attempts to pass every field from the provider configuration into each script using SQMCMD :setvar syntax, and also applies 
SQLCMD variables that only exist in the script so that the script has no SQLCMD syntax prior to execution.

.EXAMPLE
. PowerSync `
    -Manifest @{
        ConnectionString = "PSProvider=TextManifestProvider;Data Source=C:\Temp\Package\Manifest.csv;Header=True;Format=CSV"
    } `
    -Log @{
        ConnectionString = "PSProvider=TextLogProvider;Data Source=C:\Temp\Log.csv;Header=True;Format=CSV"
    } `
    -Source @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=C:\Temp\PowerSyncTestDB.mdf;";
        PrepareScript = "C:\Temp\Package\PrepareSource.sql";
        ExtractScript = "C:\Temp\Package\Extract.sql";
        Timeout = 3600;
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;AttachDbFileName=C:\Temp\PowerSyncTestDB.mdf;";
        PrepareScript = "C:\Temp\Package\PrepareTarget.sql";
        TransformScript = "C:\Temp\Package\Transform.sql";
        AutoIndex = $true;
        AutoCreate = $true;
        Overwrite = $true;
        BatchSize = 10000;
    }

.NOTES
https://github.com/Key2Consulting/PowerSync/
#>

# Command-line Parameters
param
(
    [Parameter(HelpMessage = "Manifest configuration information.", Mandatory = $false)]
    [hashtable] $Manifest,
    [Parameter(HelpMessage = "Log configuration information.", Mandatory = $false)]
    [hashtable] $Log,
    [Parameter(HelpMessage = "Source configuration information.", Mandatory = $false)]
    [hashtable] $Source,
    [Parameter(HelpMessage = "Target configuration information.", Mandatory = $false)]
    [hashtable] $Target,
    [Parameter(HelpMessage = "Scripts configuration information.", Mandatory = $false)]
    [hashtable] $Scripts
)

# Module Initialization
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


[string]$Test = $PSScriptRoot

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
    # Create Log Provider
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
            
            # Caller sets  default configuration on the command line, but the manifest can
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
            $pSource.Close()
            $pTarget.Close()
        }
    }
}
catch {
    $pLog.WriteException($_.exception, $true)
}

$pLog.WriteInformation("PowerSync-Manifest Completed in $($stopWatch.Elapsed.TotalSeconds) seconds.")
$pLog.EndLog()