<#
.SYNOPSIS
Removes or deletes a Json repository from disk.

.DESCRIPTION
PowerSync uses a repository to manage all of its configuration and state, and must be connected to a repository in order to function. Connecting is the first operation performed by any PowerSync project.

A Json repository is a convenient way to get up and running with PowerSync without much overhead. Json files are limited, so for more complex projects, use a database repository (i.e. Connect-PSYOleDbRepository).

.PARAMETER Path
Path of the Json repository to delete. If just a filename is specified, will resolve to the current working folder.

.EXAMPLE
Remove-PSYJsonRepository -Path 'MyLocalFile.json'
 #>
function Remove-PSYJsonRepository {
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    try {
        Remove-Item $Path -ErrorAction SilentlyContinue

        # Build paths to each store type.
        $activityPath = Join-Path -Path $RootPath -ChildPath "PSYActivity.json"
        $errorLogPath = Join-Path -Path $RootPath -ChildPath "PSYErrorLog.json"
        $messageLogPath = Join-Path -Path $RootPath -ChildPath "PSYMessageLog.json"
        $variableLogPath = Join-Path -Path $RootPath -ChildPath "PSYVariableLog.json"
        $queryLogPath = Join-Path -Path $RootPath -ChildPath "PSYQueryLog.json"
        $variablePath = Join-Path -Path $RootPath -ChildPath "PSYVariable.json"
        $connectionPath = Join-Path -Path $RootPath -ChildPath "PSYConnection.json"

        # Remove the files, if they exist.
        Remove-Item $errorLogPath -ErrorAction SilentlyContinue
        Remove-Item $messageLogPath -ErrorAction SilentlyContinue
        Remove-Item $variableLogPath -ErrorAction SilentlyContinue
        Remove-Item $queryLogPath -ErrorAction SilentlyContinue
        Remove-Item $activityPath -ErrorAction SilentlyContinue
        Remove-Item $connectionPath -ErrorAction SilentlyContinue
        Remove-Item $variablePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-PSYErrorLog $_
    }
}