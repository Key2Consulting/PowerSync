function Remove-PSYJsonRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path
    )

    try {
        Remove-Item $Path -ErrorAction SilentlyContinue
    }
    catch {
        Write-PSYErrorLog $_ "Error removing to JSON repository."
    }
}