function Lock-PSYStateVar {
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
        $repo = New-RepositoryFromFactory       # instantiate repository

        # Grab an exclusive lock on the variable name
        [object] $mutex = New-Object System.Threading.Mutex($false, "PSY-$Name")
        [void] $mutex.WaitOne($Timeout)
        
        # Retrieve the variable from state and execute the caller's code.
        $var = $repo.GetState($Name)
        Invoke-Command -ArgumentList $var -ScriptBlock $ScriptBlock
    }
    catch {
        Write-PSYExceptionLog $_ "Error locking state '$Name'."
    }
    finally {
        $mutex.ReleaseMutex()
    }
}