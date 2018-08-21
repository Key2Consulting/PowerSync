function Register-PSYState {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [StateType] $Type = [StateType]::Discrete,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Default = "hello",
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $CustomType,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Overwrite
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        #if ($Default -isnot [hashtable] -and $Default -isnot [System.Collections.ArrayList]) {
        #    throw "Only hashtables and array lists of hashtables are supported."
        #}
        
        # Register the state in the repository
        return $Ctx.System.Repository.RegisterState($Name, $Default, $Type, $CustomType)
    }
    catch {
        throw "Error using state $Name. $($_.Exception.Message)"
    }
}