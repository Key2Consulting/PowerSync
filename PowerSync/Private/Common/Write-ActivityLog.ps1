function Write-ActivityLog {
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
            if ($Ctx.System.ActivityStack.Count -gt 0) {
                $aParentLog = $Ctx.System.ActivityStack[$Ctx.System.ActivityStack.Count - 1]
            }
            $Activity = $Ctx.System.Repository.StartActivity($aParentLog, $Name, $env:COMPUTERNAME, $MyInvocation.PSCommandPath, $ScriptBlock.Ast.ToString(), $Status)
            $null = $Ctx.System.ActivityStack.Add($aLog)
            if ($Ctx.Option.PrintVerbose) {
                Write-Host "$($Title): $Name"
            }
            return $Activity
        }
        else {
            # Log activity end
            $Ctx.System.Repository.EndActivity($Activity, $Status)
            $Ctx.System.ActivityStack.Remove($Activity)
            if ($Ctx.Option.PrintVerbose) {
                Write-Host "$($Title): $Name"
            }
        }
    }
    catch {
        Write-PSYExceptionLog $_ "Error logging activity '$Name'." -Rethrow
    }
}