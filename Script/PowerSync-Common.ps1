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
    $global:LogFilePath = $null
    $global:LogID = $null
    $global:LogExecutionID = $null
    $global:LoggingConnectionString = $null
    $global:LogStatus = $null


# Set Script Path
#TODO: Move to Common Root folder??
    $ScriptPath = "$(Get-Location)" 

# Logging
function Write-Log(
    [Parameter(HelpMessage = "Logging Message", Mandatory = $true)]
        [string] $Message,
    [Parameter(HelpMessage = "Type of Message (Info, Error, Warning...)", Mandatory = $false)]   
        [string]$MessageType = "Information", 
    [Parameter(HelpMessage = "Severity number.  Default = 0 (low)", Mandatory = $false)]   
        [int]$Severity = 0,
    [Parameter(HelpMessage = "Log file Name prefix.  Timestamp will be added after the Prefix", Mandatory = $false)]   
        [string]$LogNamePrefix = "PowerSyncLog",
    [Parameter(HelpMessage = "Path to store log files", Mandatory = $false)]   
        [string]$LogPath,
    [Parameter(HelpMessage = "Connection String for Logging", Mandatory = $false)]   
        [string]$LogConnectionString


        )
{
    # Output log messaage
    Write-Host (Get-Date) "$MessageType($Severity): $Message" 

    # Set Log ID.  This GUID will be used to identify the execution and all tasks that are part of the execution
    If (!$global:LogID) {
        $global:LogID = (New-Guid).ToString()
    }

    # Use SQL Logging if $LogConnectionString is provided or has already been provided ($global:LogExecutionID is set)
    # Should also be -MessageType "LoggingBegin"
    If ($LogConnectionString -or $global:LogExecutionID) {
        
        $Message = $Message.Replace("'","''")

        If (!$global:LogStatus) {
            $global:LogStatus = "In Process"
        }

        # Set $global:LoggingConnectionString
        If (!$global:LoggingConnectionString){
            $global:LoggingConnectionString = $LogConnectionString
        }
        
        # If the LogExecutionID has not be set yet, Initial the logging
        If(!$global:LogExecutionID) {
            $LogBegin = @{}


    #TODO: Move Parameter LogTableName
            $LogBegin.Add("LogTableName", "[Log].[Execution]")
            $LogBegin.Add("Message", "$Message")
            $LogBegin.Add("LoggingGUID", "$global:LogID")

            $LoggingBeginScript = "$ScriptPath\LoggingBegin.sql"
           
   #TODO: Figure out why Compile-Script version of $SqlQuery1 doesn't work by hard coding it does.
           $SqlQuery1 = Compile-Script $LoggingBeginScript $LogBegin
                
           $SqlQuery = @"
                INSERT INTO [Log].[Execution] (LogID,ScriptName,StartDateTime,Status) VALUES('$global:LogID','$Message',GETDATE(),'$global:LogStatus') 
                SELECT @@IDENTITY AS LogExecutionID
"@

Write-Host $SqlQuery1
Write-Host $SqlQuery

            $ServerAConnection = new-object system.data.SqlClient.SqlConnection($global:LoggingConnectionString);
    
            $dataSet = new-object System.Data.DataSet "LogExecution"

            # Create a DataAdapter to populate the DataSet 
            $dataAdapter = new-object System.Data.SqlClient.SqlDataAdapter ($SqlQuery, $ServerAConnection)
            $dataAdapter.Fill($dataSet) 

            #Close the connection as soon as you are done with it
            $ServerAConnection.Close()
            $dataTable = new-object System.Data.DataTable
            $dataTable = $dataSet.Tables[0]

            $global:LogExecutionID =  $dataTable.Rows[0]["LogExecutionID"]


        }

        # If the $global:LogExecutionID has been set, log into the Log.ExecutionDetails
                
        # If the Message Type is an Error.  Set the Global Log status to Error.  This will be used to on Logging End
        If ($MessageType -eq "Error"){
            $global:LogStatus = "Error"
        }


        $SqlQuery = @"
            INSERT INTO [Log].[ExecutionDetails]([LogExecutionID],[LogDateTime],MessageType,MessageText,Severity)
            VALUES($global:LogExecutionID, GETDATE(), '$MessageType', '$Message', $Severity)
"@

        $ServerAConnection = new-object system.data.SqlClient.SqlConnection($global:LoggingConnectionString);
    
        $dataSet = new-object System.Data.DataSet "LogExecution"

        # Create a DataAdapter to populate the DataSet 
        $dataAdapter = new-object System.Data.SqlClient.SqlDataAdapter ($SqlQuery, $ServerAConnection)
        $dataAdapter.Fill($dataSet) 

        #Close the connection as soon as you are done with it
        $ServerAConnection.Close()         
    
        # If MessageType = LoggingEnd
        If ($MessageType -eq "LoggingEnd") {

            If ($global:LogStatus -eq "Error"){
                $MessageType = "Failed"
            }
            else {
                $MessageType = "Completed"
            }

            $SqlQuery = @"
                UPDATE [Log].[Execution] SET [EndDateTime] = GETDATE(), [Status] = '$MessageType' WHERE LogExecutionID = $global:LogExecutionID
"@

            $ServerAConnection = new-object system.data.SqlClient.SqlConnection($global:LoggingConnectionString);
    
            $dataSet = new-object System.Data.DataSet "LogExecutionEnd"

            # Create a DataAdapter to populate the DataSet 
            $dataAdapter = new-object System.Data.SqlClient.SqlDataAdapter ($SqlQuery, $ServerAConnection)
            $dataAdapter.Fill($dataSet) 

            #Close the connection as soon as you are done with it
            $ServerAConnection.Close()         
        }

        
    }


    # else not using SQL logging, log to CSV
    else {
        #Build log data
         $line = [pscustomobject]@{
            'DateTime' = (Get-Date)
            'MessageType' = $MessageType
            'Message' = $Message
            'Severity' = $Severity
        }

        # Set Logging File Name
        If (!$global:LogFileName) {
            $DateName = Get-Date -format "yyyyMMdd_HHmmssffff" 
            $NewID  = Get-UniqueID -MaxLength 5    
            $global:LogFileName = $LogNamePrefix + "_" + $DateName + "_" + $NewID + ".csv"
        }

        # Set Logging File Path.  This will be used for all logging unless it is set again
        If (!$global:LogFilePath) {
             # If LogFilePath is not specified, set it to the default
            If (!$LogPath) {
                $LogPath = "$(Get-Location)\Logs"
            }

            $global:LogFilePath = $LogPath

             # Create Logs folder, if it doesn't exist
            If(!(Test-Path -Path $global:LogFilePath)) {
                    New-Item -ItemType directory -Path $global:LogFilePath
            }
        }
      
    
        $LogFilePath = "$global:LogFilePath\$global:LogFileName"

        ## Ensure that $LogFilePath is set to a global variable at the top of script
        $line | Export-Csv -Path $LogFilePath -Append -NoTypeInformation
    }
}



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