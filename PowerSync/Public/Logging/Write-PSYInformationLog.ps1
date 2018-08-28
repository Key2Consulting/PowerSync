function Write-PSYInformationLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Message,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Category
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository

        # Write Log and output to screen
        if ($PSYSession.Initialized) {
            [void] $repo.CriticalSection({
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Type = 'Information'
                    Category = $Category
                    Message = $Message
                    CreatedDateTime = Get-Date
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1]
                }
                $this.CreateEntity('InformationLog', $o)
            })
        }
        Write-Host -Message "Information: ($Category) $Message"
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Write-PSYInformationLog."
    }
}