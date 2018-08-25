function Write-PSYVerboseLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Message,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Category
    )

    # Write Log and output to screen
    if ((Confirm-PSYInitialized -NoTerminate)) {
        $PSYSessionRepository.LogInformation($PSYSessionState.System.ActivityStack[$PSYSessionState.System.ActivityStack.Count - 1], $Category, $Message)
    }
    Write-Verbose -Message "Information Verbose: ($Category) $Message"
}