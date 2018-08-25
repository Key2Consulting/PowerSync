function Start-PSYMainActivity {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ConnectScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Throttle = 10,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $ScriptTimeout = 0,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $QueryTimeout = 0,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Parallel
    )
    
    # If any runtime options weren't explicitly passed, attempt to retrieve them from the Registry. This gives control
    # of the runtime in a production environment without changing code.
    # TODO: ENUMERATE THE FOLLOWING AND LOAD FROM REGISTRY WHERE EMPTY $MyInvocation.BoundParameters

    # The global context variable is used to store critical runtime information used by the PowerSync engine. The global session
    # used primarily during activity execution to pass state between activities. The runtime options can be set via the command-line, 
    # or stored in the repository Registry, the former taking precedence over the latter. Only serializable objects should be placed
    # in Session State since PSY passes the state to Jobs.
    [hashtable] $PSYSessionState = @{
        System = @{
            ActivityStack = New-Object System.Collections.ArrayList     # all activity logs in stack formation
            ModulePath = "$(Resolve-Path -Path "$PSScriptRoot\..\")"    # where we are located
            Initialized = $false
            WorkingFolder = "$(Get-Location)"
        }
        Option = @{
            Throttle = 10                # max parallel processes
            ScriptTimeout = 5000        # milliseconds
            QueryTimeout = 3600         # seconds
        }
    }
    # Keep the repository out of session state since it doesn't support default POSH serialization.
    [Repository] $PSYSessionRepository = $null
    # First attempt to establish a connection to the repository
    try {
        # Establish connection to repository
        $PSYSessionRepository = Invoke-Command $ConnectScriptBlock
        $PSYSessionState.System.Initialized = $true
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
        Write-PSYExceptionLog $_ "Error in Main Activity '$Name'."
    }
}