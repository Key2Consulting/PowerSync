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
Search-PSYLog -Type 'QueryLog' -Search 'MySchema.MyTable'

.EXAMPLE
Search-PSYLog -Type 'ErrorLog' -Search 'MySchema.MyTable'

.NOTES
See https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/string-wildcard-syntax for information on wildcards.
 #>
function Search-PSYLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $Type,
        [Parameter(Mandatory = $false)]
        [string[]] $SearchTerms,
        [Parameter(Mandatory = $false)]
        [datetime] $StartDate,
        [Parameter(Mandatory = $false)]
        [datetime] $EndDate
    )

    try {
        $repo = New-FactoryObject -Repository
        return $repo.SearchLogs($SearchTerms, $Wildcards)
    }
    catch {
        Write-PSYErrorLog $_
    }
}