function Write-ActivityLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Title,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Status,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Activity
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository

        if ($Status -eq 'Started') {
            # Log activity start
            $aParentLog = $null
            if ($PSYSession.ActivityStack.Count -gt 0) {
                $aParentLog = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1]
            }
            $Activity = $repo.StartActivity($aParentLog, $Name, $env:COMPUTERNAME, $MyInvocation.PSCommandPath, $ScriptBlock.Ast.ToString(), $Status)
            [void] $PSYSession.ActivityStack.Add($Activity)
            Write-Host "$($Title): $Name"
            return $Activity
        }
        else {
            # Log activity end
            $repo.EndActivity($Activity, $Status)
            $PSYSession.ActivityStack.Remove($Activity)
            Write-Host "$($Title): $Name"
        }
    }
    catch {
        Write-PSYExceptionLog $_ "Error logging activity '$Name'." 
    }
}