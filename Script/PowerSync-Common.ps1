<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Common functionality across all PowerSync scripts. This script is not intended to be used from the command-line.
.NOTES
https://github.com/Key2Consulting/PowerSync/
#>

# Module Dependencies
. "$PSScriptRoot\DataProvider\DataProvider.ps1"
. "$PSScriptRoot\DataProvider\MSSQLProvider.ps1"

# Takes a System.Data.DataTable and return an Array of pscustomobject
function Load-TableIntoArray ([System.Data.DataTable]$table){
    $array =  [System.Collections.ArrayList]@()

    # Loop through each row in the datatable
    foreach ($dr in $table.Rows)
    {
        # Create a hash for the row
        $hashRow = @{}
      
        foreach ($dc in $table.Columns)
        {    
            $ColumnName = $dc.ColumnName.ToString().Trim()
            $ColumnValue = $dr[$dc.ToString().Trim()]

            # Add each column into a Hash
            $hashRow.Add($ColumnName,$ColumnValue)
        }

        # Conver the Hash into a pscustomobject
        $myObject = [pscustomobject]$hashRow

        # Add the pscustomobject to the Array List
        $array.Add($myObject)
     }
    
    # Return the ArrayList as an Array
    return $array.ToArray()    
}

# Coordinates the copy operation of a single table
function Copy-Data {
    param
    (
        [Parameter(HelpMessage = "Connection string of the data source.", Mandatory = $true)]
        [string] $SrcConnectionString,
        [Parameter(HelpMessage = "Connection string of the data destination.", Mandatory = $true)]
        [string] $DstConnectionString,
        [Parameter(HelpMessage = "The extraction query.", Mandatory = $true)]
        [string] $ExtractQuery,
        [Parameter(HelpMessage = "The desired name of the target object in the destination. Use 'Schema.Table' format.", Mandatory = $true)]
        [string] $LoadTableName,
        [Parameter(HelpMessage = "Optionally overwrite target table if already exists.", Mandatory = $false)]
        [switch] $Overwrite,
        [Parameter(HelpMessage = "Optionally create Clustered Columnstore Index automatically.", Mandatory = $false)]
        [switch] $AutoIndex
    )

    try {
        # Establish source and destination data providers
        $src = New-DataProvider $SrcConnectionString
        $dst = New-DataProvider $DstConnectionString
        
        # Generate create table on destination (with GUID)
        $schema = $src.GetQuerySchema($ExtractQuery)
        $tableName = Get-UniqueID($LoadTableName).Trim()
        $createTableScript = $dst.ScriptCreateTable($tableName, $schema)
        $dst.ExecNonQuery($createTableScript)
        
        # Bulk copy data to destination
        $reader = $src.ExecReader($ExtractQuery)
        $dst.BulkCopyData($reader, $tableName)
        $reader.Close()
        
        # If AutoIndex, create index now
        $dst.CreateAutoIndex($tableName)
        
        # Rename hash table to LoadTableName
        $dst.RenameTable($tableName, $LoadTableName, $Overwrite)
    }
    catch {
        [exception]$ex = $_.exception
        Write-Log $ex "Error" 9

        # Clean up the hashed table (if exists)
        if ($dst -ne $null -and $tableName -ne $null) {
            $dst.DropTable($tableName)
            Write-Log "Cleaned up temp table $tableName"
        }
        throw $ex
    }
    finally {
        $src.Close()
        $dst.Close()
    }
}

function Get-UniqueID(
    [string]$BaseToken
    ,[int]$MaxLength) 
{    
    $guid = (New-Guid).ToString().Replace("-", "")

    # If MaxLength is passed in, limit the GUID to MaxLength characters
    If ($MaxLength){
        $guid = $guid.Substring(0,$MaxLength)
    }
    
    # If BaseToken is passed in, add the GUID to the end of the BaseToken
    if ($BaseToken) {
        $ReturnValue = $BaseToken + "_" + $guid 
    }
    else {
        $ReturnValue = $guid
    }   
        
    return $ReturnValue
}