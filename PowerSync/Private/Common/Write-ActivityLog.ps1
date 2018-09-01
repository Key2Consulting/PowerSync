function Write-ActivityLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $ScriptAst,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Message,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Status,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Activity,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $ParentActivity
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository

        if ($Status -eq 'Started') {
            # Log activity start
            $Activity =  $repo.CriticalSection({        # execute the operation as a critical section to ensure proper concurrency
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Name = $Name
                    Server = $env:COMPUTERNAME
                    ScriptFile = $MyInvocation.PSCommandPath
                    Status = $Status
                    ScriptAst = $ScriptAst
                    StartDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if (-not $ParentActivity) {
                    if ($PSYSession.ActivityStack.Count -gt 0) {
                        $o.ParentID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1].ID
                    }
                }
                else {
                    $o.ParentID = $ParentActivity.ID
                }
                $this.CreateEntity('ActivityLog', $o)
                return $o
            })
    
            [void] $PSYSession.ActivityStack.Add($Activity)
            
            Write-PSYInformationLog $Message
            return $Activity
        }
        else {
            # Log activity end
            [void] $repo.CriticalSection({
                $Activity.Status = $Status
                $Activity.EndDateTime = Get-Date | ConvertTo-PSYNativeType
                $this.UpdateEntity('ActivityLog', $Activity)
            })
            $PSYSession.ActivityStack.Remove($Activity)
            
            # Log completion, including duration in seconds
            $startTime = [DateTime]::Parse($Activity.StartDateTime);
            $endTime = [DateTime]::Parse($Activity.EndDateTime);
            [TimeSpan] $duration = $endTime.Subtract($startTime)
            Write-PSYInformationLog "$Message in $($duration.TotalSeconds) sec"
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}