function Start-PSYParallelActivity {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock[]] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        
        # Log activity start
        $a = Write-ActivityLog $ScriptBlock[0] $Name 'Parallel Activity Started' 'Started'

        # Enumerate all ScriptBlocks passed in, and asynchrously execute them. By using runspaces, variables are easily imported
        # into ScriptBlock.  If we used jobs, we'd need to marshal the variables over, which is difficult to do with object types & classes.
        # https://github.com/RamblingCookieMonster/Invoke-Parallel

        # We can't use the original scriptblock because PowerShell forces it to run in the original runspace (i.e. single threaded). A
        # workaround is to recreate the scriptblocks.
        $recreatedScriptBlock = New-Object System.Collections.ArrayList
        if (-not $Ctx.System.DisableParallel) {
            foreach ($script in $ScriptBlock) {
                $null = $recreatedScriptBlock.Add([Scriptblock]::Create($script.ToString()))
            }
        }
        else {
            # Don't recreate, forcing the process to be sequential (and debugging to work seamlessly).
            $recreatedScriptBlock = $ScriptBlock
        }

        # Execute each (new) script block in parallel, importing all variables and modules.
        $recreatedScriptBlock | Invoke-Parallel -ImportVariables -ImportModules -Throttle $Ctx.Option.Throttle -RunspaceTimeout $Ctx.Option.ScriptTimeout -ScriptBlock {
            #Write-ActivityLog $ScriptBlock $Name "Parallel Activity [$($recreatedScriptBlock.IndexOf($_))] Started" 'Started'
            Invoke-Command $_
            #Write-ActivityLog $ScriptBlock $Name "Parallel Activity [$($recreatedScriptBlock.IndexOf($_))] Completed" 'Completed'
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
        Write-ActivityLog $ScriptBlock[0] $Name 'Main Activity Completed' 'Completed' $a
    }
    catch {
        Write-PSYExceptionLog $_ "Error starting parallel activity '$Name'." -Rethrow
    }
}