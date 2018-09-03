function Lock-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Timeout = 5000
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Grab an exclusive lock on the variable name
        [object] $mutex = New-Object System.Threading.Mutex($false, "PSY-$Name")
        [void] $mutex.WaitOne($Timeout)
        
        # Lock the variable and execute the caller's code.
        Invoke-Command -ScriptBlock $ScriptBlock
    }
    catch {
        Write-PSYErrorLog $_ "Error locking state '$Name'."
    }
    finally {
        $mutex.ReleaseMutex()
    }
}