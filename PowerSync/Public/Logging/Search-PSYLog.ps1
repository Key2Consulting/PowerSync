<#
.SYNOPSIS
Returns a list of logs across all log types matching a given criteria.

.DESCRIPTION
This function will search all PowerSync logs and return the ones which meet the given criteria. Supports wildcards. Searches key attributes of each log.

.PARAMETER Attribute
Restricts search to a specific attribute e.g. ActivityID

 .PARAMETER Search
The term to search for. Supports wildcards (i.e. *, ?).

.EXAMPLE
Search-PSYLog -Search 'MySchema.MyTable'

.NOTES
See https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/string-wildcard-syntax for information on wildcards.
 #>
 function Search-PSYLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $Attribute,
        [Parameter(Mandatory = $false)]
        [string[]] $Search,
        [Parameter(Mandatory = $false)]
        [switch] $Wildcards,
        [Parameter(Mandatory = $false)]
        [datetime] $StartDate,
        [Parameter(Mandatory = $false)]
        [datetime] $EndDate
    )

    try {
        # TODO: IMPLEMENT START/END DATE FILTERS
        $repo = New-FactoryObject -Repository
        return $repo.SearchLogs($Attribute, $Search, $Wildcards)
    }
    catch {
        Write-PSYErrorLog $_
    }
}