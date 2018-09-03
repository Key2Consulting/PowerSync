function Write-PSYQueryLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Query,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Param
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Write Log and output to screen
        if ($PSYSession.Initialized) {
            [void] $repo.CriticalSection({
                $logValue = ConvertTo-Json $Value
                if ($logValue) {
                    $logValue = $Value
                }
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Type = 'Query'
                    Name = $Name
                    Query = $Query
                    Param = ConvertTo-Json -InputObject $Param -Depth 5 -Compress
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1].ID
                }
                $this.CreateEntity('QueryLog', $o)
            })
        }
        # Don't output to console since queries can get rather large.
    }
    catch {
        Write-PSYErrorLog $_ "Error in Write-PSYQueryLog."
    }
}