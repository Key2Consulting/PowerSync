<#
.SYNOPSIS
Connects to a Json repository.

.DESCRIPTION
PowerSync uses a repository to manage all of its configuration and state, and must be connected to a repository in order to function. Connecting is the first operation performed by any PowerSync project.

A Json repository is a convenient way to get up and running with PowerSync without much overhead. Json files are limited, so for more complex projects, use a database repository (i.e. Connect-PSYOleDbRepository).

.PARAMETER Path
Path of the Json file, the repository, to connect to. If just a filename is specified, will resolve to the current working folder.

.PARAMETER LockTimeout
The timeout, in milliseconds, to wait for exclusive access to the repository before failing. You normally do not need to specify this parameter.

.EXAMPLE
Connect-PSYJsonRepository -Path 'MyLocalFile.json'
 #>
function Connect-PSYJsonRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $LockTimeout = 5000
    )

    try {
        # Disconnect if already connected
        Disconnect-PSYRepository

        # Create the instance, passing it our session state. The class should set it's state properties to the session,
        # making the connection available on subsequent requests.
        $fullPath = Resolve-Path -Path $Path
        $repo = New-Object JsonRepository $fullPath, $LockTimeout, $PSYSession.RepositoryState
        $global:PSYSession.Initialized = $true
    }
    catch {
        Write-PSYErrorLog $_
    }
}