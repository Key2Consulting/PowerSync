Set-StrictMode -Version latest
Trap {"Error: $_"; Break;}

# The global context variable is used to store critical runtime information used by the PowerSync engine. The global session
# used primarily during activity execution to pass state between activities. The runtime options can be set via the command-line, 
# or stored in the repository Registry, the former taking precedence over the latter. Only serializable objects should be placed
# in Session State since PSY passes the state to Jobs.
[hashtable] $global:PSYSessionState = @{
    System = @{
        ActivityStack = New-Object System.Collections.ArrayList     # all activity logs in stack formation
        Module = "$PSScriptRoot"        # where we're located
        UserModules = New-Object System.Collections.ArrayList       # loaded modules so subsequent jobs can bootstrap
        Initialized = $false
        WorkingFolder = "$(Get-Location)"
    }
    Option = @{
        Throttle = 10               # max parallel processes
        ScriptTimeout = 5000        # milliseconds
        QueryTimeout = 3600         # seconds
    }
}
# Keep the repository out of session state since it doesn't support default POSH serialization.
[Repository] $global:PSYSessionRepository = $null