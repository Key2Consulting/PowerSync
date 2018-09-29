<#
.SYNOPSIS
Receives and executes a PowerSync Activity from a queue.

.DESCRIPTION
TODO

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
        [Parameter(HelpMessage = "The queue to monitor.", Mandatory = $true)]
        [string] $Queue,
        [Parameter(HelpMessage = "Will continously monitor the queue indefinitely.", Mandatory = $false)]
        [switch] $Continous,
        [Parameter(HelpMessage = "Maximum number of parallel executions", Mandatory = $false)]
        [int] $Throttle = 5,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
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

        # Force initial iteration
        $continueProcessing = $true

        # While there are still unprocessed activities on the queue
        while ($continueProcessing -or $queuedActivity) {

            if ($queuedActivity) {
                # Execute the activity
                $queuedActivity = Start-PSYActivity -QueuedActivity $queuedActivity -Async
                $processing.Add($queuedActivity)

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
            $completed = $processing | Where-Object { (Get-Job -InstanceId $_.JobInstanceID).JobStateInfo.State -ne "Running" }
            $completed | ForEach-Object {
                $_ | Wait-PSYActivity
                $processing.Remove($_)
            }

            # If continous, wait for more work to arrive.
            if ($Continous) {
                # Out of activities, so wait for our next polling interval to check again.
                Start-Sleep -Milliseconds $queuePollingInterval
            }
            else {
                # If we're not processing continously, exit immediately once no more activities are available on the queue and we're done processing.
                if ($processing.Count -eq 0) {
                    $continueProcessing = $false
                }
                else {
                    Start-Sleep -Milliseconds 500
                    $continueProcessing = $true
                }
            }

            # Get next queued activity
            Start-Sleep -Milliseconds 500
            $queuedActivity = $repo.CriticalSection({ $this.DequeueActivity($Queue) })
        }
    }
    catch {
        Write-PSYErrorLog $_
    }    
}