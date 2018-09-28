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

            # Control parameters
            $totalCount = $activities.Count
            $completed = New-Object System.Collections.ArrayList        # completed activities will be moved here
            $queuePollingInterval = Get-PSYVariable -Name 'PSYQueuePollingInterval' -DefaultValue 5000
            $jobPollingInterval = 1000       # since it's local, we can poll more frequent
            $lastQueuePollTime = Get-Date
            $timeToPollQueue = $true

            # While there are still incomplete activities.
            while ($activities.Count) {
                $activities | ForEach-Object {
                    $justCompleted = $false

                    # If it was queued, monitor the return queue for completed messages.
                    if ($_.Queue) {
                        # If it's time to poll the queue again
                        if ($timeToPollQueue) {
                            $repo = New-FactoryObject -Repository
                            
                            # Since there's no way to fetch a message by ID from a queue, handlers must place
                            # their response on a return queue with the Message ID in the name.
                            $returnQueue = "$($_.Queue):$($_.MessageID)"
                            $returnMsg = $repo.CriticalSection({
                                $this.GetMessage($returnQueue)      # will automatically delete
                            })

                            if ($returnMsg) {
                                # It's complete, so move it to completed, and finish up.
                                $_.Result = $returnMsg.Result
                                $justCompleted = $true
                            }
                        }
                    }
                    else {
                        # Executing as local job, so check whether it's complete.
                        if ($_.Job.State -ne "Running") {
                            # It's complete, so move it to completed, and finish up.
                            $job = Receive-Job -Job $_.Job -Verbose
                            $_.Result = @{
                                Output = $_.Job.ChildJobs[0].Output
                                Error = $_.Job.ChildJobs[0].Error
                                Information = $_.Job.ChildJobs[0].Information
                                Debug = $_.Job.ChildJobs[0].Debug
                                Verbose = $_.Job.ChildJobs[0].Verbose
                            }
                            $justCompleted = $true
                        }
                    }

                    # Regardless of queue or job, if the activity just completed, finish up processing.
                    if ($justCompleted) {
                        [void] $completed.Add($_)
                        Write-PSYDebugLog -Message "$($Name): Completed (Processed $($completed.Count) out of $totalCount)"
                        Write-Progress -Activity $_.Name -PercentComplete ($completed.Count / $totalCount * 100)

                        # Send any printable streams to the Console.
                        $_.Result.Information | ForEach-Object { Write-PSYHost $_.MessageData }
                        $_.Result.Debug | ForEach-Object { Write-PSYHost $_.MessageData }
                        $_.Result.Verbose | ForEach-Object { Write-PSYHost $_.MessageData }

                        # If errors and the current error action is to stop, we should do just that. Otherwise processing would continue silently.
                        if ($_.Result.Error.Count -gt 0 -and $ErrorActionPreference -eq "Stop") {
                            throw $_.Result.Error[0]
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
        }
        catch {
            Write-PSYErrorLog $_
        }
    }
}