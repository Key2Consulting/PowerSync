function Remove-PSYConnection {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Remove-PSYConnection." 
    }
}