<#
.SYNOPSIS
Gets a PowerSync connection.

.DESCRIPTION
Retrieves a connection from the currently connected repository. See Set-PSYConnection for more information.

.PARAMETER Name
The name of the connection.

.EXAMPLE
Get-PSYConnection -Name 'MySource'
#>
function Get-PSYConnection {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    try {
        $repo = New-FactoryObject -Repository

        # Get the from the repository.
        $existing = $repo.FindEntity('Connection', 'Name', $Name)
        if ($existing.Count -eq 0) {
            throw "No connection entry found with name '$Name'."
        }
        else {
            return $existing[0]
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}