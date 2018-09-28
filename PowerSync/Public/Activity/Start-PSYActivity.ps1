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
        [parameter(HelpMessage = 'Parameters passed to the activity. Use the $Input automatic variable in the value of the ScriptBlock parameter to represent the input objects.', Mandatory = $false)]
        [object] $InputObject,
        [Parameter(HelpMessage = "The script to execute as part of the activity.", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "The name of the activity for logging and readability purposes.", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "Starts activity execution and immediately returns handles to the running activities. Use Wait-PSYActivity to await their completion.", Mandatory = $false)]
        [switch] $Async,
        [Parameter(HelpMessage = "Submits the activity to a given queue for remote and scalable execution.", Mandatory = $false)]
        [string] $Queue,
        [Parameter(HelpMessage = "If set, forces remote jobs used in parallel processes to break into the debugger.", Mandatory = $false)]
        [switch] $WaitDebugger
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

        # Package up all the required execution information as an activity object. This object must be serializable.
        $activity = @{
            InputObject = $InputObject
            ScriptBlock = $ScriptBlock.Ast.ToString().TrimStart('{').TrimEnd('}')
            Name = $Name
            PSYSession = $PSYSession
            DebugPreference = $DebugPreference
            VerbosePreference = $VerbosePreference
            ErrorActionPreference = $ErrorActionPreference
            WaitDebugger = $WaitDebugger
        }

        # If we're executing the activity now (i.e. not queuing).
        if (-not $Queue) {
            # If we're running asynchronously, use remote jobs.
            if ($Async) {
                $activity.Job = (Start-Job -ArgumentList $activity -Verbose -Debug -ScriptBlock {
                    param ($activity)
                    
                    # Initialize environment
                    if ($activity.WaitDebugger) {
                        Wait-Debugger       # if the WaitDebugger option is set in Invoke-ForEach, will break here. Step into Invoke-Command to debug client code.
                    }
                    Import-Module $activity.PSYSession.Module
                    $global:PSYSession = $activity.PSYSession
                    $PSYSession.UserModules | ForEach-Object { Import-Module $_ }       # load any user modules
                    Set-Location -Path $PSYSession.WorkingFolder                        # default to parent session's working folder
                    $PSYSession.UserInteractive = $false                                # force false since out-of-process jobs are unattended
                
                    # Without setting these preferences, this output won't get returned
                    $DebugPreference = $activity.DebugPreference
                    $VerbosePreference = $activity.VerbosePreference
                    $ProgressPreference = 'SilentlyContinue'

                    # Execute the input scriptblock
                    $log = Write-PSYActivityLog -ScriptAst $activity.ScriptBlock -Name $activity.Name -Message "Activity '$($activity.Name)' started" -Status 'Started'
                    $scriptBlock = [Scriptblock]::Create($activity.ScriptBlock)                     # only the text was serialized, not the object, so reconstruct
                    Invoke-Command -ScriptBlock $scriptBlock -InputObject $activity.InputObject     # run client code
                    Write-PSYActivityLog -Name $activity.Name -Message "Activity '$($activity.Name)' completed" -Status 'Completed' -Activity $log
                })
                
                Write-PSYDebugLog -Message "Activity '$Name' executing asynchronously as job $($activity.Job.InstanceId)"

                # If WaitDebugger was set, the remote jobs will be waiting for the debugger, but the main thread still needs
                # to call Debug-Job to complete the cycle.
                if ($activity.WaitDebugger -and $Async) {
                    Start-Sleep -Milliseconds 500       # isn't there a better way? needed b/c of what appears to be timing issues
                    $null = Debug-Job $activity.Job
                }
            }
            else {
                # Else, we're running sequentially, so avoid using jobs. One reason for this is to make debugging client
                # scripts easier. We still need to imitate async processing and output the same values as before.
                try {
                    $log = Write-PSYActivityLog -ScriptAst $activity.ScriptBlock -Name $Name -Message "Activity '$Name' started" -Status 'Started'
                    $r = Invoke-Command -ScriptBlock $ScriptBlock -InputObject $activity.InputObject
                    Write-PSYActivityLog -Name $Name -Message "Activity '$Name' completed" -Status 'Completed' -Activity $log
                    $activity.Result = $r
                    $activity.HadErrors = $false
                    $activity.Errors = @()
                }
                catch {
                    $activity.Result = $null
                    $activity.HadErrors = $true
                    $activity.Errors = $_
                    Write-PSYErrorLog $_
                }
                Write-PSYDebugLog -Message "Activity '$Name' executing synchronously $($activity.Job.InstanceId)"
            }
        }
        else {
            # Else, submit the activity to the given queue to allow execution on a remote process monitoring the queue.
            $repo = New-FactoryObject -Repository       # instantiate repository

            # Create the activity message (one per script block).
            $msgScriptBlock = $ScriptBlock.Ast.ToString()
            [void] $repo.CriticalSection({
                $this.CreateQueue($Name)
                $msg = @{
                    ID = $null
                    Activity = $activity
                }
                $this.PutMessage($Queue, $msg)
            })

            Write-PSYInformationLog -Message "Activity '$Name' queued for asynchronous execution on '$Queue'"
        }

        if ($Async) {
            # Can't end the activity log since it's being executed remotely. Either the activity handler or job should perform this.
            # Return activity (job) to caller
            $activity
        }
        elseif ($Queue) {
            # If not running async, and the item was queued, must wait for activity to complete 
            # before returning control to the caller.
            $activity | Wait-PSYActivity
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}