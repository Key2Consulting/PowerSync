function New-PSYJsonRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path
    )

    try {
        $null = New-Item $Path
        Connect-PSYJsonRepository -Path $Path
        Set-PSYRegistry -Name 'PSYDefaultCommandTimeout' -Value 3600
        Set-PSYRegistry -Name 'PSYDefaultThrottle' -Value 5
        Disconnect-PSYRepository
    }
    catch {
        Write-PSYExceptionLog $_ "Error creating JSON repository."
    }
}