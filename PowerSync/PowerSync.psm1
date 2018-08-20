 # Dynamically load all of our dependent modules, separating Public from Private functionality (public gets exported).
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse)

@($Public + $Private) | ForEach-Object {
    try {
        . $_.FullName
    } catch {
        Write-Error -Message "Failed to import function $($_.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName