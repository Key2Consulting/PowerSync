<#
.SYNOPSIS
Removes a PowerSync connection from the connected repository.

.DESCRIPTION
Removes a connection from the currently connected repository. See Set-PSYConnection for more information.

.PARAMETER Name
The name of the connection.

.EXAMPLE
Remove-PSYConnection -Name 'MySource'
#>
function Remove-PSYConnection {
    param
    (
        [Parameter(Mandatory = $false)]
        [string] $Name
    )

    try {
        $repo = New-FactoryObject -Repository
        
        # Log
        Write-PSYVariableLog "Connection.$Name" $null

        # Determine if existing
        $existing = $repo.FindEntity('Connection', 'Name', $Name)
        if ($existing.Count -eq 0) {
            return
        }
        else {
            $existing = $existing[0]
        }

        $repo.DeleteEntity('Connection', $existing.ID)
    }
    catch {
        Write-PSYErrorLog $_
    }
}