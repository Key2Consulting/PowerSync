<#
.SYNOPSIS
Connects to a Json repository.

.DESCRIPTION
PowerSync uses a repository to manage all of its configuration and state, and must be connected to a repository in order to function. Connecting is the first operation performed by any PowerSync project.

A Json repository is a convenient way to get up and running with PowerSync without much overhead. Json files are limited, so for more complex projects, use a database repository (i.e. Connect-PSYOleDbRepository).

.PARAMETER Path
Path of the Json repository to connect to. If just a filename is specified, will resolve to the current working folder.

.PARAMETER Create
Automatically creates the repository if it doesn't exist.

.PARAMETER Recreate
Automatically recreates the repository if it doesn't exist, clearing any previous contents.

.PARAMETER LockTimeout
The timeout, in milliseconds, to wait for exclusive access to the repository before failing. You normally do not need to specify this parameter.

.EXAMPLE
Connect-PSYJsonRepository -RootPath 'MyLocalFile.json'
 #>
function Connect-PSYJsonRepository {
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $RootPath,
        [Parameter(Mandatory = $false)]
        [switch] $ClearLogs,
        [Parameter(Mandatory = $false)]
        [switch] $ClearActivities,
        [Parameter(Mandatory = $false)]
        [switch] $ClearConnections,
        [Parameter(Mandatory = $false)]
        [switch] $ClearVariables,
        [Parameter(Mandatory = $false)]
        [string] $LockTimeout = 30000
    )

    try {
        # Disconnect if already connected
        Disconnect-PSYRepository

        # Build paths to each store type.
        $activityPath = Join-Path -Path $RootPath -ChildPath "PSYActivity.json"
        $errorLogPath = Join-Path -Path $RootPath -ChildPath "PSYErrorLog.json"
        $messageLogPath = Join-Path -Path $RootPath -ChildPath "PSYMessageLog.json"
        $variableLogPath = Join-Path -Path $RootPath -ChildPath "PSYVariableLog.json"
        $queryLogPath = Join-Path -Path $RootPath -ChildPath "PSYQueryLog.json"
        $variablePath = Join-Path -Path $RootPath -ChildPath "PSYVariable.json"
        $connectionPath = Join-Path -Path $RootPath -ChildPath "PSYConnection.json"

        # Remove the files for any store marked as clear.
        if ($ClearLogs) {
            Remove-Item $errorLogPath -ErrorAction SilentlyContinue
            Remove-Item $messageLogPath -ErrorAction SilentlyContinue
            Remove-Item $variableLogPath -ErrorAction SilentlyContinue
            Remove-Item $queryLogPath -ErrorAction SilentlyContinue
        }

        if ($ClearActivities) {
            Remove-Item $activityPath -ErrorAction SilentlyContinue
        }
        
        if ($ClearConnections) {
            Remove-Item $connectionPath -ErrorAction SilentlyContinue
        }

        if ($ClearVariables) {
            Remove-Item $variablePath -ErrorAction SilentlyContinue
        }

        # Create the files if they don't exist already.
        $null = New-Item -Path (Join-Path -Path $RootPath -ChildPath "PSYActivity.json") -ErrorAction SilentlyContinue -Value '[]' 
        $null = New-Item -Path (Join-Path -Path $RootPath -ChildPath "PSYErrorLog.json") -ErrorAction SilentlyContinue -Value '[]' 
        $null = New-Item -Path (Join-Path -Path $RootPath -ChildPath "PSYMessageLog.json") -ErrorAction SilentlyContinue -Value '[]' 
        $null = New-Item -Path (Join-Path -Path $RootPath -ChildPath "PSYVariableLog.json") -ErrorAction SilentlyContinue -Value '[]' 
        $null = New-Item -Path (Join-Path -Path $RootPath -ChildPath "PSYQueryLog.json") -ErrorAction SilentlyContinue -Value '[]' 
        $null = New-Item -Path (Join-Path -Path $RootPath -ChildPath "PSYVariable.json") -ErrorAction SilentlyContinue -Value '[]' 
        $null = New-Item -Path (Join-Path -Path $RootPath -ChildPath "PSYConnection.json") -ErrorAction SilentlyContinue -Value '[]' 

        # Create the instance, passing it our session state. The class should set it's state properties to the session,
        # making the connection available on subsequent requests.
        $fullPath = Resolve-Path -Path $RootPath
        $repo = New-Object JsonRepository $fullPath, $LockTimeout, $PSYSession.RepositoryState
        $global:PSYSession.Initialized = $true

        # Ensure system defaults exist.
        if (-not (Get-PSYVariable -Name 'PSYDefaultCommandTimeout')) {
            Set-PSYVariable -Name 'PSYDefaultCommandTimeout' -Value 3600 -Category 'Environment'
        }
        if (-not (Get-PSYVariable -Name 'PSYDefaultThrottle')) {
            Set-PSYVariable -Name 'PSYDefaultThrottle' -Value 5 -Category 'Environment'
        }
        if (-not (Get-PSYVariable -Name 'PSYCmdPath')) {
            Set-PSYVariable -Name 'PSYCmdPath' -Value '' -Category 'Environment'
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}