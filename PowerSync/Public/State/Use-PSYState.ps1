function Use-PSYState {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Key,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $DefaultValue,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Overwrite
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        if ($DefaultValue -isnot [hashtable] -and $DefaultValue -isnot [System.Collections.ArrayList]) {
            throw "Only hashtables and array lists of hashtables are supported."
        }
        
        # If the state isn't present, load and attach it now.
        if (-not $Ctx.State."$Key") {
            $Ctx.State."$Key" = $DefaultValue
        }
        return $Ctx.State."$Key"
    }
    catch {
        throw "Error using state $Key. $($_.Exception.Message)"
    }
}