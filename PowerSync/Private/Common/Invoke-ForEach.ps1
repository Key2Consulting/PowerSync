function Invoke-ForEach {
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [object] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name = 'Invoke-ForEach {0}',
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $ParentActivity,
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
                PSYSession = $PSYSession
                DebugPreference = $DebugPreference
                VerbosePreference = $VerbosePreference
                ErrorActionPreference = $ErrorActionPreference
                ForceDebug = $ForceDebug
            }
            if ($ScriptBlock -is [array]) {                                 # ScriptBlocks can either be a single definition, or an array of different definitions, one per pipeline item.
                $workItem.ScriptBlock = $ScriptBlock[$index]
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
                #$UserModules = @( Get-Module | Where-Object {$_.Path -notmatch 'PowerSync' -and (Test-Path $_.Path -ErrorAction SilentlyContinue)} | Select-Object -ExpandProperty Path )
                #$UserFunctions = @( Get-ChildItem function:\ | Where-Object { $StandardUserEnv.Functions -notcontains $_.Name } )
                #$sessionstate.Commands.Add((New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $FunctionDef.Name,$FunctionDef.ScriptBlock))

                $workItem.Job = (Start-Job -ArgumentList $workItem -Verbose -Debug -ScriptBlock {
                    param ($workItem)
                    
                    # Initialize environment
                    if ($workItem.ForceDebug) {
                        Wait-Debugger       # if the ForceDebug option is set in Invoke-ForEach, will break here. Step into Invoke-Command to debug client code.
                    }
                    Import-Module $workItem.PSYSession.Module
                    $global:PSYSession = $workItem.PSYSession
                    $PSYSession.UserModules | ForEach-Object { Import-Module $_ }       # load any user modules
                    Set-Location -Path $PSYSession.WorkingFolder    # default to parent session's working folder
                   
                    # Without setting these preferences, this output won't get returned
                    $DebugPreference = $workItem.DebugPreference
                    $VerbosePreference = $workItem.VerbosePreference

                    # Execute the input scriptblock
                    $scriptBlock = [Scriptblock]::Create($workItem.ScriptBlock)     # only the text was serialized, not the object, so reconstruct
                    Invoke-Command -ScriptBlock $scriptBlock -InputObject $workItem.InputObject     # run client code
                })
                Write-PSYDebugLog ("$($Name): Job Running {1}" -f $workItem.Index, $workItem.Job.InstanceId)
                # If this is being run as part of an activity, log each invocation as a separate activity
                if ($ParentActivity) {
                    $workItem.Activity = Write-ActivityLog -ScriptAst $workItem.ScriptBlock.Ast.ToString() -Name ($Name -f $workItem.Index) -Message ("Activity '$Name' started" -f $workItem.Index) -Status 'Started' -ParentActivity $ParentActivity
                }
            }
            else {      # Else not parallel
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
                    Write-PSYErrorLog $_
                }
                Write-PSYDebugLog ("$($Name): Sequential" -f $workItem.Index)
            }

            if ($workItem.ForceDebug -and $Parallel) {
                Start-Sleep -Milliseconds 500       # isn't there a better way?
                Debug-Job $workItem.Job
            }
        }
        catch {
            Write-PSYErrorLog $_
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
                        Write-Progress -Activity ("$($Name)" -f $_.Index) -PercentComplete ($completedJobs.Count / $workItems.Count * 100)
                        Write-PSYDebugLog -Message ("$($Name): Completed (Processed {1} out of {2})" -f $_.Index, $completedJobs.Count, $workItems.Count)
                        # If this is being run as part of an activity, complete activity log
                        if ($ParentActivity) {
                            Write-ActivityLog -Name ($Name -f $_.Index) -Message ("Activity '$Name' completed" -f $_.Index) -Status 'Completed' -Activity $_.Activity
                        }        
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
                # If errors and the current error action is to stop, we should do just that. Otherwise processing would continue.
                if ($item.Job.ChildJobs[0].Error.Count -gt 0 -and $ErrorActionPreference -eq "Stop") {
                    throw $item.Job.ChildJobs[0].Error
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