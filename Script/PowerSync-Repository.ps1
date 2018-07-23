<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Runs PowerSync for a collection of items defined in a SQL table, and performs an Extract, Load, Transform for each item. The TSQL used
at each stage is defined in separate .SQL files and (optionally) passed into PowerSync. PowerSync attempts to pass every field in the table into each 
TSQL script using SQMCMD :setvar syntax, and also applies SQLCMD variables that only exist in the script.

PowerSync-Manifest also supports writebacks to the database. This is useful for tracking runtime information like the last incremental
extraction value (for incremental loads), the last run date/time, or count of extracted records. Operations are also logged to logging table.

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


# TODO: SIMILAR TO MANIFEST MODE, EXCEPT USES A DATABASE FOR CONFIGURATION/LOGGING.


# Command Parameters
param
(
    [Parameter(HelpMessage = "Connection string of the data source.", Mandatory = $true)]
        [string] $SrcConnectionString,
    [Parameter(HelpMessage = "Connection string of the data destination.", Mandatory = $true)]
        [string] $DstConnectionString,
    [Parameter(HelpMessage = "Path to the manifest file.", Mandatory = $false)]
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
        [string] $LogPath = "$(Get-Location)\Logs",
    [Parameter(HelpMessage = "Log connection string.  If not provided, logging will be done to CSV file", Mandatory = $false)]
        [string] $LogConnectionString,  
    [Parameter(HelpMessage = "SQL Connection to Manifest Table", Mandatory = $false)]
        [string] $ManifestConnectionString,  
    [Parameter(HelpMessage = "Table name for the Manifest Table", Mandatory = $false)]
        [string] $ManifestTableName = 'dbo.Manifest', 
    [Parameter(HelpMessage = "Folder that contains Extract queries for the manifest", Mandatory = $false)]
        [string] $ManifestScriptLibrary
)

# Module Dependencies
. "$PSScriptRoot\PowerSync-Common.ps1"


# Saves changes back to the manifest (i.e. writeback)
function Save-Manifest([psobject]$Manifest, [string]$Path) {
    $Manifest | Export-Csv -Path $Path -NoTypeInformation
}


# Executes a TSQL script from disk given a set of SQLCMD parameters, and optionally applies writeback logic
# by updating $Vars with matching fields in the result set
function Exec-Script([DataProvider]$Provider, [string]$ScriptPath, [psobject]$Vars, [bool]$SupportWriteback) {
    if ($ScriptPath) {
        $query = Compile-Script $ScriptPath $Vars

        if ($query -ne "") {

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
}

# Initialize SQL Logging by passing the $LogConnectionString
Write-Log "PowerSync-Repository Started" -LogConnectionString $LogConnectionString -MessageType "LoggingBegin"
$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    # Process the manifest table
    
    $SqlQuery = "SELECT * FROM $ManifestTableName"
    $ServerAConnection = new-object system.data.SqlClient.SqlConnection($SrcConnectionString);
    
    $dataSet = new-object System.Data.DataSet "ManifestDataset"

    # Create a DataAdapter to populate the DataSet 
    $dataAdapter = new-object System.Data.SqlClient.SqlDataAdapter ($SqlQuery, $ServerAConnection)
    $dataAdapter.Fill($dataSet) 

    #Close the connection as soon as you are done with it
    $ServerAConnection.Close()
    $dataTable = new-object System.Data.DataTable
    $dataTable = $dataSet.Tables[0]


    $manifest = Load-TableIntoArray $dataTable
    
#TODO: FIgure out why Load-TableIntoArray contains the 0,1,2... at the beging of the array values.
   
       foreach ($item in $manifest) {
        # if LoadTableName is not a object in the array, go to the next item
        if (!$item.'LoadTableName') {continue}

        try {
            $stopWatchStep = [System.Diagnostics.Stopwatch]::StartNew()
            # Create connections to source and destination for the current manifest item
            $src = New-DataProvider $SrcConnectionString
            $dst = New-DataProvider $DstConnectionString

            # Load special fields from manifest file (required to exist by convention)
            $tableName = $item.'LoadTableName'.Trim()
            Write-Log "Started Processing $tableName"

    #TODO:  Fix  Exec-Script for Writeback. TO Writeback to SQL
    #TODO: Fix Save-Manifest
            # Prepare Phase
            Exec-Script $src $PrepareScriptPath $item $true
            #Save-Manifest $manifest $ManifestPath

            # Extract Phase
            $extractQuery = Compile-Script $ExtractScriptPath $item
    #TODO: Error in Copy-Data.
            Copy-Data $SrcConnectionString $DstConnectionString $extractQuery $tableName -Overwrite:$Overwrite -AutoIndex:$AutoIndex

            # Transform Phase
            Exec-Script $dst $TransformScriptPath  $item $true
            #Save-Manifest $manifest $ManifestPath

            Write-Log "Completed Processing $tableName in $($stopWatchStep.Elapsed.TotalSeconds)"
        }
        catch {
            [exception]$ex = $_.exception
            Write-Log $ex "Error" 9
            throw $ex
        }
        finally {
            $src.Close()
            $dst.Close()
        }        
    }

    # Publish Phase
    $dst = New-DataProvider $DstConnectionString
    Exec-Script $dst $PublishScriptPath  $item $false
}
catch {
    [exception]$ex = $_.exception
    Write-Log "The following error was encountered (processing will continue): $ex" "Error" 9 
}

Write-Log "PowerSync-Manifest Completed in $($stopWatch.Elapsed.TotalSeconds)" -MessageType "LoggingEnd"