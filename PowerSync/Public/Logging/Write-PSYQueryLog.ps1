function Write-PSYQueryLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Connection,
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
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Type = 'Query'
                    Name = $Name
                    Connection = $Connection
                    Query = $Query
                    Param = ConvertTo-Json -InputObject $Param -Depth 3 -Compress
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if ($o.Param.Length -gt 2000) {
                    $o.Param = $o.Param.Substring(0, 2000);
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