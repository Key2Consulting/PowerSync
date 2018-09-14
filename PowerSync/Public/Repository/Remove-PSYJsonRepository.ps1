<#
.SYNOPSIS
Removes or deletes a Json repository from disk.

.DESCRIPTION
PowerSync uses a repository to manage all of its configuration and state, and must be connected to a repository in order to function. Connecting is the first operation performed by any PowerSync project.

A Json repository is a convenient way to get up and running with PowerSync without much overhead. Json files are limited, so for more complex projects, use a database repository (i.e. Connect-PSYOleDbRepository).

.PARAMETER Path
Path of the Json file, the repository, to delete. If just a filename is specified, will resolve to the current working folder.

.EXAMPLE
Remove-PSYJsonRepository -Path 'MyLocalFile.json'
 #>
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
        Write-PSYErrorLog $_
    }
}