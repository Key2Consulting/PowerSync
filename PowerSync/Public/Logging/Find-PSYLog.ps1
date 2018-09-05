<#
.SYNOPSIS
Returns a list of logs across all log types matching a given criteria.

.DESCRIPTION
This function will search all PowerSync logs and return the ones which meet the given criteria. Supports wildcards. Searches key attributes of each log.

.PARAMETER Type
Restricts search to a specific log type. The available types are:
 - InformationLog
 - VerboseLog
 - DebugLog
 - ErrorLog
 - VariableLog
 - QueryLog
 - DebugLog
 
 .PARAMETER Search
The term to search for. Supports wildcards (i.e. *, ?).

.EXAMPLE
Find-PSYLog -Type 'QueryLog' -Search 'MySchema.MyTable'

.EXAMPLE
Find-PSYLog -Type 'ErrorLog' -Search 'MySchema.MyTable'

.NOTES
See https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/string-wildcard-syntax for information on wildcards.
 #>
function Find-PSYLog {
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "Restricts search to a specific log type.", Mandatory = $false)]
        [string] $Type,
        [Parameter(HelpMessage = "The term to search for. Supports wildcards (i.e. *, ?).", Mandatory = $false)]
        [string] $Search
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository

        # Search all logs in the repository and return any that match
        return $repo.CriticalSection({
            if (-not $Type -or $Type -eq 'Debug' -or $Type -eq 'Information' -or $Type -eq 'Verbose') {
                $messageLog = $this.FindEntity('MessageLog', 'Message', $Search, $true)
            }
            if (-not $Type -or $Type -eq 'Error') {
                $errorLog1 = $this.FindEntity('ErrorLog', 'Message', $Search, $true)
                $errorLog2 = $this.FindEntity('ErrorLog', 'Exception', $Search, $true)
                $errorLog3 = $this.FindEntity('ErrorLog', 'StackTrace', $Search, $true)
            }
            if (-not $Type -or $Type -eq 'Variable') {
                $variableLog = $this.FindEntity('VariableLog', 'VariableName', $Search, $true)
            }
            if (-not $Type -or $Type -eq 'Query') {
                $queryLog = $this.FindEntity('QueryLog', 'Query', $Search, $true)
            }

            $allLogs = $messageLog + $errorLog1 + $errorLog2 + $errorLog3 + $variableLog + $queryLog
            
            # Some log entries can be found multiple times, remove the duplicates
            # TODO: CAN'T USE SELECT-OBJECT -UNQIUE AS IT DOESN'T WORK WITH OBJECT TYPES. INSTEAD, BUILD A NEW ARRAY AND ONLY ADD UNIQUE ITEMS TO IT.
            
            # If the caller wants to filter on log type, apply that here in addition to above since some logs use
            # shared storage.
            if ($Type) {
                $allLogs | Where-Object {$_.Type -eq $Type}
            }
            else {
                $allLogs
            }
        })
    }
    catch {
        Write-PSYErrorLog $_ "Error in Find-PSYLog."
    }
}