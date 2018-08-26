function Invoke-ForEach {
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $LogTitle = 'Invoke-ForEach {0}',
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Throttle = 5,        # $env:NUMBER_OF_PROCESSORS + 1
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Timeout = 0,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Parallel,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $ForceDebug
    )

    begin {
        # Validation
        Confirm-PSYInitialized

        # Initialize processing variables
        $workItems = New-Object System.Collections.ArrayList     # to pass parameters, and track jobs while they're processing
        $index = 0

        # Avoids confirmation prompts during logging.
        if ($DebugPreference -eq 'Inquire') {
            $DebugPreference = 'Continue'
        }
        if ($VerbosePreference -eq 'Inquire') {
            $VerbosePreference = 'Continue'
        }
        #$ErrorActionPreference = 'Stop'        # let the caller decide how to deal with exceptions
    }

    process {
        try {
            # Package up all of the required state as a collection of job items. Enumerate all jobs, and asynchrously execute them.
            #
            $workItem = @{
                InputObject = $InputObject
                ScriptBlock = $ScriptBlock
                Index = $index
                SessionState = $PSYSessionState
                RepositorySerializedData = $PSYSessionRepository.Serialize()        # Posh classes are not threadsafe, so we copy the entire session and serialize/deserialize repository
                DebugPreference = $DebugPreference
                VerbosePreference = $VerbosePreference
                ErrorActionPreference = $ErrorActionPreference
                ForceDebug = $ForceDebug
            }
            if ($ScriptBlock -is [array]) {                                 # ScriptBlocks can either be a single definition, or an array of different definitions, one per pipeline item.
                ScriptBlock = $ScriptBlock[$index]
            }
            [void] $workItems.Add($workItem)
            $index += 1

            if ($Parallel) {
                # Job throttling (https://stackoverflow.com/questions/23552058/powershell-start-jobs-throttling)
                while (@(Get-Job -State Running).Count -ge $Throttle) {
                    $now = Get-Date
                    foreach ($job in @(Get-Job -State Running)) {
                        if ($Timeout) {
                            if ($now - (Get-Job -Id $job.id).PSBeginTime -gt [TimeSpan]::FromSeconds($Timeout)) {
                                Stop-Job $job
                            }
                        }
                    }
                    Start-Sleep -Milliseconds 500
                }

                # Invoke a job to handle item processing
                $workItem.Job = (Start-Job -ArgumentList $workItem -Verbose -Debug -ScriptBlock {
                    param ($workItem)
                    
                    # Initialize environment
                    if ($workItem.ForceDebug) {
                        Wait-Debugger       # if the ForceDebug option is set in Invoke-ForEach, will break here. Step into Invoke-Command to debug client code.
                    }
                    Import-Module $workItem.SessionState.System.Module
                    $global:PSYSessionState = $workItem.SessionState
                    $PSYSessionState.System.UserModules | ForEach-Object { Import-Module $_ }       # load any user modules
                    $global:PSYSessionRepository = & (Get-Module 'PowerSync').NewBoundScriptBlock({        # https://stackoverflow.com/questions/31051103/how-to-export-a-class-in-powershell-v5-module
                        [Repository]::Deserialize($workItem.RepositorySerializedData)
                    })
                    Set-Location -Path $PSYSessionState.System.WorkingFolder    # default to parent session's working folder
                   
                    # Without setting these preferences, this output won't get returned
                    $DebugPreference = $workItem.DebugPreference
                    $VerbosePreference = $workItem.VerbosePreference

                    # Execute the input scriptblock
                    $scriptBlock = [Scriptblock]::Create($workItem.ScriptBlock)     # only the text was serialized, not the object, so reconstruct
                    Invoke-Command -ScriptBlock $scriptBlock -InputObject $workItem.InputObject     # run client code
                })
                Write-PSYDebugLog ("$($LogTitle): Job Running {1}" -f $workItem.Index, $workItem.Job.InstanceId)
            }
            else {
                # Else, we're running sequentially. The primary reason for this is to make debugging client scripts
                # easier. We still need to imitate parallel processing and output the same values as before.
                try {
                    $r = Invoke-Command -ScriptBlock $workItem.ScriptBlock -InputObject $workItem.InputObject
                    $workItem.Result = $r
                    $workItem.HadErrors = $false
                    $workItem.Errors = @()
                }
                catch {
                    $workItem.HadErrors = $true
                    $workItem.Errors = $_
                    Write-PSYExceptionLog $_
                }
                Write-PSYDebugLog ("$($LogTitle): Sequential" -f $workItem.Index)
            }

            if ($workItem.ForceDebug -and $Parallel) {
                Start-Sleep -Milliseconds 500       # isn't there a better way?
                Debug-Job $workItem.Job
            }
        }
        catch {
            Write-PSYExceptionLog $_
        }
    }

    end {
        if ($Parallel) {
            # Wait for the jobs to complete
            $completedJobs = New-Object System.Collections.ArrayList
            while ($completedJobs.Count -lt $workItems.Count) {
                $workItems | ForEach-Object {
                    if ($_.Job.HasMoreData -or $_.Job.State -eq "Running") {
                        $j = Receive-Job -Job $_.Job -Verbose
                    }
                    elseif (-not $completedJobs.Contains($_.Job.InstanceId)) {
                        [void] $completedJobs.Add($_.Job.InstanceId)
                        $_.Result = $_.Job.ChildJobs[0].Output
                        Write-Progress -Activity ("$($LogTitle)" -f $_.Index) -PercentComplete ($completedJobs.Count / $workItems.Count * 100)
                        Write-PSYDebugLog -Message ("$($LogTitle): Completed (Processed {1} out of {2})" -f $_.Index, $completedJobs.Count, $workItems.Count)
                        # TODO: WRITE HAD ERRORS, EXCEPTIONS
                    }
                }
            }
            # Return results of job to caller
            foreach ($item in $workItems) {
                @{
                    InputObject = $item.InputObject
                    Result = $item.Result
                    HadErrors = [bool] $item.Job.ChildJobs[0].Error.Count
                    Errors = $item.Job.ChildJobs[0].Error
                }
            }
        }
        else {
            # Return results of job to caller. Sequential processing is slightly different.
            foreach ($item in $workItems) {
                @{
                    InputObject = $item.InputObject
                    Result = $item.Result
                    HadErrors = [bool] $item.HadErrors
                    Errors = $item.Errors
                }
            }
        }
    }
}