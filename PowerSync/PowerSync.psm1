# Manually load private modules since the order they are loaded matters. Attempting to do this dynamically (as depicted below) results
# in random dependency errors.
. "$PSScriptRoot\Private\Common\Model.ps1"
. "$PSScriptRoot\Private\Repository\Repository.ps1"
. "$PSScriptRoot\Private\Repository\JsonRepository.ps1"
. "$PSScriptRoot\Private\Common\Core.ps1"

# Dynamically load all of our dependent modules, separating Public from Private functionality (public gets exported).
$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse)
#$Private = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse)

#@($Public + $Private) | ForEach-Object {
@($Public) | ForEach-Object {
    try {
        . $_.FullName
    } catch {
        Write-Error -Message "Failed to import function $($_.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName