function New-PSYJsonRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path
    )

    try {
        New-Item $Path
    }
    catch {
        Write-PSYExceptionLog $_ "Error creating JSON repository."
    }
}