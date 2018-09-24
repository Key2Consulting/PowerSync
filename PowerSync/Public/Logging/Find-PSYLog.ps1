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
        [string] $Search,
        [Parameter(HelpMessage = "Filters logs dated later than StartDate.", Mandatory = $false)]
        [datetime] $StartDate,
        [Parameter(HelpMessage = "Filters logs dated earlier than EndDate.", Mandatory = $false)]
        [datetime] $EndDate
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

            $combinedLogs = $messageLog + $errorLog1 + $errorLog2 + $errorLog3 + $variableLog + $queryLog
            
            # If the caller wants to filter on log type, apply that here in addition to above since some logs use
            # shared storage.
            if ($Type) {
                $typeFiltered = $combinedLogs | Where-Object {$_.Type -eq $Type}
            }
            else {
                $typeFiltered = $combinedLogs
            }

            # If the caller wants to filter on a date range, use the CreatedDateTime field which should
            # exist for every log type.
            $dateFiltered = $typeFiltered | Where-Object {
                ((ConvertFrom-PSYCompatibleType -InputObject $_.CreatedDateTime -Type 'datetime') -ge $StartDate -or -not $StartDate) `
                -and ((ConvertFrom-PSYCompatibleType -InputObject $_.CreatedDateTime -Type 'datetime') -le $EndDate -or -not $EndDate)
            }
            
            # Some log entries can be found multiple times, so remove the duplicates.
            $uniqueLogs = New-Object System.Collections.ArrayList
            foreach ($log in $dateFiltered) {
                $existing = $uniqueLogs | Where-Object { $_.ID -eq $log.ID }
                if (-not $existing) {
                    [void] $uniqueLogs.Add($log)
                }
            }
            
            $uniqueLogs
        })
    }
    catch {
        Write-PSYErrorLog $_
    }
}