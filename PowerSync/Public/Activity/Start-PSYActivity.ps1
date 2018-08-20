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
        $log = $Ctx.System.Repository.StartActivity($null, $Name, $env:COMPUTERNAME, $MyInvocation.PSCommandPath, $ScriptBlock.Ast.ToString(), 'Started')

        # $ScriptBlock = [ScriptBlock]::Create('param($Ctx)' + $ScriptBlock.ToString())
        Invoke-Command -ScriptBlock $ScriptBlock -NoNewScope -ArgumentList $Args
        #$job = Start-Job -Name Para1 -ScriptBlock $ScriptBlock
        #Wait-Job $job

        # Log activity end
        $Ctx.System.Repository.EndActivity($log.ID)
    }
    catch {
        throw "Error starting activity $Name. $($_.Exception.Message)"
    }
}