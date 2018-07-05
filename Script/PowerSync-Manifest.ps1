<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Runs PowerSync for a collection of items defined in a manifest file (CSV format), and performs an Extract, Load, Transform for each item. The TSQL used
at each stage is defined in separate .SQL files and (optionally) passed into PowerSync. PowerSync attempts to pass every field in the manifest into each 
TSQL script using SQMCMD :setvar syntax, and also applies SQLCMD variables that only exist in the script.

PowerSync-Manifest also supports writebacks to the manifest file itself. This is useful for tracking runtime information like the last incremental
extraction value (for incremental loads), the last run date/time, or count of extracted records. Operations are also logged to a file.

Scripts are called in the following order:
 1) Prepare (supports writeback)
 2) Extract
 3) Transform (supports writeback)
 4) Publish (called once for entire process)

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
    [Parameter(HelpMessage = "Path to the manifest file.", Mandatory = $true)]
    [string] $ManifestPath,
    [Parameter(HelpMessage = "Path to the prepare script.", Mandatory = $false)]
    [string] $PrepareScriptPath,
    [Parameter(HelpMessage = "Path to the extract script.", Mandatory = $true)]
    [string] $ExtractScriptPath,
    [Parameter(HelpMessage = "Path to the transform script.", Mandatory = $false)]
    [string] $TransformScriptPath,
    [Parameter(HelpMessage = "Path to the publish script.", Mandatory = $false)]
    [string] $PublishScriptPath,
    [Parameter(HelpMessage = "Optionally overwrite target table if already exists.", Mandatory = $false)]
    [switch] $Overwrite,
    [Parameter(HelpMessage = "Optionally create index automatically (columnstore preferred).", Mandatory = $false)]
    [switch] $AutoIndex,
    [Parameter(HelpMessage = "The designated output log file (defaults to current folder).", Mandatory = $false)]
    [string] $LogPath = "$(Get-Location)\Log.txt"    
)

# Module Dependencies
. "$PSScriptRoot\PowerSync-Common.ps1"

# Loads a TSQL script from disk, applies any SQLCMD variables passed in, and returns the compiled script.
function Compile-Script([string]$ScriptPath, [psobject]$Vars) {
    # Load the script into a variable
    $script = [IO.File]::ReadAllText($ScriptPath)
    # This regular expression is used to identify :setvar commands in the TSQL script, and uses capturing 
    # groups to separate the variable name from the value.
    $regex = ':setvar\s*([A-Za-z0-9]*)\s*"?([A-Za-z0-9 .]*)"?'
    # Find the next match, remove the :setvar line from the script, but also replace
    # any reference to it with the actual value. This eliminates any SQLCMD syntax from
    # the script prior to execution.
    do {
        $match = [regex]::Match($script, $regex)
        if ($match.Success) {
            $script = $script.Remove($match.Index, $match.Length)
            $name = $match.Groups[1]
            $value = $match.Groups[2]
            if ($Vars."$name") {
                $value = $Vars."$name"
            }
            $script = $script.Replace('$(' + $name + ')', $value)
        }
    } while ($match.Success)
    # if ($script.Length -eq 0) {
    #     throw "Script $ScriptPath was specified, but does not contain any TSQL logic."
    # }
    return $script
}

# Executes a TSQL script from disk given a set of SQLCMD parameters, and optionally applies writeback logic
# by updating $Vars with matching fields in the result set
function Exec-Script([DataProvider]$Provider, [string]$ScriptPath, [psobject]$Vars, [bool]$SupportWriteback) {
    if ($ScriptPath) {
        $query = Compile-Script $ScriptPath $Vars
        if ($SupportWriteback) {
            $reader = $Provider.ExecReader($query)
            $b = $reader.Read()
            for ($i=0;$i -lt $reader.FieldCount; $i++) {
                $col = $reader.GetName($i)
                if ([bool]($Vars.PSobject.Properties.name -match "$col")) {
                    $Vars."$col" = $reader[$col]
                }
            }
        }
        else {
            $Provider.ExecNonQuery($query)
        }
    }
}

# Saves changes back to the manifest (i.e. writeback)
function Save-Manifest([psobject]$Manifest, [string]$Path) {
    $Manifest | Export-Csv -Path $Path -NoTypeInformation
}

Write-Log "PowerSync-Manifest Started"
$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    # Process the manifest file
    $manifest = Import-Csv $ManifestPath
    foreach ($item in $manifest) {
        try {
            $stopWatchStep = [System.Diagnostics.Stopwatch]::StartNew()
            # Create connections to source and destination for the current manifest item
            $src = New-DataProvider $SrcConnectionString
            $dst = New-DataProvider $DstConnectionString

            # Load special fields from manifest file (required to exist by convention)
            $tableName = $item.'LoadTableName'
            Write-Log "Started Processing $tableName"

            # Prepare Phase
            Exec-Script $src $PrepareScriptPath $item $true
            Save-Manifest $manifest $ManifestPath

            # Extract Phase
            $extractQuery = Compile-Script $ExtractScriptPath $item
            Copy-Data $SrcConnectionString $DstConnectionString $extractQuery $tableName -Overwrite:$Overwrite -AutoIndex:$AutoIndex

            # Transform Phase
            Exec-Script $dst $TransformScriptPath  $item $true
            Save-Manifest $manifest $ManifestPath

            Write-Log "Completed Processing $tableName in $($stopWatchStep.Elapsed.TotalSeconds)"
        }
        catch {
            [exception]$ex = $_.exception
            Write-Log $ex "Error"
            throw $ex
        }
        finally {
            $src.Close()
            $dst.Close()
        }        
    }

    # Publish Phase
    Exec-Script $PublishScriptPath  $item $false
}
catch {
    Write-Log "The following error was encountered (processing will continue): $ex" "Error"
}

Write-Log "PowerSync-Manifest Completed in $($stopWatch.Elapsed.TotalSeconds)"