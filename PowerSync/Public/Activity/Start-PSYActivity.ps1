function Start-PSYActivity {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object[]] $Args
    )

    try {
        # Log activity start
        if ($Ctx.System.ActivityStack.Count -gt 0) {
            $aParentLog = $Ctx.System.ActivityStack[$Ctx.System.ActivityStack.Count - 1]
        }
        $aLog = $Ctx.System.Repository.StartActivity($aParentLog, $Name, $env:COMPUTERNAME, $MyInvocation.PSCommandPath, $ScriptBlock.Ast.ToString(), 'Started')
        $Ctx.System.ActivityStack.Add($aLog)

        # $ScriptBlock = [ScriptBlock]::Create('param($Ctx)' + $ScriptBlock.ToString())
        Invoke-Command -ScriptBlock $ScriptBlock -NoNewScope -ArgumentList $Args
        #$job = Start-Job -Name Para1 -ScriptBlock $ScriptBlock
        #Wait-Job $job

        # Log activity end
        $Ctx.System.Repository.EndActivity($aLog.ID, "Completed")
        $Ctx.System.ActivityStack.Remove($aLog)
    }
    catch {
        throw "Error starting activity $Name. $($_.Exception.Message)"
    }
}