<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER InputObject
Parameters passed to the activity. Use the $Input automatic variable in the value of the ScriptBlock parameter to represent the input objects.

.EXAMPLE
#>
function Wait-PSYActivity {
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = 'Return value from Start-PSYActivity.', Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [object] $InputObject
    )

    begin {
        $activities = [System.Collections.ArrayList]::new()
        $completed = [System.Collections.ArrayList]::new()       # completed activities will be moved here
    }
    
    process {
        if ($InputObject -is [array]) {
            [void] $activities.AddRange($InputObject)
        }
        else {
            [void] $activities.Add($InputObject)
        }
    }

    end {
        try {
            # Progress doesn't work well in an unattended environment.
            if (-not $PSYSession.UserInteractive) {
                $ProgressPreference = "SilentlyContinue"        # certain hosting environments will fail b/c they don't support Write-Progress
            }

            # Control variables
            $totalCount = $activities.Count
            $queuePollingInterval = Get-PSYVariable -Name 'PSYQueuePollingInterval' -DefaultValue 5000
            $jobPollingInterval = 1000       # since it's local, we can poll more frequent
            $lastQueuePollTime = Get-Date
            $timeToPollQueue = $true

            # While there are still incomplete activities.
            while ($activities.Count) {
                $activities | ForEach-Object {
                    $activity = $_
                    $justCompleted = $false

                    # If it was queued, monitor the return queue for completed messages.
                    if ($activity.Queue) {
                        # If it's time to poll the queue again
                        if ($timeToPollQueue) {
                            $repo = New-FactoryObject -Repository
                            
                            # Since there's no way to fetch a message by ID from a queue, handlers must place
                            # their response on a return queue with the Message ID in the name.
                            $returnQueue = "$($activity.Queue):$($activity.MessageID)"
                            $returnMsg = $repo.CriticalSection({
                                $this.GetMessage($returnQueue)      # will automatically delete
                            })

                            if ($returnMsg) {
                                # It's complete, so move it to completed, and finish up.
                                $activity.Result = $returnMsg.Result
                                $activity.HadErrors = $returnMsg.HadErrors
                                $activity.Error = $returnMsg.Error
    
                                $justCompleted = $true
                            }
                        }
                    }
                    else {
                        # Executing as local job, so check whether it's complete.
                        if ($activity.Job.State -ne "Running") {
                            Receive-Job -Job $activity.Job
                            # Send any printable streams to the Console.
                            $job = $activity.Job.ChildJobs[0]
                            $job.Information | ForEach-Object { Write-PSYHost $_.MessageData }
                            $job.Debug | ForEach-Object { Write-PSYHost $_.MessageData }
                            $job.Verbose | ForEach-Object { Write-PSYHost $_.MessageData }

                            # Append the results to the activity
                            $activity.Result = if ($job.Output.Count) { $job.Output[0] } else { $null }
                            $activity.HadErrors = [bool] $job.Error.Count
                            $activity.Error = if ($job.Error.Count) { $job.Error[0] } else { $null }

                            Remove-Job -Job $activity.Job -Force
                            $justCompleted = $true
                        }
                    }

                    # Regardless of queue or job, if the activity just completed, finish up processing.
                    if ($justCompleted) {
                        [void] $completed.Add($activity)
                        Write-PSYDebugLog -Message "$($Name): Completed (Processed $($completed.Count) out of $totalCount)"
                        Write-Progress -Activity $activity.Name -PercentComplete ($completed.Count / $totalCount * 100)

                        # If errors and the current error action is to stop, we should do just that. Otherwise processing would continue silently.
                        if ($activity.HasErrors -and $ErrorActionPreference -eq "Stop") {
                            throw $activity.Error
                        }
                    }
                }
                
                # Remove any completed activities from our incomplete list, and wait until next polling interval.
                $completed | ForEach-Object { $activities.Remove($_) }

                if ($activities.Count) {
                    Start-Sleep -Milliseconds $jobPollingInterval
                    $lastQueuePollDuration = New-TimeSpan -Start $lastQueuePollTime -End (Get-Date)
                    if ($lastQueuePollDuration.TotalMilliseconds -ge $queuePollingInterval) {
                        $timeToPollQueue = $true
                        $lastQueuePollTime = Get-Date
                    }
                    else {
                        $timeToPollQueue = $false
                    }
                }
            }

            # Return completed results to caller
            $completed
        }
        catch {
            Write-PSYErrorLog $_
        }
    }
}