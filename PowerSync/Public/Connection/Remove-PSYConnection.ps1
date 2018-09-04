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
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Log
        Write-PSYVariableLog "Connection.$Name" $null

        # Set the in the repository.  If it doesn't exist, it will be created.
        return $repo.CriticalSection({
            
            # Determine if existing
            $existing = $this.FindEntity('Connection', 'Name', $Name)
            if ($existing.Count -eq 0) {
                return
            }
            else {
                $existing = $existing[0]
            }

            $this.DeleteEntity('Connection', $existing.ID)
        })
    }
    catch {
        Write-PSYErrorLog $_ "Error removing connection '$Name'."
    }
}