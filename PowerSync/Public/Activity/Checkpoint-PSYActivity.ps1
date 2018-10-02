<#
.SYNOPSIS
Saves the current state of an activity. You should not need to call this API directly.
#>
function Checkpoint-PSYActivity {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [object] $Activity
    )

    try {
        $repo = New-FactoryObject -Repository

        if (-not $Activity.ID) {
            # Save to the repository
            [void] $repo.CreateEntity('Activity', $Activity)
    
            # Log
            Write-PSYInformationLog -Message "Activity '$($Activity.Name)' $($Activity.Status)"
        }
        elseif ($Activity.Status -eq 'Completed') {
            # Save to the repository
            [void] $repo.UpdateEntity('Activity', $Activity)
            
            # Log
            $startTime = [DateTime]::Parse($Activity.StartDateTime);
            if ($Activity.ExecutionDateTime) {
                $execTime = [DateTime]::Parse($Activity.ExecutionDateTime);
            }
            else {
                $execTime = [DateTime]::Parse($Activity.StartDateTime);
            }
            $endTime = [DateTime]::Parse($Activity.EndDateTime);
            [TimeSpan] $totalDuration = $endTime.Subtract($startTime)
            [TimeSpan] $execDuration = $endTime.Subtract($execTime)
            Write-PSYInformationLog -Message "Activity '$($Activity.Name)' $($Activity.Status) in $($totalDuration.TotalSeconds) sec (executed in $($execDuration.TotalSeconds) sec)."
        }
        elseif ($Activity.Status -eq 'Executing') {
            # Save to the repository
            [void] $repo.UpdateEntity('Activity', $Activity)

            # Log
            Write-PSYVerboseLog -Message "Activity '$($Activity.Name)' $($Activity.Status) at $($Activity.ExecutionDateTime.ToString())"
        }
        else {
            # Save to the repository
            [void] $repo.UpdateEntity('Activity', $Activity)
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}