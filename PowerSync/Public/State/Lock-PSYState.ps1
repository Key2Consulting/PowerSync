function Lock-PSYState {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)

        # Grab an exclusive lock on the variable name
        [object] $mutex = New-Object System.Threading.Mutex($false, "PSY-$Name")
        $null = $mutex.WaitOne()
        
        # Retrieve the variable from state and execute the caller's code.
        $var = $Ctx.System.Repository.GetState($Name)
        Invoke-Command -ArgumentList $var -ScriptBlock $ScriptBlock
    }
    catch {
        Write-PSYExceptionLog $_ "Error getting state '$Name'." -Rethrow
    }
    finally {
        $mutex.ReleaseMutex()
    }
}