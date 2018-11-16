<#
.SYNOPSIS
Locks a PowerSync State Variable in the connected repository for exclusive access.

.DESCRIPTION
This function is designed to provide synchronization between processes. The lock uses a mutex, which spans processes on the same computer. 

The current version only supports local concurrency, but will not synchronize remote processing.

.PARAMETER Name
Name of the variable. Variable names must be unique. The variable name can be an actual PowerSync variable, or any contrived identifier you want to hold the lock.

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
A variable should be locked for the shortest amount of time possible. Think seconds, not minutes.
#>
function Lock-PSYVariable {
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(Mandatory = $false)]
        [int] $Timeout = 10000
    )

    try {
        # Grab an exclusive lock on the variable name
        [object] $mutex = [System.Threading.Mutex]::new($false, "PSY-$Name")
        [void] $mutex.WaitOne($Timeout)
        Write-PSYDebugLog -Message "Acquired mutex PSY-$Name"
        
        # Lock the variable and execute the caller's code.
        Invoke-Command -ScriptBlock $ScriptBlock
    }
    catch {
        Write-PSYErrorLog $_
    }
    finally {
        $mutex.ReleaseMutex()
        Write-PSYDebugLog -Message "Released mutex PSY-$Name"
    }
}