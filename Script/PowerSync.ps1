<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Executes an extraction query against a source, and copies the results into a new table on the destination. This command only supports full extractions, 
but it will publish in a transactionally consistent manner (i.e. does not drop then recreate, but rather stages and swaps).
.EXAMPLE
TODO
.NOTES
https://github.com/Key2Consulting/PowerSync/
#>

# Command Parameters
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
. "$PSScriptRoot\Provider\Data\DataProvider.ps1"
. "$PSScriptRoot\Provider\Data\MSSQLDataProvider.ps1"

# A data factory to create the correct Provider implementation based on inspecting the ConnectionString and Type
function New-Provider([string] $Type, [hashtable] $Configuration, [string] $Namespace = '') {
    # The provider instance
    $provider = $null
    
    # Parse connection string
    $sb = New-Object System.Data.Common.DbConnectionStringBuilder
    $sb.set_ConnectionString($Configuration."${Namespace}ConnectionString")
    
    # LogProvider
    if ($Type -eq "Log") {
        if ($sb.ContainsKey('Provider') -eq $false) {
            $provider = New-Object MSSQLLogProvider($Namespace, $Configuration)
        }
        elseif ($sb.'Provider' -eq "PSText") {
            $provider = New-Object TextLogProvider($Namespace, $Configuration)
        }
    }
    # ManifestProvider
    elseif ($Type -eq "Manifest") {
        if ($sb.ContainsKey('Provider') -eq $false) {
            $provider = New-Object MSSQLManifestProvider($Namespace, $Configuration)
        }
        elseif ($sb.'Provider' -eq "PSText") {
            $provider = New-Object TextManifestProvider($Namespace, $Configuration)
        }
    }
    # DataProvider
    elseif ($Type -eq "Data") {
        if ($sb.ContainsKey('Provider') -eq $false) {
            $provider = New-Object MSSQLDataProvider($Namespace, $Configuration)
        }
    }

    if ($provider -eq $null) {
        throw "No Provider available for connection string"
    }

    return $provider
}

# Process Manifest
try {
    # Create Log Provider
    $pLog = New-Provider "Log" $Log
    $pLog.BeginLog()

    # Create Manifest Provider
    $pManifest = New-Provider "Manifest" $Manifest

    $pLog.WriteInformation("PowerSync Started")
    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Process the manifest file
    $manifestContent = $pManifest.ReadManifest()
    
    foreach ($item in $manifestContent) {
        try {
            $pLog.BeginLog()
            $stopWatchStep = [System.Diagnostics.Stopwatch]::StartNew()
            # Create connections to source and destination for the current manifest item
            #
            # Caller can set provider default configuration on the command line, but the manifest can optionally
            # override those settings.
            $sourceConfig = $pManifest.OverrideManifest("Source", $Source, "", $item)
            $targetConfig = $pManifest.OverrideManifest("Target", $Target, "", $item)
            
            $pSource = New-Provider "Data" $sourceConfig 'Source'
            $pTarget = New-Provider "Data" $targetConfig 'Target'

            # Prepare Source
            $writeback = $pSource.Prepare()
            $pManifest.WriteManifestItem($writeback)
            
            # Prepare Target
            $writeback = $pTarget.Prepare()
            $pManifest.WriteManifestItem($writeback)

            # Extract and Load (writeback not supported)
            $reader = $pSource.Extract()
            $pTarget.Load($reader)

            # Transform
            $writeback = $pTarget.Transform()
            $pManifest.WriteManifestItem($writeback)

            # Final logging. Note that the only field we know this item has is the RuntimeID. However, that's a sequential
            # number and not very informative. So we'll search the columns and attempt to identify something useful to display.
            $possibleFields = $item.Keys.Where({$_.Contains('Table')})
            if ($possibleFields.Count -gt 0) {
                $friendlyIdentifier = $item[$possibleFields[$possibleFields.Count - 1]]      # publish table names tend to be listed last
                $friendlyIdentifier = "($friendlyIdentifier)"
            }
            $pLog.WriteInformation("Completed Processing item $($item.RuntimeID) $friendlyIdentifier in $($stopWatchStep.Elapsed.TotalSeconds) seconds.")
            $pLog.EndLog()
        }
        catch {
            $pLog.WriteException($_.exception, $false)
        }
        finally {
            # TODO: HOW SHOULD WE CLEAN THESE UP?
            #$pSource.Close()
            #$pTarget.Close()
        }
    }
}
catch {
    $pLog.WriteException($_.exception, $true)
}

$pLog.WriteInformation("PowerSync-Manifest Completed in $($stopWatch.Elapsed.TotalSeconds)")
$pLog.EndLog()