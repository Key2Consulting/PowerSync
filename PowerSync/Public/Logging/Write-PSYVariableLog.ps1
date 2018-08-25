function Write-PSYVariableLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Value
    )

    # Write Log and output to screen
    if ((Confirm-PSYInitialized -NoTerminate)) {
        $PSYSessionRepository.LogVariable($PSYSessionState.System.ActivityStack[$PSYSessionState.System.ActivityStack.Count - 1], $Name, $Value)
    }
    Write-Verbose -Message "Variable: $Name = $Value"
}