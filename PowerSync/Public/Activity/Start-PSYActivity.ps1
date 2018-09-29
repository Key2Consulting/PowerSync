<#
.SYNOPSIS
Starts a PowerSync Activity.

.DESCRIPTION
PowerSync activities organize your data integration workload into atomic units of work. Although activities are not required, they provide certain benefits, such as:
 - Log operations performed during an activity are associated to that activity.
 - Automatic error handling and logging.
 - Sequential or parallel execution (using remote jobs).

 By default, activities execute sequentially unless the -Async switch is set.

.PARAMETER InputObject
Parameters passed to the activity. Use the $Input automatic variable in the value of the ScriptBlock parameter to represent the input objects.

.PARAMETER ScriptBlock
The script to execute as part of the activity.

.PARAMETER Name
The name of the activity for logging and readability purposes.

.PARAMETER Async
Starts activity execution and immediately returns handles to the running activities. Use Wait-PSYActivity to await their completion.

.PARAMETER Queue
Submits the activity to a given queue for remote and scalable execution. The queue must be monitored by one or more external agents using Receive-PSYActivity.

The queue name is automatically created within the repository if it doesn't exist.

.PARAMETER WaitDebugger
If set, forces remote jobs used in parallel processes to break into the debugger.

.PARAMETER QueuedActivity
An activity previously queued for execution. See Receive-PSYQueuedActivity for more information.

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
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = 'Parameters passed to the activity. Use the $Input automatic variable in the value of the ScriptBlock parameter to represent the input objects.', Mandatory = $false, ParameterSetName = 'Default')]
        [object] $InputObject,
        [Parameter(HelpMessage = "The script to execute as part of the activity.", Mandatory = $true, ParameterSetName = 'Default')]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "The name of the activity for logging and readability purposes.", Mandatory = $false, ParameterSetName = 'Default')]
        [string] $Name,
        [Parameter(HelpMessage = "Starts activity execution and immediately returns handles to the running activities. Use Wait-PSYActivity to await their completion.", Mandatory = $false)]
        [switch] $Async,
        [Parameter(HelpMessage = "Submits the activity to a given queue for remote and scalable execution.", Mandatory = $false, ParameterSetName = 'Default')]
        [string] $Queue,
        [Parameter(HelpMessage = "If set, forces remote jobs used in parallel processes to break into the debugger.", Mandatory = $false)]
        [switch] $WaitDebugger,
        [parameter(HelpMessage = 'An activity previously queued for execution.', Mandatory = $false, ParameterSetName = 'Queued')]
        [object] $QueuedActivity
    )

    try {
        # Avoids confirmation prompts during logging.
        if ($DebugPreference -eq 'Inquire') {
            $DebugPreference = 'Continue'
        }
        if ($VerbosePreference -eq 'Inquire') {
            $VerbosePreference = 'Continue'
        }
        # Progress doesn't work well in an unattended environment.
        if (-not $PSYSession.UserInteractive) {
            $ProgressPreference = "SilentlyContinue"        # certain hosting environments will fail b/c they don't support Write-Progress
        }
        #$ErrorActionPreference = 'Stop'        # let the caller decide how to deal with exceptions

        if (-not $QueuedActivity) {
            # Package up all the required execution information as an activity object. This object must be serializable.
            $activity = @{
                # Activity Information
                ID = $null                      # set by repository
                ParentID = if ($PSYSession.ActivityStack.Count -gt 0) { $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1] } else { $null }
                Name = $Name
                Status = 'Started'
                StartDateTime = Get-Date | ConvertTo-PSYCompatibleType
                ExecutionDateTime = $null
                EndDateTime = $null
                Queue = $Queue                  # if set, activity is executed remotely by a receiver monitoring this queue name
                OriginatingServer = $env:COMPUTERNAME
                ExecutionServer = $null
                # Invocation Information
                InputObject = $InputObject
                ScriptBlock = $ScriptBlock.Ast.ToString().TrimStart('{').TrimEnd('}')       # without trim, Invoke-Command will just return a scriptblock
                ScriptFile = $MyInvocation.PSCommandPath
                JobInstanceID = $null
                # Results/Response Information
                Result = $null
                HadErrors = $null
                Error = $null
            }

            Checkpoint-PSYActivity -Activity $activity
        }
        else {
            $activity = $QueuedActivity
        }

        # Push activity to stack
        [void] $PSYSession.ActivityStack.Add($activity.ID)

        # If we're executing the activity now (i.e. not queuing).
        if (-not $Queue) {
            # If we're running asynchronously, use remote jobs.
            if ($Async) {

                # Environment Information
                $environmentInfo = @{
                    PSYSession = $PSYSession
                    DebugPreference = $DebugPreference.ToString()
                    VerbosePreference = $VerbosePreference.ToString()
                    ErrorActionPreference = $ErrorActionPreference.ToString()
                    WaitDebugger = [bool] $WaitDebugger
                }

                # Execute the job
                $job = (Start-Job -ArgumentList $activity.ID, $environmentInfo -Verbose -Debug -ScriptBlock {
                    param ($activityID, $environmentInfo)
                    
                    # Initialize environment
                    if ($environmentInfo.WaitDebugger) {
                        Wait-Debugger       # WaitDebugger was set, step into Invoke-Command below to debug client code
                    }
                    Import-Module $environmentInfo.PSYSession.Module
                    $global:PSYSession = $environmentInfo.PSYSession
                    $PSYSession.UserModules | ForEach-Object { Import-Module $_ }       # load any user modules
                    Set-Location -Path $PSYSession.WorkingFolder                        # default to parent session's working folder
                    $PSYSession.UserInteractive = $false                                # force false since out-of-process jobs are unattended
                
                    # Without setting these preferences, this output won't get returned
                    $DebugPreference = $environmentInfo.DebugPreference
                    $VerbosePreference = $environmentInfo.VerbosePreference
                    $ProgressPreference = 'SilentlyContinue'

                    # Fetch the activity
                    $activity = Get-PSYActivity -ID $activityID
                    if (-not $activity) {
                        throw "Cannot find activity '$activityID'"
                    }
                    elseif (-not $activity.JobInstanceID) {
                        throw "Synchronization error with activity '$($activity.Name)'. JobInstanceID not set."     # hopefully this never happens
                    }

                    # Execute the input scriptblock
                    $scriptBlock = [Scriptblock]::Create($activity.ScriptBlock)                     # only the text was serialized, not the object, so reconstruct
                    $activity.Status = 'Executing'
                    $activity.ExecutionDateTime = Get-Date | ConvertTo-PSYCompatibleType
                    $activity.ExecutionServer = $env:COMPUTERNAME
                    Checkpoint-PSYActivity $activity

                    try {
                        $activity.Result = Invoke-Command -ScriptBlock $scriptBlock -InputObject $activity.InputObject     # run client code
                    }
                    catch {
                        $activity.Result = $r
                        $activity.HadErrors = $true
                        $activity.Error = $_
                        Write-PSYErrorLog $_
                    }

                    $activity.Status = 'Completed'
                    $activity.EndDateTime = Get-Date | ConvertTo-PSYCompatibleType
                    Checkpoint-PSYActivity $activity
                })
                
                # Save the JobInstanceID immediately. This *could* cause a synchronization error if the job somehow started before we were
                # able to save the JobInstanceID.
                $activity.JobInstanceID = $job.InstanceId
                Checkpoint-PSYActivity -Activity $activity

                Write-PSYDebugLog -Message "Activity '$Name' executing asynchronously as job $($activity.Job.InstanceId)"

                # If WaitDebugger was set, the remote jobs will be waiting for the debugger, but the main thread still needs
                # to call Debug-Job to complete the cycle.
                if ($WaitDebugger -and $Async) {
                    Start-Sleep -Milliseconds 500       # isn't there a better way? needed b/c of what appears to be timing issues
                    $null = Debug-Job $job
                }
            }
            else {
                # Else, we're running sequentially, so avoid using jobs. One reason for this is to make debugging client
                # scripts easier. We still need to imitate async processing and output the same values as before.
                try {
                    $activity.Status = 'Executing'
                    $activity.ExecutionDateTime = Get-Date | ConvertTo-PSYCompatibleType
                    $activity.ExecutionServer = $env:COMPUTERNAME
                    Checkpoint-PSYActivity $activity

                    $r = Invoke-Command -ScriptBlock $ScriptBlock -InputObject $activity.InputObject
                    
                    $activity.Result = $r
                    $activity.HadErrors = $false
                    $activity.Status = 'Completed'
                    $activity.EndDateTime = Get-Date | ConvertTo-PSYCompatibleType
                    Checkpoint-PSYActivity -Name $Name -Message "Activity '$Name' completed" -Status 'Completed' -Activity $log
                }
                catch {
                    $activity.Result = $null
                    $activity.HadErrors = $true
                    $activity.Error = $_
                    $activity.Status = 'Completed'
                    $activity.EndDateTime = Get-Date | ConvertTo-PSYCompatibleType
                    Checkpoint-PSYActivity -Name $Name -Message "Activity '$Name' completed" -Status 'Completed' -Activity $log
                    Write-PSYErrorLog $_
                }
                Write-PSYDebugLog -Message "Activity '$Name' executing synchronously $($activity.JobInstanceID)"
            }
        }
        else {
            # Allow execution on a remote process monitoring the queue. Since the activity is already saved
            # to the repository, there's nothing more to do.
            Write-PSYDebugLog -Message "Activity '$Name' queued for asynchronous execution on '$($activity.Queue)'"
        }

        if ($Async) {
            # Return activity to caller
            $activity
        }
        else {
            # If not running async, wait for activity to complete before returning control to the caller. This
            # is always the defaults case since it's a safer paradigm for client code.
            $activity | Wait-PSYActivity
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
    finally {
        # Pop activity from stack
        [void] $PSYSession.ActivityStack.Remove($activity.ID)
    }
}