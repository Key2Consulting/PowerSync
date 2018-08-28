Set-StrictMode -Version latest
Trap {"Error: $_"; Break;}

# The global context variable is used to store critical runtime information used by the PowerSync engine. The global session
# used primarily during activity execution to pass state between activities and to store the repository connection information. 
# Only serializable objects should be placed in the Session since PowerSync passes the state to Jobs for parallel processing 
# using PowerShell serialization / type conversion.
#
# NOTE: The design intentionally avoids saving state within classes since PowerShell has some major issues with thread safety
# when attempting to marshal classes to other processes (apparently due to scriptblock affinity and serialization woes). Classes
# are also incompatible with RunSpaces. Therefore, all the classes are designed to be recreated for every cmdlet invoked by clients,
# and do not attempt to maintain their state in between invocations. It breaks the principle of encapsulation, but there doesn't seem
# to be a better way considering PowerShell kept freezing up at any significant load. Tried PoshRSJob, Invoke-Parallel, and rolling our
# own custom runspace.

[hashtable] $global:PSYSession = @{
    Initialized = $false                                        # indicates whether PowerSync is ready for use
    RepositoryState = @{}                                       # stores connection information when connecting to a repository
    ActivityStack = New-Object System.Collections.ArrayList     # all activity logs in stack formation
    Module = "$PSScriptRoot"                                    # where we're located
    UserModules = New-Object System.Collections.ArrayList       # loaded modules so subsequent jobs can bootstrap
    WorkingFolder = "$(Get-Location)"                           # where the PowerSync module is located
}

# Import Local Module Dependencies
#Import-Module "$PSScriptRoot\Private\Library\Newtonsoft.Json"

# REFERENCES
# https://github.com/PowerShell/PowerShell/issues/3173
# https://stackoverflow.com/questions/3563262/how-to-make-c-sharp-powershell-invoke-member-thread-safe
# https://stackoverflow.com/questions/31051103/how-to-export-a-class-in-powershell-v5-module
# https://github.com/proxb/PoshRSJob
# https://github.com/RamblingCookieMonster/Invoke-Parallel