<#
.SYNOPSIS
Starts a PowerSync ForEach Activity.

.DESCRIPTION
TODO - ForEach does not support Async
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

.PARAMETER WaitDebugger
If set, forces remote jobs used in parallel processes to break into the debugger.

.EXAMPLE
(1, 2, 3) | Start-PSYForEachActivity -Name 'ForEach Activity' -ScriptBlock {
    Write-PSYInformation "Item $Input"
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
function Start-PSYForEachActivity {
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "The script to execute as part of the activity.", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "The name of the activity for logging and readability purposes.", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "Runs the ForEach in parallel", Mandatory = $false, ParameterSetName = 'Parallel')]
        [switch] $Parallel,
        [Parameter(HelpMessage = "Maximum number of parallel executions", Mandatory = $false, ParameterSetName = 'Parallel')]
        [int] $Throttle = 5,
        [Parameter(HelpMessage = "Submits the activity to a given queue for remote and scalable execution.", Mandatory = $false, ParameterSetName = 'Queued')]
        [string] $Queue,
        [Parameter(HelpMessage = "If set, forces remote jobs used in parallel processes to break into the debugger.", Mandatory = $false)]
        [switch] $WaitDebugger
    )

    begin {
        $processing = [System.Collections.ArrayList]::new()
        $itemIndex = 0

        # If throttling only allows a single execution, don't use remote jobs since they have overhead.
        if ($Throttle -eq 1) {
            $Parallel = $false
        }
    }
    
    process {
        try {
            # Start the activity
            $activity = Start-PSYActivity -Name "$Name[$($itemIndex)]" -InputObject $InputObject -ScriptBlock $ScriptBlock -Async -Queue $Queue
            [void] $processing.Add($activity)
            $itemIndex++

            # If we've met our throttle limit, wait until at least one of them finishes before continuing. Does not apply to queued activities
            # since the remote reciver processing those activities has its own throttling.
            while (@(Get-Job -State Running).Count -ge $Throttle -and -not $Queue) {
                $now = Get-Date
                foreach ($job in @(Get-Job -State Running)) {
                    if ($Timeout) {
                        if ($now - (Get-Job -Id $job.id).PSBeginTime -gt [TimeSpan]::FromSeconds($Timeout)) {
                            Stop-Job $job
                        }
                    }
                }
                Start-Sleep -Milliseconds 500
            }

            # Check if any in-process activities have completed. If we're queuing, there's no easy way to check this without
            # fetching all of the activities from the database, but that would be too resource intensive when we already do 
            # that during our End event processing.
            if (-not $Queue) {
                $completed = $processing | Where-Object { (Get-Job -InstanceId $_.JobInstanceID).JobStateInfo.State -ne "Running" }
                $completed | ForEach-Object {
                    $_ | Wait-PSYActivity
                    $processing.Remove($_)
                }
            }
        }
        catch {
            Write-PSYErrorLog $_
        }
    }

    end {
        # Ensure everything's complete and results are returned before exiting (it's a safer paradigm for client code).
        $temp = $processing | Wait-PSYActivity
    }
}