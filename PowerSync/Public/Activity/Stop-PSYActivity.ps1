<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER InputObject
Parameters passed to the activity. Use the $Input automatic variable in the value of the ScriptBlock parameter to represent the input objects.

.EXAMPLE
#>
function Stop-PSYActivity {
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = 'Return value from Start-PSYActivity.', Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [object] $InputObject
    )

    try {
        $x = 1
       <#  # If the activity was not queued.
        if ($true) {
            if ($Parallel) {
                # Wait for the jobs to complete
                $completedJobs = New-Object System.Collections.ArrayList
                while ($completedJobs.Count -lt $workItems.Count) {
                    $workItems | ForEach-Object {
                        if ($_.Job.HasMoreData -or $_.Job.State -eq "Running") {
                            $j = Receive-Job -Job $_.Job -Verbose
                        }
                        elseif (-not $completedJobs.Contains($_.Job.InstanceId)) {
                            [void] $completedJobs.Add($_.Job.InstanceId)
                            $_.Result = $_.Job.ChildJobs[0].Output
                            Write-Progress -Activity ("$($Name)" -f $_.Index) -PercentComplete ($completedJobs.Count / $workItems.Count * 100)
                            Write-PSYDebugLog -Message ("$($Name): Completed (Processed {1} out of {2})" -f $_.Index, $completedJobs.Count, $workItems.Count)
                            # If this is being run as part of an activity, complete activity log
                            if ($ParentActivity) {
                                Checkpoint-PSYActivity -Name ($Name -f $_.Index) -Message ("Activity '$Name' completed" -f $_.Index) -Status 'Completed' -Activity $_.Activity
                            }
                        }
                    }
                }
                # Return results of job to caller
                foreach ($item in $workItems) {
                    $j = $item.Job.ChildJobs[0]     # actual job is stored as first element of ChildJobs
                    @{
                        InputObject = $item.InputObject
                        Result = $item.Result
                        HadErrors = [bool] $j.Error.Count
                        Errors = $j.Error
                    }
                    
                    # Send any printable streams to the Console.
                    $j.Information | ForEach-Object { Write-PSYHost $_.MessageData }
                    $j.Debug | ForEach-Object { Write-PSYHost $_.MessageData }
                    $j.Verbose | ForEach-Object { Write-PSYHost $_.MessageData }
                    
                    # If errors and the current error action is to stop, we should do just that. Otherwise processing would continue silently.
                    if ($j.Error.Count -gt 0 -and $ErrorActionPreference -eq "Stop") {
                        throw $j.Error
                    }
                }
            }
            else {
                # Return results of job to caller. Sequential processing is slightly different.
                foreach ($item in $workItems) {
                    @{
                        InputObject = $item.InputObject
                        Result = $item.Result
                        HadErrors = [bool] $item.HadErrors
                        Errors = $item.Errors
                    }
                }
            } #>
        #}
        #else {
            <# # Wait for the queued activity to complete.
            $pollingInterval = Get-PSYVariable -Name 'PSYQueuePollingInterval' -DefaultValue 5
            $remainingCount = 1
            while ($remainingCount -gt 0) {
                Start-Sleep -Seconds $pollingInterval
                $polledMsgs = $repo.FindEntity('Queue', 'Queue', $Queue, $false)
                $remainingCount = $polledMsgs.Count
                Write-PSYDebugLog "Queued activity $Name has $remainingCount remaining messages."
            }      #>       
        
    }
    catch {
        Write-PSYErrorLog $_
    }
}