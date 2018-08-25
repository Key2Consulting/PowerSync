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
        if ($Status -eq 'Started') {
            # Log activity start
            $aParentLog = $null
            if ($PSYSessionState.System.ActivityStack.Count -gt 0) {
                $aParentLog = $PSYSessionState.System.ActivityStack[$PSYSessionState.System.ActivityStack.Count - 1]
            }
            $Activity = $PSYSessionRepository.StartActivity($aParentLog, $Name, $env:COMPUTERNAME, $MyInvocation.PSCommandPath, $ScriptBlock.Ast.ToString(), $Status)
            [void] $PSYSessionState.System.ActivityStack.Add($Activity)
            Write-Host "$($Title): $Name"
            return $Activity
        }
        else {
            # Log activity end
            $PSYSessionRepository.EndActivity($Activity, $Status)
            $PSYSessionState.System.ActivityStack.Remove($Activity)
            Write-Host "$($Title): $Name"
        }
    }
    catch {
        Write-PSYExceptionLog $_ "Error logging activity '$Name'." 
    }
}