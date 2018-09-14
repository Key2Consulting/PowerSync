<#
.SYNOPSIS
Locks a PowerSync variable in the connected repository for exclusive access. The lock uses a mutex, which spans processes on the same computer.

.PARAMETER Name
Name of the variable. Variable names must be unique.

.PARAMETER ScriptBlock
The scriptblock to execute for the duration of the lock.

.PARAMETER Timeout
The duration to wait to acquire a lock on a variable. If timeout is exceeded, the lock will fail.

.EXAMPLE
Lock-PSYVariable -Name 'MyVar' -ScriptBlock {
    Write-PSYInformation 'Do something quick!'
}

.EXAMPLE
Set-PSYVariable -Name 'MyVar' -Value @{Prop1 = 123; Prop2 = 456}

.NOTES
A variable should be locked for the shortest amount of time possible. Think milliseconds, and not seconds or minutes.
#>
function Lock-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "Name of the variable. Variable names must be unique.", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "The scriptblock to execute for the duration of the lock.", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "The duration to wait to acquire a lock on a variable. If timeout is exceeded, the lock will fail.", Mandatory = $false)]
        [int] $Timeout = 5000
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Grab an exclusive lock on the variable name
        [object] $mutex = New-Object System.Threading.Mutex($false, "Global\PSY-$Name")
        [void] $mutex.WaitOne($Timeout)
        Write-PSYDebugLog -Message "Acquired mutex Global\PSY-$Name"
        
        # Lock the variable and execute the caller's code.
        Invoke-Command -ScriptBlock $ScriptBlock
    }
    catch {
        Write-PSYErrorLog $_
    }
    finally {
        $mutex.ReleaseMutex()
        Write-PSYDebugLog -Message "Released mutex Global\PSY-$Name"
    }
}