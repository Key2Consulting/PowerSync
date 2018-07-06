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

# Global Parameters
    $global:LogFileName = $null

# Logging
function Write-Log(
    [Parameter(HelpMessage = "Logging Message", Mandatory = $true)]
        [string] $Message,
    [Parameter(HelpMessage = "Type of Message (Info, Error, Warning...)", Mandatory = $false)]   
        [string]$MessageType = "Information", 
    [Parameter(HelpMessage = "Severity number.  Default = 0 (low)", Mandatory = $false)]   
        [int]$Severity = 0
        )
{
    # Set Logging File Name
    If (!$global:LogFileName) {
        $DateName = Get-Date -format "yyyyMMdd_HHmmssffff" 
        $NewID  = Get-UniqueID -MaxLength 5
        $global:LogFileName = "PowerSyncLog_" + $DateName + "_" + $NewID + ".csv"
    }

    #Output log messaage
    Write-Host (Get-Date) + "$MessageType($Severity): $Message" 

    #Build log data
     $line = [pscustomobject]@{
        'DateTime' = (Get-Date)
        'MessageType' = $MessageType
        'Message' = $Message
        'Severity' = $Severity
    }

    
    $LogFilePath = "$(Get-Location)\Logs"

    # Create Logs folder, if it doesn't exist
    If(!(Test-Path -Path $LogFilePath)) {
          New-Item -ItemType directory -Path $LogFilePath
    }
    
    $LogFilePath = "$LogFilePath\$global:LogFileName"

    ## Ensure that $LogFilePath is set to a global variable at the top of script
    $line | Export-Csv -Path $LogFilePath -Append -NoTypeInformation
}


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
        $dst.BulkCopyData($reader, $tableName)
        $reader.Close()
        
        # If AutoIndex, create index now
        $dst.CreateAutoIndex($tableName)
        
        # Rename hash table to LoadTableName
        $dst.RenameTable($tableName, $LoadTableName, $Overwrite)
    }
    catch {
        [exception]$ex = $_.exception
        Write-Log $ex "Error"

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
    if ($BaseToken) {
        $ReturnValue = $BaseToken + (New-Guid).ToString().Replace("-", "")
    }
    else {
        $ReturnValue = (New-Guid).ToString().Replace("-", "")
    }   

    If ($MaxLength){
        $ReturnValue = $ReturnValue.Substring(0,$MaxLength)
    }
    return $ReturnValue
}