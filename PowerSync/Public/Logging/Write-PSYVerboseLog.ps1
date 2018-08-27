function Write-PSYVerboseLog {
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
            $repo.LogInformation($PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1], $Category, $Message)
        }
        Write-Verbose -Message "Information Verbose: ($Category) $Message"
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Write-PSYVerboseLog."
    }
}