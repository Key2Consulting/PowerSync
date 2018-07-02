<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Executes an extraction query against a source, and copies the results into a new table on the destination. This command only supports full extractions, 
but it will publish in a transactionally consistent manner (i.e. does not drop then recreate, but rather stages and swaps).
.EXAMPLE
TODO
#>

# Command Parameters
param
(
	[Parameter(HelpMessage="Connection string of the data source.", Mandatory=$true)]
    [string] $SrcConnectionString,
	[Parameter(HelpMessage="Connection string of the data destination.", Mandatory=$true)]
    [string] $DstConnectionString,
	[Parameter(HelpMessage="The extraction query.", Mandatory=$true)]
    [string] $ExtractQuery,
	[Parameter(HelpMessage="The desired name of the target object in the destination. Use 'Schema.Table' format.", Mandatory=$true)]
    [string] $DstTableName,
	[Parameter(HelpMessage="Optionally overwrite target table if already exists.", Mandatory=$false)]
    [switch] $Overwrite,
	[Parameter(HelpMessage="Optionally create Clustered Columnstore Index automatically.", Mandatory=$false)]
    [switch] $AutoIndex
)

# Module Dependencies
. "$PSScriptRoot\DataProvider\DataProvider.ps1"
. "$PSScriptRoot\DataProvider\MSSQLProvider.ps1"

# A data factory to create the correct DataProvider implementation based on inspecting the Connection String
function New-DataProvider($ConnectionString)
{
    $sb = New-Object System.Data.Common.DbConnectionStringBuilder
    $sb.set_ConnectionString($ConnectionString)
    if ($sb.'Provider' -eq $null -and $sb.'Server' -ne $null) {
        return New-Object MSSQLProvider($ConnectionString)
    } else {
        return New-Object MSSQLProvider($ConnectionString)
    }
}

# Coordinates the copy operation of a single table
function Copy-Data
{
    param
    (
        [Parameter(HelpMessage="Connection string of the data source.", Mandatory=$true)]
        [string] $SrcConnectionString,
        [Parameter(HelpMessage="Connection string of the data destination.", Mandatory=$true)]
        [string] $DstConnectionString,
        [Parameter(HelpMessage="The extraction query.", Mandatory=$true)]
        [string] $ExtractQuery,
        [Parameter(HelpMessage="The desired name of the target object in the destination. Use 'Schema.Table' format.", Mandatory=$true)]
        [string] $DstTableName,
        [Parameter(HelpMessage="Optionally overwrite target table if already exists.", Mandatory=$false)]
        [switch] $Overwrite,
        [Parameter(HelpMessage="Optionally create Clustered Columnstore Index automatically.", Mandatory=$false)]
        [switch] $AutoIndex
    )

    try
    {
        # Establish source and destination data providers
        $src = New-DataProvider $SrcConnectionString
        $dst = New-DataProvider $DstConnectionString
        
        # Generate create table on destination (as hash table)
        $tableHash = (New-Guid).ToString().Replace("-", "")
        $schema = $src.GetQuerySchema($ExtractQuery)
        $tableName = "$DstTableName$tableHash"
        $createTableScript = $dst.ScriptCreateTable($tableName, $schema)
        $dst.ExecScript($createTableScript)
        

        # Bulk copy data to destination
        $reader = $src.ExecReader($ExtractQuery)
        $src.BulkCopyData($reader, $tableName)
        $reader.Close()
        
        # If AutoIndex, create index now
        $dst.CreateAutoIndex($tableName)
        
        # Rename hash table to DstTable
        $dst.RenameTable($tableName, $DstTableName, $Overwrite)
    }
    catch
    {
        [exception]$ex = $_.exception

        # Clean up the hashed table (if exists)
        if ($dst -ne $null -and $tableName -ne $null)
        {
            $dst.DropTable($tableName)
        }
    }
    finally
    {
        $src.Close()
        $dst.Close()
    }
}

# Invoke Copy-Data command given the command line parameters
Copy-Data $SrcConnectionString $DstConnectionString $ExtractQuery $DstTableName -Overwrite:$Overwrite -AutoIndex:$AutoIndex