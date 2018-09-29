<#
.SYNOPSIS
Saves the current state of an activity.

.DESCRIPTION
TODO
Should not need to call this API
#>
function Checkpoint-PSYActivity {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Activity
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository

        if (-not $Activity.ID) {
            # Save to the repository
            [void] $repo.CriticalSection({        # execute the operation as a critical section to ensure proper concurrency
                $this.CreateEntity('Activity', $Activity)
            })
    
            # Log
            Write-PSYInformationLog -Message "Activity '$($Activity.Name)' $($Activity.Status)"
        }
        elseif ($Activity.Status -eq 'Completed') {
            # Save to the repository
            [void] $repo.CriticalSection({
                $this.UpdateEntity('Activity', $Activity)
            })
            
            # Log
            $startTime = [DateTime]::Parse($Activity.StartDateTime);
            $endTime = [DateTime]::Parse($Activity.EndDateTime);
            [TimeSpan] $duration = $endTime.Subtract($startTime)
            Write-PSYInformationLog -Message "Activity '$($Activity.Name)' $($Activity.Status) in $($duration.TotalSeconds) sec"
        }
        elseif ($Activity.Status -eq 'Executing') {
            # Save to the repository
            [void] $repo.CriticalSection({
                $this.UpdateEntity('Activity', $Activity)
            })

            # Log
            Write-PSYVerboseLog -Message "Activity '$($Activity.Name)' $($Activity.Status) at $($Activity.ExecutionDateTime.ToString())"
        }
        else {
            # Save to the repository
            [void] $repo.CriticalSection({
                $this.UpdateEntity('Activity', $Activity)
            })
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}