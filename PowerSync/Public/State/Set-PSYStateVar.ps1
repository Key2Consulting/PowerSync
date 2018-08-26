function Set-PSYStateVar {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Value,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [ContainerType] $ContainerType = 'Scalar'
    )

    try {
        # Validation
        Confirm-PSYInitialized

        # Log
        Write-PSYVariableLog $Name $Value

        # Set the state in the repository.  If it doesn't exist, it will be created.
        $PSYSessionRepository.SetState($Name, $Value, $ContainerType)
    }
    catch {
        Write-PSYExceptionLog $_ "Error setting state '$Name'."
    }
}