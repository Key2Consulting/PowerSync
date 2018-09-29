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
            $logs = [System.Collections.ArrayList]::new()
            if (-not $Type -or $Type -eq 'Debug' -or $Type -eq 'Information' -or $Type -eq 'Verbose') {
                $logs.AddRange($this.FindEntity('MessageLog', 'Message', $Search, $true))
                $logs.AddRange($this.FindEntity('MessageLog', 'ActivityID', $Search, $false))
            }
            if (-not $Type -or $Type -eq 'Error') {
                $logs.AddRange($this.FindEntity('ErrorLog', 'Message', $Search, $true))
                $logs.AddRange($this.FindEntity('ErrorLog', 'Exception', $Search, $true))
                $logs.AddRange($this.FindEntity('ErrorLog', 'StackTrace', $Search, $true))
                $logs.AddRange($this.FindEntity('ErrorLog', 'ActivityID', $Search, $false))
            }
            if (-not $Type -or $Type -eq 'Variable') {
                $logs.AddRange($this.FindEntity('VariableLog', 'VariableName', $Search, $true))
                $logs.AddRange($this.FindEntity('VariableLog', 'ActivityID', $Search, $false))
            }
            if (-not $Type -or $Type -eq 'Query') {
                $logs.AddRange($this.FindEntity('QueryLog', 'Query', $Search, $true))
                $logs.AddRange($this.FindEntity('QueryLog', 'ActivityID', $Search, $false))
            }
            
            # If the caller wants to filter on log type, apply that here in addition to above since some logs use
            # shared storage.
            if ($Type) {
                $typeFiltered = $logs | Where-Object {$_.Type -eq $Type}
            }
            else {
                $typeFiltered = $logs
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