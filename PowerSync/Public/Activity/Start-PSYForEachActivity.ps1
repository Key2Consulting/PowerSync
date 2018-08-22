function Start-PSYForEachActivity {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object[]] $Enumerate,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Parallel,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $ContinueOnError
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        
        # Setup sequential or parallel processing configuration
        $logTitle = "ForEach Activity"
        $throttle = 1
        $runParallel = $false
        if ($Parallel -and -not $Ctx.Option.DisableParallel) {
            $runParallel = $true
            $logTitle = "Activity (Parallel)"
            $throttle = $Ctx.Option.Throttle
        }

        # Log activity start
        $a = Write-ActivityLog $ScriptBlock[0] $Name "$logTitle Started" 'Started'

        # Enumerate all items passed in, and asynchrously execute them. By using runspaces, variables are easily imported
        # into ScriptBlock.  If we used jobs, we'd need to marshal the variables over, which is difficult to do with object types & classes.
        # https://github.com/RamblingCookieMonster/Invoke-Parallel

        # Build a list of workitems (scripts) to process
        $workItems = New-Object System.Collections.ArrayList
        foreach ($o in $Enumerate) {
            $workItem = @{
                InputObject = $o
                ScriptBlock = $ScriptBlock
                Index = $Enumerate.IndexOf($o)
            }
            # We can't use the original scriptblock because PowerShell forces it to run in the original runspace (i.e. single threaded). A
            # workaround is to recreate the scriptblocks (unless parallel processing is disabled).
            if ($runParallel) {
                $workItem.ScriptBlock = [Scriptblock]::Create($ScriptBlock.ToString())
            }
            $null = $workItems.Add($workItem)
        }

        # Execute each (new) script block in parallel, importing all variables and modules.
        $workItems | Invoke-Parallel -ImportVariables -ImportModules -ImportFunctions -Throttle $Ctx.Option.Throttle -RunspaceTimeout $Ctx.Option.ScriptTimeout -ScriptBlock {
            $a = Write-ActivityLog $_.ScriptBlock $Name "$logTitle [$($_.Index)] Started" 'Started'
            Invoke-Command -ArgumentList $_.InputObject -ScriptBlock $_.ScriptBlock
            Write-ActivityLog $_.ScriptBlock $Name "$logTitle [$($_.Index)] Completed" 'Completed' $a
        }

        # Log activity end
        Write-ActivityLog $ScriptBlock[0] $Name "$logTitle Completed" 'Completed' $a
    }
    catch {
        Write-PSYExceptionLog $_ "Error in $modeTitle '$Name'." -Rethrow
    }
}