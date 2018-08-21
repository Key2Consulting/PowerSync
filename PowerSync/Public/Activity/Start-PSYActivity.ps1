function Start-PSYActivity {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        
        # Log activity start
        $a = Write-ActivityLog $ScriptBlock $Name 'Activity Started' 'Started'
    
        # Execute activity
        # $ScriptBlock = [ScriptBlock]::Create('param($Ctx)' + $ScriptBlock.ToString())
        Invoke-Command -ScriptBlock $ScriptBlock -NoNewScope -ArgumentList $Args
        #$job = Start-Job -Name Para1 -ScriptBlock $ScriptBlock
        #Wait-Job $job

        # Log activity end
        Write-ActivityLog $ScriptBlock $Name 'Activity Completed' 'Completed' $a
    }
    catch {
        Write-PSYExceptionLog $_ "Error starting activity '$Name'." -Rethrow
    }
}