<#
.SYNOPSIS
Starts a PowerSync Activity.

.DESCRIPTION
PowerSync activities organize your data integration workload into atomic units of work. Although activities are not required, they provide certain benefits, such as:
 - Any log operations performed during an activity is associated to that activity. 
 - Automatic error handling and logging.
 - Sequential or parallel execution (using remote jobs).

.PARAMETER ScriptBlock
The script to execute as part of the activity. Can be a single script, or an array of scripts.

.PARAMETER Name
The name of the activity for logging and readability purposes.

.PARAMETER Parallel
Runs the scriptblocks in parallel when multiple scriptblocks are defined.

.PARAMETER Throttle
Maximum number of parallel executions.

.EXAMPLE
Start-PSYActivity -Name 'Simple Activity' -ScriptBlock {
    Write-PSYInformationLog 'Parallel nested script 1 is executing'
}

.EXAMPLE
Start-PSYActivity -Name 'Test Parallel Execution' -Parallel -ScriptBlock ({
    Write-PSYInformationLog 'Parallel nested script 1 is executing'
}, {
    Write-PSYInformationLog 'Parallel nested script 2 is executing'
}, {
    Write-PSYInformationLog 'Parallel nested script 3 is executing'
})
.NOTES
 - Since remote jobs are used for parallel execution, any enumerated object must support PowerShell serialization. Changes to those objects during parallel execution will not affect the instance in the caller's process space. If state needs to be shared, it is recommended to use PowerSync variables.
 - Enabling Parallel disables breakpoints in most IDEs, so consider disabling parallel execution when debugging an issue.
#>
 function Start-PSYActivity {
    param
    (
        [Parameter(HelpMessage = "The script to execute as part of the activity. Can be a single script, or an array of scripts.", Mandatory = $true)]
        [object] $ScriptBlock,
        [Parameter(HelpMessage = "The name of the activity for logging and readability purposes.", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "Runs the scriptblocks in parallel when multiple scriptblocks are defined.", Mandatory = $false)]
        [switch] $Parallel,
        [Parameter(HelpMessage = "Maximum number of parallel executions", Mandatory = $false)]
        [int] $Throttle = 3
    )

    try {
        # Log activity start. We also lock the scriptblock AST for reference purposes.  If multiple scriptblocks are
        # defined, just log the first one.
        $scriptAst = $ScriptBlock | ForEach-Object { $_.Ast.ToString() }
        $scriptAst = '[' + ($scriptAst -join ',') + ']'
        
        $a = Write-ActivityLog -ScriptAst $scriptAst -Name $Name -Message "Activity '$Name' started" -Status 'Started'
        $parentActivity = if ($ScriptBlock -is [array]) {$a} else {$null}       # only log a child activity if an array of scriptblocks need processing

        # Execute foreach (in parallel if specified)
        $job = ($ScriptBlock | Invoke-ForEach -ScriptBlock $ScriptBlock -Parallel:$Parallel -Throttle $Throttle -Name "$Name[{0}]" -ParentActivity $parentActivity)
        
        # Log activity end
        Write-ActivityLog -Name $Name -Message "Activity '$Name' completed" -Status 'Completed' -Activity $a
    }
    catch {
        Write-PSYErrorLog $_ "Error in Start-PSYActivity '$Name'."
    }
}