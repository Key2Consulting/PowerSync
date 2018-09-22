<#
.SYNOPSIS
Creates a new Json repository.

.DESCRIPTION
PowerSync uses a repository to manage all of its configuration and state, and must be connected to a repository in order to function. Connecting is the first operation performed by any PowerSync project.

A Json repository is a convenient way to get up and running with PowerSync without much overhead. Json files are limited, so for more complex projects, use a database repository (i.e. Connect-PSYOleDbRepository).

.PARAMETER Path
Path of the Json file, the repository, to create. If just a filename is specified, will resolve to the current working folder.

.EXAMPLE
New-PSYJsonRepository -Path 'MyLocalFile.json'
 #>
function New-PSYJsonRepository {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path
    )

    try {
        $null = New-Item $Path
        Connect-PSYJsonRepository -Path $Path
        Set-PSYVariable -Name 'PSYDefaultCommandTimeout' -Value 3600 -Category 'Environment'
        Set-PSYVariable -Name 'PSYDefaultThrottle' -Value 5 -Category 'Environment'
        Set-PSYVariable -Name 'PSYCmdPath' -Value '' -Category 'Environment'
        Set-PSYVariable -Name 'PSYTempFolder' -Value "$PSYSession.WorkingFolder\Temp" -Category 'Environment'
        Disconnect-PSYRepository
    }
    catch {
        Write-PSYErrorLog $_
    }
}