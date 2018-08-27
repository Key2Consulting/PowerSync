function New-PSYConnection {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $ConnectionString,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $ProviderType
    )

    try {
        
    }
    catch {
        Write-PSYExceptionLog $_ "Error in New-PSYConnection."
    }
}