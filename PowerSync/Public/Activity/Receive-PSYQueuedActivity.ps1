<#
.SYNOPSIS
Receives and executes a PowerSync Activity from a queue.

.DESCRIPTION
This function is called by a remote process to monitor a given queue and process activities as they're submitted.

Multiple receivers can monitor the same queue for scalability purposes. Receivers can be hosted in variety of hosting platforms, including:
 - WebJobs
 - One or more Virtual Machines (up to one receiver per core, depending on network capacity)
 - Same desktop where the activity originated for development purposes.

.PARAMETER Queue
The queue to monitor.

.PARAMETER Continous
Process will never exist, and will continously monitor the queue indefinitely. When omitted (useful for development purposes), Receive-PSYActivity exits immediately and returns a Job.

.PARAMETER Throttle
Maximum number of parallel executions. Throtting is handled in the repository and applies to all receivers regardless of where they execute.

.EXAMPLE
Receive-PSYActivity -Queue 'MyQueue' -Continous -Throttle 5
Write-PSYHost "You will never see this message."

.EXAMPLE
$job = Receive-PSYActivity -Queue 'MyQueue' -Throttle 5
Write-PSYHost "You will see this message."
Receive-Job -Job $job

.NOTES
TODO
#>
function Receive-PSYQueuedActivity {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $Queue,
        [Parameter(Mandatory = $false)]
        [switch] $Continous,
        [Parameter(Mandatory = $false)]
        [int] $Throttle = 5,
        [Parameter(Mandatory = $false)]
        [int] $Timeout = 0
    )

    try {
        $processing = [System.Collections.ArrayList]::new()

        # Progress doesn't work well in an unattended environment.
        if (-not $PSYSession.UserInteractive) {
            $ProgressPreference = "SilentlyContinue"        # certain hosting environments will fail b/c they don't support Write-Progress
        }

        # Control variables
        $queuePollingInterval = Get-PSYVariable -Name 'PSYQueuePollingInterval' -DefaultValue 500
        $repo = New-FactoryObject -Repository
        $async = if ($Throttle -eq 1) { $false } else { $true }
        
        # Force initial iteration
        $continueProcessing = $true

        # While there are still unprocessed activities on the queue
        while ($continueProcessing -or $queuedActivity) {

            if ($queuedActivity) {
                # Execute the activity
                if ($async) {
                    $queuedActivity = Start-PSYActivity -QueuedActivity $queuedActivity -Async -ScriptBlock {}
                    [void] $processing.Add($queuedActivity)
                }
                else {
                    Start-PSYActivity -QueuedActivity $queuedActivity -ScriptBlock {}
                }

                # If we've met our throttle limit, wait until at least one of them finishes before continuing.
                while (@(Get-Job -State Running).Count -ge $Throttle) {
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

            # Check if any in-process activities have completed
            if ($async) {
                $completed = $processing | Where-Object { (Get-Job -InstanceId $_.JobInstanceID).JobStateInfo.State -ne "Running" }
                $completed | ForEach-Object {
                    $temp = $_ | Wait-PSYActivity
                    $processing.Remove($_)
                }
            }

            # Get next queued activity
            $queuedActivity = $repo.DequeueActivity($Queue)
            if (-not $queuedActivity) {
                # Out of activities, so wait for our next polling interval to check again.
                Start-Sleep -Milliseconds $queuePollingInterval
                $queuedActivity = $repo.DequeueActivity($Queue)
            }

            # If we're not processing continously, exit immediately once no more activities are available on the queue and we're done processing.
            if (-not $Continous -and -not $queuedActivity) {
                if ($processing.Count -eq 0) {
                    $continueProcessing = $false
                }
                else {
                    Start-Sleep -Milliseconds 500
                    $continueProcessing = $true
                }
            }
        }
    }
    catch {
        Write-PSYErrorLog $_
    }    
}