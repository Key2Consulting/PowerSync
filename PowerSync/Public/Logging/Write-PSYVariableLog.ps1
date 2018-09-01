function Write-PSYVariableLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Value
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository
        
        # Write Log and output to screen
        if ($PSYSession.Initialized) {
            [void] $repo.CriticalSection({
                $logValue = ConvertTo-Json $Value
                if ($logValue) {
                    $logValue = $Value
                }
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    VariableName = $Name
                    VariableValue = $logValue
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1].ID
                }
                $this.CreateEntity('VariableLog', $o)
            })
    }
        Write-Verbose -Message "Variable: $Name = $Value"
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Write-PSYVariableLog."
    }
}