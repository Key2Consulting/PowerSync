function Write-ActivityLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Title,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Status,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Activity
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository

        if ($Status -eq 'Started') {
            # Log activity start
            $Activity =  $repo.CriticalSection({        # execute the operation as a critical section to ensure proper concurrency
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Name = $Name
                    Server = $env:COMPUTERNAME
                    ScriptFile = $MyInvocation.PSCommandPath
                    Status = $Status
                    ScriptAst = $ScriptBlock.Ast.ToString()
                    StartDateTime = Get-Date | ConvertTo-PSYNativeType
                    Test = $PSYSession.ActivityStack
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ParentID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1]
                }
                $this.CreateEntity('ActivityLog', $o)
                return $o
            })
    
            [void] $PSYSession.ActivityStack.Add($Activity)
            
            Write-Host "$($Title): $Name"
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
            Write-Host "$($Title): $Name"
        }
    }
    catch {
        Write-PSYExceptionLog $_ "Error logging activity '$Name'." 
    }
}