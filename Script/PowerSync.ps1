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
    [Parameter(HelpMessage = "Connection string of the data source.", Mandatory = $true)]
    [string] $SrcConnectionString,
    [Parameter(HelpMessage = "Connection string of the data destination.", Mandatory = $true)]
    [string] $DstConnectionString,
    [Parameter(HelpMessage = "The extraction query.", Mandatory = $true)]
    [string] $ExtractQuery,
    [Parameter(HelpMessage = "The desired name of the target object in the destination. Use 'Schema.Table' format for data providers which support schemas.", Mandatory = $true)]
    [string] $LoadTableName,
    [Parameter(HelpMessage = "Optionally overwrite target table if already exists.", Mandatory = $false)]
    [switch] $Overwrite,
    [Parameter(HelpMessage = "Optionally create index automatically (columnstore preferred).", Mandatory = $false)]
    [switch] $AutoIndex
)

# Module Dependencies
. "$PSScriptRoot\PowerSync-Common.ps1"

# Invoke Copy-Data command with the given parameters
Write-Log "PowerSync-Manifest Started"
$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
Copy-Data $SrcConnectionString $DstConnectionString $ExtractQuery $LoadTableName -Overwrite:$Overwrite -AutoIndex:$AutoIndex
Write-Log "PowerSync-Manifest Completed in $($stopWatch.Elapsed.TotalSeconds)"