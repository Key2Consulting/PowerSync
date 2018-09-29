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
            $jobPollingInterval = 1000       # since it's local, we can poll more frequently
            $lastQueuePollTime = Get-Date
            $timeToPollQueue = $true
            $repo = New-FactoryObject -Repository

            # While there are still incomplete activities.
            while ($activities.Count) {
                $activities | ForEach-Object {
                    
                    $activity = $_
                    $justCompleted = $false

                    # NOTE: The activities passed into this function will be out of date since they run asynchronously and there's
                    # no automatic marshaling of updates to those activities back into the instances of the main thread. The only
                    # reliable attributes are those defined when initially starting the job (i.e. JobInstanceID, Queue).

                    # If it was queued on a remote server. The dequeued status indicates Receive-PSYQueuedActivity invoked 
                    # Wait-PSYActivity, so it's actually a local job.
                    if ($activity.Queue -and $activity.Status -ne 'Dequeued') {
                        # If it's time to poll the queue again
                        if ($timeToPollQueue) {
                            # Immediately check if it's complete to avoid hitting the repository if so. If not, reload it and check again.
                            if ($activity.Status -eq 'Completed') {
                                $justCompleted = $true
                            }
                            else {
                                # Get the most updated activity from the repository (our instance would be out of date) and check again. 
                                $activity = $repo.CriticalSection({
                                    $this.ReadEntity('Activity', $activity.ID)
                                })
                                if ($activity.Status -eq 'Completed') {
                                    $justCompleted = $true
                                }
                            }
                        }
                    }
                    else {
                        # Executing as local job, so check whether it's complete.
                        $job = Get-Job -InstanceId $activity.JobInstanceID
                        if ($job) {
                            if ($job.JobStateInfo.State -ne "Running") {
                                # Ensure it's completely done
                                $j = $job | Wait-Job | Receive-Job

                                # Refresh the activity information from the repo
                                $activity = $repo.CriticalSection({
                                    $this.ReadEntity('Activity', $activity.ID)
                                })

                                # Send any printable streams to the Console.
                                $job = $job.ChildJobs[0]
                                $job.Information | ForEach-Object { Write-PSYHost $_.MessageData }
                                $job.Debug | ForEach-Object { Write-PSYHost $_.MessageData }
                                $job.Verbose | ForEach-Object { Write-PSYHost $_.MessageData }

                                $j = Remove-Job -InstanceId $activity.JobInstanceID -Force
                                $justCompleted = $true
                            }
                        }
                        else {
                            # Can't find the job, so it's impossible to complete this request. Flag as error and mark as complete.
                            $activity.Result = $null
                            $activity.HadErrors = $true
                            $activity.Error = "Activity '$($activity.Name)' could not be confirmed as Job InstanceId '$($activity.JobInstanceID)' does not exist."
                            $justCompleted = $true
                        }
                    }

                    # Regardless of queue or job, if the activity just completed, finish up processing.
                    if ($justCompleted) {
                        [void] $completed.Add($activity)
                        Write-PSYDebugLog -Message "$($Name): Completed (Processed $($completed.Count) out of $totalCount)"
                        Write-Progress -Activity $activity.Name -PercentComplete ($completed.Count / $totalCount * 100)

                        # Perform hard copy of activity data we just refreshed back to the input objects passed into 
                        # this function, which clients may still have references to. We return the refreshed/completed 
                        # result, but updating their original objects is a nice touch.
                        $_.ID = $activity.ID
                        $_.ParentID = $activity.ParentID
                        $_.Name = $activity.Name
                        $_.Status = $activity.Status
                        $_.StartDateTime = $activity.StartDateTime
                        $_.ExecutionDateTime = $activity.ExecutionDateTime
                        $_.EndDateTime = $activity.EndDateTime
                        $_.Queue = $activity.Queue
                        $_.OriginatingServer = $activity.OriginatingServer
                        $_.ExecutionServer = $activity.ExecutionServer
                        $_.InputObject = $activity.InputObject
                        $_.ScriptBlock = $activity.ScriptBlock
                        $_.ScriptFile = $activity.ScriptFile
                        $_.JobInstanceID = $activity.JobInstanceID
                        $_.Result = $activity.Result
                        $_.HadErrors = $activity.HadErrors
                        $_.Error = $activity.Error
        
                    }
                }
                
                # Remove any completed activities from our incomplete list, and wait until next polling interval.
                $completed | ForEach-Object {
                    $id = $_.ID
                    $a = $activities.Where({$_.ID -eq $id})
                    $activities.Remove($a[0])
                }

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

            # All jobs completed at this point
            #
                        
            # If there are errors and the current error action is to stop, throw those errors now. Otherwise processing would continue silently.
            if ($ErrorActionPreference -eq "Stop") {
                $errorList = [System.Collections.ArrayList]::new()
                $completed | ForEach-Object {
                    if ($_.HasErrors) {
                        [void] $errorList.Add($_.Error)
                    }
                }
                $ex = [System.Exception]::new()
                $ex.Data = $errorList
                $ex.Message = "$($errorList.Count) error(s) were encountered during activity execution."
                throw $ex
            }

            # Return completed results to caller
            $completed
        }
        catch {
            Write-PSYErrorLog $_
        }
    }
}