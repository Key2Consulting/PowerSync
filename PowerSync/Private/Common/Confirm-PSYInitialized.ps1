function Confirm-PSYInitialized {
    [CmdletBinding()]
    param(
        [parameter(HelpMessage = "A boolean value is returned indicating whether the framework is initialized.", Mandatory = $false)]
        [switch] $NoTerminate
    )

    # If the session exists, and is initialized, return true.  Otherwise, return false (or error).
    if (-not $PSYSessionState -and $PSYSessionState.System.Initialized) {
        if ($NoTerminate) {
            return $false
        }
        else {
            Write-PSYException "PowerSync is not properly initialized. See Start-PSYMainActivity for more information."
        }
    }
    if ($NoTerminate) {
        return $true
    }
}