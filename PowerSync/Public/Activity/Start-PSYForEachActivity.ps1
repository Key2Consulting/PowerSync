<#
.SYNOPSIS
Starts a PowerSync ForEach Activity.

.DESCRIPTION
PowerSync activities organize your data integration workload into atomic units of work. Although activities are not required, they provide certain benefits, such as:
 - Any log operations performed during an activity is associated to that activity. 
 - Automatic error handling and logging.
 - Sequential or parallel execution (using remote jobs).

 ForEach activities enumerate a list of objects, in parallel if specified, passing each object to the execution block as an $Input variable.

.PARAMETER ScriptBlock
The script to execute as part of the activity.

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
 - Since remote jobs are used for parallel execution, any enumerated object must support PowerShell serialization. Changes to those objects during parallel execution will not
affect the instance in the caller's process space. If state needs to be shared, it is recommended to use PowerSync variables.
 - Enabling Parallel disables breakpoints in most IDEs, so consider disabling parallel execution when debugging an issue.
#>
function Start-PSYForEachActivity {
    param
    (
        [parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "The script to execute as part of the activity.", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "The name of the activity for logging and readability purposes.", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "Runs the ForEach in parallel", Mandatory = $false)]
        [switch] $Parallel,
        [Parameter(HelpMessage = "Maximum number of parallel executions", Mandatory = $false)]
        [int] $Throttle = 3
    )

    try {
        # Log activity start
        $a = Write-ActivityLog -ScriptAst $ScriptBlock.Ast.ToString() -Name $Name -Message "ForEach Activity '$Name' started" -Status 'Started'

        # Execute foreach (in parallel if specified)
        $jobs = ($InputObject | Invoke-ForEach -ScriptBlock $ScriptBlock -Parallel:$Parallel -Throttle $Throttle -Name "$Name[{0}]" -ParentActivity $a)
        
        # Log activity end
        Write-ActivityLog -Name $Name -Message "ForEach Activity '$Name' completed" -Status 'Completed' -Activity $a
    }
    catch {
        Write-PSYErrorLog $_ "Error in Start-PSYForEachActivity '$Name'."
    }
}