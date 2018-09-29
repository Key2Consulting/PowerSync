<#
.SYNOPSIS

.DESCRIPTION
Stop-PSYActivity will not stop a remote activities if they've already started processing. However, it will prevent remote activities from starting if they haven't yet.

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
        $repo = New-FactoryObject -Repository
        if ($InputObject -is [hashtable]) {
            $activityID = $InputObject.ID
        }
        else {
            $activityID = $InputObject
        }

        # Attempt to execute the stop logic within a critical section. This should prevent local concurrency issues, but will
        # not synchronize remote processing.
        $activity = $repo.CriticalSection({
            # Get an updated copy.
            $activity = $this.ReadEntity('Activity', $activityID)
            
            # If the activity hasn't started, cancel it.
            if ($activity.Status -eq 'Started') {
                $activity = $repo.CriticalSection({
                    $activity.Status = 'Stopped'
                    $this.UpdateEntity('Activity', $activity)
                })
            }
            # If it's a local job, terminate it via Stop-Job
            elseif ($activity.JobInstanceID -and $activity.ExecutionServer -eq $env:COMPUTERNAME) {
                $temp = Get-Job -InstanceId $activity.JobInstanceID | Stop-Job | Remove-Job -Force
                $activity = $repo.CriticalSection({
                    $activity.Status = 'Stopped'
                    $this.UpdateEntity('Activity', $activity)
                })
            }
            else {
                throw "Unable to stop activity '$($activity.Name)' with ID $($activity.ID)."
            }
        })
    }
    catch {
        Write-PSYErrorLog $_
    }
}