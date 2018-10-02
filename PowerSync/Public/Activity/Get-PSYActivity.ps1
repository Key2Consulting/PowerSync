<#
.SYNOPSIS
Gets a PowerSync activity from the repository.

.PARAMETER ID
The ID of the activity to retrieve.
#>
function Get-PSYActivity {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $false)]
        [object] $ID
    )

    try {
        # Fetch the activity
        $repo = New-FactoryObject -Repository
        $repo.ReadEntity('Activity', $ID)
    }
    catch {
        Write-PSYErrorLog $_
    }
}