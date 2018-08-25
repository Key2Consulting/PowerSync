function Import-PSYTextFile {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path,
        [string] $Format,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Header
    )

    try {
        # Validation
        Confirm-PSYInitialized
        
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Import-PSYTextFile."
    }
}