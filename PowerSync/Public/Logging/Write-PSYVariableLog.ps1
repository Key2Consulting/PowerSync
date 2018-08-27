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
            $repo.LogVariable($PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1], $Name, $Value)
        }
        Write-Verbose -Message "Variable: $Name = $Value"
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Write-PSYVariableLog."
    }
}