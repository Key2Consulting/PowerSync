function Start-PSYActivity {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock[]] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Parallel
    )

    try {
        # Validation
        Confirm-PSYInitialized
        
        # Setup sequential or parallel processing configuration
        $throttle = 1
        $runParallel = $false
        if ($Parallel -and -not $PSYSessionState.Option.DisableParallel) {
            $runParallel = $true
            $throttle = $PSYSessionState.Option.Throttle
        }

        # Log activity start
        $a = Write-ActivityLog $ScriptBlock[0] $Name "Start-PSYActivity Started" 'Started'

        # Enumerate all ScriptBlocks passed in, and asynchrously execute them. By using runspaces, variables are easily imported
        # into ScriptBlock.  If we used jobs, we'd need to marshal the variables over, which is difficult to do with object types & classes.
        # https://github.com/RamblingCookieMonster/Invoke-Parallel

        # Build a list of workitems (scripts) to process
        $workItems = New-Object System.Collections.ArrayList
        foreach ($o in $ScriptBlock) {
            $workItem = @{
                ScriptBlock = $ScriptBlock[$ScriptBlock.IndexOf($o)]
                Index = $ScriptBlock.IndexOf($o)
            }
            # We can't use the original scriptblock because PowerShell forces it to run in the original runspace (i.e. single threaded). A
            # workaround is to recreate the scriptblocks (unless parallel processing is disabled).
            if ($runParallel) {
                $workItem.ScriptBlock = [Scriptblock]::Create($o.ToString())
            }
            [void] $workItems.Add($workItem)
        }

        # Execute each (new) script block in parallel, importing all variables and modules.
        $workItems | Invoke-Parallel -ImportVariables -ImportModules -ImportFunctions -Throttle $throttle -RunspaceTimeout $PSYSessionState.Option.ScriptTimeout -ScriptBlock {
            $a = Write-ActivityLog $_.ScriptBlock $Name "Start-PSYActivity [$($_.Index)] Started" 'Started'
            Invoke-Command $_.ScriptBlock
            Write-ActivityLog $_.ScriptBlock $Name "Start-PSYActivity [$($_.Index)] Completed" 'Completed' $a
        }

        <# THE CODE BELOW WAS AN ATTEMPT TO USE JOBS TO RUN PARALLEL ACTIVITIES.
        $jobs = New-Object System.Collections.ArrayList
        foreach ($script in $ScriptBlock) {
            $job = Start-Job -ScriptBlock $script -InitializationScript {
                Import-Module "D:\Dropbox\Project\Key2\PowerSync\PowerSync"
            }
            $null = $jobs.Add($job)
            Start-Sleep -Seconds 1
            Debug-Job -Job $job
        }

        # Wait for them all to finish
        Get-Job | Wait-Job
        $x = $jobs[0].ChildJobs[0].Error
        #>

        # Log activity end
        Write-ActivityLog $ScriptBlock[0] $Name "Start-PSYActivity Completed" 'Completed' $a
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Start-PSYActivity '$Name'."
    }
}