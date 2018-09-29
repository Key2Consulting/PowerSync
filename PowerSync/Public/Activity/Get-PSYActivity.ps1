<#
.SYNOPSIS
Gets a PowerSync activity from the repository.

.DESCRIPTION
TODO
#>
function Get-PSYActivity {
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = 'TODO', Mandatory = $false)]
        [object] $ID
    )

    try {
        # Fetch the activity
        $repo = New-FactoryObject -Repository
        $repo.CriticalSection({
            $this.ReadEntity('Activity', $ID)
        })
    }
    catch {
        Write-PSYErrorLog $_
    }
}