<#
.SYNOPSIS
Starts a PowerSync Activity.

.DESCRIPTION
PowerSync activities organize your data integration workload into atomic units of work. Although activities are not required, they provide certain benefits, such as:
 - Log operations performed during an activity are associated to that activity.
 - Automatic error handling and logging.
 - Sequential or parallel execution (using remote jobs).

 By default, activities execute sequentially unless the -Async switch is set. 
 
 Async, Queue, and Parallel always return activities to the caller so that return values and error conditions can be checked. Sequential does not return an activity, but does return any output.

.PARAMETER InputObject
Specifies the input objects, and runs the activity on each input object. Use the $_ automatic variable in the ScriptBlock to reference the object.

.PARAMETER ScriptBlock
The script to execute as part of the activity.

.PARAMETER Name
The name of the activity for logging and readability purposes.

.PARAMETER Parallel
Runs the scriptblocks against each input object in parallel, but completes all activity instances before returning control to the caller. Cannot be used with the Async switch.

.PARAMETER Throttle
Maximum number of parallel executions.

.PARAMETER Async
Starts activity execution and immediately returns handles to the running activities. Use Wait-PSYActivity to await their completion.

By default, activities do not return control to the caller until after they've completed, even when using the Parallel switch, as it's a safer paradigm for client code.

.PARAMETER Queue
Submits the activity to a given queue for remote and scalable execution. The queue must be monitored by one or more external agents using Receive-PSYActivity.

The queue name is automatically created within the repository if it doesn't exist.

.PARAMETER WaitDebugger
If set, forces remote jobs used in parallel processes to break into the debugger.

.PARAMETER QueuedActivity
An activity previously queued for execution. See Receive-PSYQueuedActivity for more information.

.EXAMPLE
Start-PSYActivity -Name 'Outer Activity' -ScriptBlock {
    Start-PSYActivity -Name 'Inner Activity' -ScriptBlock {
        Write-Host "Hello World"
    }
}

.EXAMPLE
$async = 'Hello World' | Start-PSYActivity -Name 'Asynchronous Activity' -Async -ScriptBlock {
    Write-Host $_
}
Write-Host 'Some long running task'
$async | Wait-PSYActivity       # echos any log information collected during the activity

.NOTES
 - Since remote jobs are used for parallel execution, any enumerated object must support PowerShell serialization. Changes to those objects during parallel execution will not affect the instance in the caller's process space. If state needs to be shared, it is recommended to use PowerSync variables.
 - Enabling Parallel disables breakpoints in most IDEs, so consider disabling parallel execution when debugging an issue.
#>
 function Start-PSYActivity {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(Mandatory = $false)]
        [string] $Name,
        [Parameter(Mandatory = $false)]
        [switch] $Parallel,
        [Parameter(Mandatory = $false)]
        [int] $Throttle = 5,
        [Parameter(Mandatory = $false)]
        [switch] $Async,
        [Parameter(Mandatory = $false)]
        [string] $Queue,
        [Parameter(Mandatory = $false)]
        [switch] $WaitDebugger,
        [parameter(Mandatory = $false)]
        [object] $QueuedActivity
    )

    begin {
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

        # Allow forcing of all activities to run sequentially if PSYForceSequential is set. The purpose is to facilitate development
        # and debugging since you lose breakpoint capability with asynchronous processing.
        if (Get-PSYVariable -Name 'PSYForceSequential' -DefaultValue $false) {
            $Async = $false
            $Queue = $null
            $Parallel = $false
        }

        $activities = [System.Collections.ArrayList]::new()
        $itemIndex = 0
    }

    process {
        try {
            # If we've met our throttle limit, wait until at least one of them finishes before continuing. Does not apply to queued activities
            # since the remote reciver processing those activities has its own throttling.
            if ($Parallel) {
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
            }

            # Construct the activity objrect to process (or use the one provided).
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
                    ExecutionPID = $null
                    # Invocation Information
                    InputObject = $InputObject
                    ScriptBlock = $ScriptBlock.Ast.ToString().TrimStart('{').TrimEnd('}')       # without trim, Invoke-Command will just return a scriptblock
                    ScriptPath = $MyInvocation.PSCommandPath
                    JobInstanceID = $null
                    # Results/Response Information
                    OutputObject = $null
                    HadErrors = $null
                    Error = $null
                }

                Checkpoint-PSYActivity -Activity $activity
            }
            else {
                $activity = $QueuedActivity
            }

            # Push activity to stack and track
            [void] $PSYSession.ActivityStack.Add($activity.ID)
            [void] $activities.Add($activity)

            # If we're executing the activity now (i.e. not queuing).
            if (-not $Queue) {
                # If we're running asynchronously, use remote jobs.
                if ($Async -or $Parallel) {

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
                        Import-Module $environmentInfo.PSYSession.Module
                        $global:PSYSession = $environmentInfo.PSYSession
                        $PSYSession.UserModules.Clone() | ForEach-Object { Import-Module $_ }       # load any user modules
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
                        
                        # Force activity to top of the stack to ensure logging is correlated correctly.
                        $PSYSession.ActivityStack.Clear()
                        [void] $PSYSession.ActivityStack.Add($activity.ID)

                        # Execute the input scriptblock
                        $scriptBlock = [Scriptblock]::Create($activity.ScriptBlock)                     # only the text was serialized, not the object, so reconstruct
                        $activity.Status = 'Executing'
                        $activity.ExecutionDateTime = Get-Date | ConvertTo-PSYCompatibleType
                        $activity.ExecutionServer = $env:COMPUTERNAME
                        $activity.ExecutionPID = $PID
                        Checkpoint-PSYActivity $activity

                        try {
                            $global:PSItem = $activity.InputObject                              # set $_ automatic variable so script can reference
                            $global:_ = $activity.InputObject
                            
                            if ($environmentInfo.WaitDebugger) {
                                Wait-Debugger       # WaitDebugger was set, step into Invoke-Command below to debug client code
                            }
    
                            $activity.OutputObject = Invoke-Command -ScriptBlock $scriptBlock   # run client code
                        }
                        catch {
                            $activity.OutputObject = $r
                            $activity.HadErrors = $true
                            $activity.Error = $_.Exception.Message
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
                    if ($WaitDebugger -and ($Async -or $Parallel)) {
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
                        $activity.ExecutionPID = $PID
                        Checkpoint-PSYActivity $activity

                        $global:PSItem = $activity.InputObject                              # set $_ automatic variable so script can reference
                        $global:_ = $activity.InputObject
                        $activity.OutputObject = Invoke-Command -ScriptBlock $ScriptBlock   # run client code
                        
                        $activity.HadErrors = $false
                        $activity.Status = 'Completed'
                        $activity.EndDateTime = Get-Date | ConvertTo-PSYCompatibleType
                        Checkpoint-PSYActivity $activity
                    }
                    catch {
                        $activity.OutputObject = $null
                        $activity.HadErrors = $true
                        $activity.Error = $_.Exception.Message
                        $activity.Status = 'Completed'
                        $activity.EndDateTime = Get-Date | ConvertTo-PSYCompatibleType
                        Checkpoint-PSYActivity $activity
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
          
        }
        catch {
            Write-PSYErrorLog $_
        }
        finally {
            # Pop activity from stack
            [void] $PSYSession.ActivityStack.Remove($activity.ID)
        }
    }

    end {
        # Async, Queue, and Parallel always return activities to the caller.  Sequential does not.

        # Return activities to caller when executing async.
        if ($Async) {
            $activities
        }
        # If not running async, wait for activities to complete before returning control to the caller. This
        # is always the defaults case since it's a safer paradigm for client code.
        elseif ($Queue -or $Parallel) {
            $results = $activities | Wait-PSYActivity       # if this hangs on Queued activities, there's no receiver processing the queue
            $activities
        }
        elseif ($InputObject) {
            $activities
        }
        else {
            # Just a simple, sequential activity, so output anything returned by the activity, or nothing if not. Exceptions
            # would have already been thrown to the caller.
            $activities | ForEach-Object {
                if ($_.OutputObject) {
                    $_.OutputObject
                }
            }
        }
    }
}