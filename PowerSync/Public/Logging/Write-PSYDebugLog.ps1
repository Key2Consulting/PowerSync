function Write-PSYDebugLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Message,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Category
    )

    try {
        $repo = New-FactoryObject -Repository               # instantiate repository

        # Write Log and output to screen    
        if ($PSYSession.Initialized) {
            [void] $repo.CriticalSection({
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Type = 'Debug'
                    Category = $Category
                    Message = $Message
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1].ID
                }
                $this.CreateEntity('InformationLog', $o)
            })
        }
        Write-Debug -Message "Debug: $Category $Message"
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Write-PSYDebugLog."
    }

}