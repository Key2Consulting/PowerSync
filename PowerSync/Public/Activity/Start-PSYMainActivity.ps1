function Start-PSYMainActivity {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ConnectScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Throttle = 5,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $ScriptTimeout = 0,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $DisableParallel,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $PrintVerbose
    )
    
    # The global context variable is used to store critical runtime information used by the PowerSync engine. The runtime options
    # can be set via the command-line, or stored in the repository Registry, the former taking precedence over the latter.
    [hashtable] $Ctx = @{
        System = @{
            Repository = $null                                          # reference to the connected repository
            ActivityStack = New-Object System.Collections.ArrayList     # all activity logs in stack formation
            ModulePath = "$(Resolve-Path -Path "$PSScriptRoot\..\")"
        }
        Option = @{
            Throttle = $Throttle
            ScriptTimeout = $ScriptTimeout
            DisableParallel = $DisableParallel
            PrintVerbose = $PrintVerbose
        }
        # State = @{}
    }

    # If any runtime options weren't explicitly passed, attempt to retrieve them from the Registry. This gives control
    # of the runtime in a production environment without changing code.
    # TODO: ENUMERATE THE FOLLOWING AND LOAD FROM REGISTRY WHERE EMPTY $MyInvocation.BoundParameters

    # First attempt to establish a connection to the repository
    try {
        # Establish connection to repository
        $Ctx.System.Repository = Invoke-Command $ConnectScriptBlock

        # 
    }
    catch {
        throw "Unable to connect to PowerSync repository with the ConnectionScriptBlock provided. $($_.Exception.Message)"
    }

    # Test the connection
    try {
        # TODO
    }
    catch {
        throw "Repository test failed. $($_.Exception.Message)"
    }

    # The main activity is really just another activity, with initialization capability (above).
    try {
        # Log activity start
        $a = Write-ActivityLog $ScriptBlock $Name 'Main Activity Started' 'Started'
    
        # Execute activity
        Invoke-Command -ScriptBlock $ScriptBlock -NoNewScope -ArgumentList $Args

        # Log activity end
        Write-ActivityLog $ScriptBlock $Name 'Main Activity Completed' 'Completed' $a
    }
    catch {
        Write-PSYExceptionLog $_ "Unable to start main activity '$Name'." -Rethrow
    }
}