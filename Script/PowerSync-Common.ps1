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

# A data factory to create the correct DataProvider implementation based on inspecting the Connection String
function New-DataProvider($ConnectionString) {
    $sb = New-Object System.Data.Common.DbConnectionStringBuilder
    $sb.set_ConnectionString($ConnectionString)
    if ($sb.'Provider' -eq $null -and $sb.'Server' -ne $null) {
        return New-Object MSSQLProvider($ConnectionString)
    }
    else {
        throw "No DataProvider available for connection string"
    }
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
        $tableName = Get-UniqueID($LoadTableName)
        $createTableScript = $dst.ScriptCreateTable($tableName, $schema)
        $dst.ExecNonQuery($createTableScript)
        
        # Bulk copy data to destination
        $reader = $src.ExecReader($ExtractQuery)
        $src.BulkCopyData($reader, $tableName)
        $reader.Close()
        
        # If AutoIndex, create index now
        $dst.CreateAutoIndex($tableName)
        
        # Rename hash table to LoadTableName
        $dst.RenameTable($tableName, $LoadTableName, $Overwrite)
    }
    catch {
        [exception]$ex = $_.exception

        # Clean up the hashed table (if exists)
        if ($dst -ne $null -and $tableName -ne $null) {
            $dst.DropTable($tableName)
        }
        throw $ex
    }
    finally {
        $src.Close()
        $dst.Close()
    }
}

function Get-UniqueID([string]$BaseToken) {
    if ($BaseToken) {
        return $BaseToken + (New-Guid).ToString().Replace("-", "")
    }
    else {
        return (New-Guid).ToString().Replace("-", "")
    }   
}