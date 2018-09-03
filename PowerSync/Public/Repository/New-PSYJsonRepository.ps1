function New-PSYJsonRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path
    )

    try {
        $null = New-Item $Path
        Connect-PSYJsonRepository -Path $Path
        Set-PSYVariable -Name 'PSYDefaultCommandTimeout' -Value 3600 -UserType 'Environment'
        Set-PSYVariable -Name 'PSYDefaultThrottle' -Value 5 -UserType 'Environment'
        Set-PSYVariable -Name 'PSYStoredCommandPath' -Value '' -UserType 'Environment'
        Disconnect-PSYRepository
    }
    catch {
        Write-PSYErrorLog $_ "Error creating JSON repository."
    }
}