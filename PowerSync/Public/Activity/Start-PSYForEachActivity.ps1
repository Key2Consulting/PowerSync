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
        [switch] $ContinueOnError
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        
        # Log activity start
        $a = Write-ActivityLog $ScriptBlock $Name 'ForEach Activity Started' 'Started'

        # Enumerate all items passed in, and asynchrously execute them. By using runspaces, variables are easily imported
        # into ScriptBlock.  If we used jobs, we'd need to marshal the variables over, which is difficult to do with object types & classes.
        # https://github.com/RamblingCookieMonster/Invoke-Parallel

        $workItems = New-Object System.Collections.ArrayList
        foreach ($o in $Enumerate) {
            $workItem = @{
                InputObject = $o
                ScriptBlock = $ScriptBlock
                Index = $Enumerate.IndexOf($o)
            }
            if (-not $Ctx.Option.DisableParallel) {
                $workItem.ScriptBlock = [Scriptblock]::Create($ScriptBlock.ToString())
            }
            $null = $workItems.Add($workItem)
        }

        # Execute each (new) script block in parallel, importing all variables and modules.
        $workItems | Invoke-Parallel -ImportVariables -ImportModules -ImportFunctions -Throttle $Ctx.Option.Throttle -RunspaceTimeout $Ctx.Option.ScriptTimeout -ScriptBlock {
            $a = Write-ActivityLog $_.ScriptBlock $Name "ForEach Activity [$($_.Index)] Started" 'Started'
            Invoke-Command -ArgumentList $_.InputObject -ScriptBlock $_.ScriptBlock
            Write-ActivityLog $_.ScriptBlock $Name "ForEach Activity [$($_.Index)] Completed" 'Completed' $a
        }

        # Log activity end
        Write-ActivityLog $ScriptBlock[0] $Name 'ForEach Activity Completed' 'Completed' $a
    }
    catch {
        Write-PSYExceptionLog $_ "Error starting ForEach Activity '$Name'." -Rethrow
    }
}