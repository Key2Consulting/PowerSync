# Kept here for reference purposes in case the project switches from Jobs to RunSpaces.  However, RunSpaces gave a lot of problems
# mainly freezing up at runtime during high loads.  The tests used synchronized lists and simple serializable data type (no class
# as POSH classes are not threadsafe), but still couldn't get it to work.  Also tried PoshRSJobs and Invoke-Parallel, same issue.
function Invoke-RSForEach {
    [CmdletBinding()]
    param
    (
        [parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Throttle = 10,        # $env:NUMBER_OF_PROCESSORS + 1
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Parallel
    )

    begin {
        # Initialize RunSpacePool to handle parallelization.
        # https://blogs.technet.microsoft.com/heyscriptingguy/2015/11/28/beginning-use-of-powershell-runspaces-part-3/
        [void] [runspacefactory]::CreateRunspacePool()
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
        $runspacePool.ApartmentState = 'STA'
        $jobs = New-Object System.Collections.ArrayList
        $runspacePool.Open()
        $index = 0

        # Avoids confirmation prompts during logging.
        if ($DebugPreference -eq 'Inquire') {
            $DebugPreference = 'Continue'
        }
        if ($VerbosePreference -eq 'Inquire') {
            $VerbosePreference = 'Continue'
        }
        #$ErrorActionPreference = 'Stop'        # let the caller deceide how to deal with exceptions
    }

    process {
        try {
            # Package up all of the required state as a collection of job items. Enumerate all jobs, and asynchrously execute them.
            #
            $job = [hashtable]::Synchronized(@{})
            #$job.InputObject = $o
            $job.ScriptBlock = $ScriptBlock.ToString()
            $job.Index = $index
            #$job.PSYSessionSerializedData = Copy-ObjectToStream $PSYSession      # Posh classes are not threadsafe, so we copy the entire session and serialize/deserialize repository
            $job.DebugPreference = $DebugPreference
            $job.VerbosePreference = $VerbosePreference
            $job.ErrorActionPreference = $ErrorActionPreference

            if ($ScriptBlock -is [array]) {                                 # ScriptBlocks can either be a single definition, or an array of different definitions, one per pipeline item.
                #ScriptBlock = $ScriptBlock[$index].ToString()
            }
            # We can't use the original scriptblock because PowerShell forces it to run in the original runspace (i.e. single threaded). A
            # workaround is to recreate the scriptblocks (unless parallel processing is disabled).
            if ($Parallel) {
                #$workItem.ScriptBlock = [Scriptblock]::Create($ScriptBlock.ToString())
            }
            [void] $jobs.Add($job)
            $index += 1

            # The POSH instance tied to this job
            $powerShell = [PowerShell]::Create()
            $powerShell.RunspacePool = $runspacePool

            # Add a boostrap script which will handle the parameter negotiation and initialization
            [void] $powerShell.AddScript({
                param ($job)
                try {
                    # Module dependencies
                    Import-Module 'C:\Users\Dan\Dropbox\Project\Key2\PowerSync\PowerSync'

                    # Without setting these preferences, this output won't get printed in the console
                    #$DebugPreference = $job.DebugPreference
                    #$VerbosePreference = $job.VerbosePreference
                    #$ErrorActionPreference = $job.ErrorActionPreference
                    
                    # Reconstitute repository from serialization stream
                    #$script:PSYSession = Copy-ObjectFromStream $job.PSYSessionSerializedData
                    
                    # Default Posh serialization converts our class to a PSObject, so we use that state data to deserialize into class instance.
                    #$PSYSession = & (Get-Module 'PowerSync').NewBoundScriptBlock({        # https://stackoverflow.com/questions/31051103/how-to-export-a-class-in-powershell-v5-module
                    #    [Repository]::Deserialize($PSYSessionRepository)
                    #})
                    Start-PSYMainActivity -ConnectScriptBlock {
                        Connect-PSYJsonRepository -ConfigurationPath "Configuration$($job.Index)" -LogPath "Log$($job.Index)"
                    } -Name 'Test Concurrency' -ScriptBlock {
                        Write-PSYVerboseLog "foo1 "
                        Write-PSYVerboseLog "foo2 "
                        Write-PSYVerboseLog "foo3 "
                        #$scriptBlock = [Scriptblock]::Create($job.ScriptBlock)
                        Start-PSYActivity -ScriptBlock {Write-PSYVerboseLog 'world'} -Name "Invoke-ForEach Started"
                        #Invoke-Command -ArgumentList $job.InputObject -ScriptBlock $job.ScriptBlock
                        #Write-ActivityLog -ScriptBlock {Write-Host 'Hello World'} -Name "Invoke-ForEach Completed" -Status 'Completed' -Activity $a
                    }                                        

                    "hello world"

                    #$a = Write-ActivityLog -ScriptBlock $job.ScriptBlock -Name "Invoke-ForEach [$($job.Index)] Started" -Status 'Started'
                    #Start-PSYActivity -ScriptBlock $job.ScriptBlock -Name "Invoke-ForEach [$($job.Index)] Started"
                    #Invoke-Command -ArgumentList $job.InputObject -ScriptBlock $job.ScriptBlock
                    #Write-ActivityLog -ScriptBlock $job.ScriptBlock -Name "Invoke-ForEach [$($job.Index)] Completed" -Status 'Completed' -Activity $a

                    # Initialize PSYSession. The session MUST BE threadsafe, or it will cause unpredictable runtime errors. The
                    # repository is not threadsafe, so we must clone it.
                    #$global:PSYSession = Copy-ObjectFromStream $job.PSYSessionStream
                    #Start-Sleep -Seconds 5
                    #Write-Debug 'Yada Yada Yada Again'
                    #throw "don't try it"
                    #$PSYSessionRepository.LogInformation($PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1], "HELLO WORLD", 'TODAY')
                    #$PSYSessionRepository = [Repository]::Deserialize($PSYSession.SerializedData)

                    #$PSYSessionRepository.LogInformation($PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1], "HELLO WORLD", 'TODAY')
                    <#
                    Start-PSYMainActivity -ConnectScriptBlock {
                        Connect-PSYJsonRepository
                    } -Name 'Test Concurrency' -ScriptBlock {
                        $PSYSessionRepository.LogInformation($PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1], "HELLO WORLD", 'TODAY')
                    }
                    #>
                    #$threadID = [appdomain]::GetCurrentThreadId()
                    #$processID = $PID
                    #Start-Sleep -Seconds 2
                }
                catch {
                    Write-Host $_.Exception
                }
                #Write-PSYDebugLog "ThreadID: $threadID ($processID)"
                #Get-Variable -Scope 'Global'
                #Invoke-Command -InputObject $job.InputObject -ScriptBlock $job.ScriptBlock
            }, $true)       # https://learn-powershell.net/2018/01/28/dealing-with-runspacepool-variable-scope-creep-in-powershell/
        
            [void] $powerShell.AddParameters(@{Job = $job})       # pass all of the job information to the script so it can do its thing
            $job.PowerShell = $powerShell
            $job.Handle = $powerShell.BeginInvoke()     # start the job

            #Write-PSYDebugLog "Available Runspaces: $($runspacePool.GetAvailableRunspaces())"
            #$remaining = @($jobs | Where-Object {$_.handle.IsCompleted -ne 'Completed'}).Count
            #Write-PSYDebugLog "Remaining Jobs: $remaining"
        }
        catch {
            throw
        }
    }

    end {
        # Wait for the jobs to complete
        foreach ($job in $jobs) {
            try {
                #Start-Sleep -Seconds 3
                $job.ReturnValue = $job.Powershell.EndInvoke($job.handle)       # if the script errors, will bubble up in this call
                # TODO: Enum output streams, write to log
            }
            catch {
                $job.Exception = $_
                Write-PSYErrorLog -ErrorRecord $_ -Message 'Error in Invoke-ForEach'
            }
            finally {
                $job.PowerShell.Dispose()
            }
            Write-Debug "Job $($job.Index): Returned $($job.ReturnValue), HadErrors $($job.PowerShell.HadErrors)"
            $j = $jobs[0].PowerShell
            $r = $jobs[0].ReturnValue
    
        }
        $jobs
    }


<#
        $jobs = ($workItems | Start-RSJob -VariablesToImport 'Ctx' -Throttle $PSYSession.Option.Throttle -ScriptBlock {
            Start-Sleep -Seconds 1      # somehow this avoids the "You cannot call a method on a null-valued expression." error
            Write-PSYInformationLog "here"
            #$a = Write-ActivityLog $_.ScriptBlock $Name "Start-PSYForEachActivity [$($_.Index)] Started" 'Started'
            #Invoke-Command -ArgumentList $_.InputObject -ScriptBlock $_.ScriptBlock
            #Write-ActivityLog $_.ScriptBlock $Name "Start-PSYForEachActivity [$($_.Index)] Completed" 'Completed' $a
        } | Wait-RSJob)
        #$x = $jobs[0] | Select-Object *
        
        #$modules = Get-Module | Select-Object -ExpandProperty Name
        #$functions = Get-ChildItem function:\ | Select-Object -ExpandProperty Name
        #$variables = Get-Variable | Select-Object -ExpandProperty Name

        # Execute each (new) script block in parallel, importing all variables and modules.
        $workItems | Invoke-Parallel -ImportVariables -ImportModules -ImportFunctions -Throttle $PSYSession.Option.Throttle -RunspaceTimeout $PSYSession.Option.ScriptTimeout -ScriptBlock {
            Write-PSYInformationLog "here"
            #$a = Write-ActivityLog $_.ScriptBlock $Name "$logTitle [$($_.Index)] Started" 'Started'
            #Invoke-Command -ArgumentList $_.InputObject -ScriptBlock $_.ScriptBlock
            #Write-ActivityLog $_.ScriptBlock $Name "$logTitle [$($_.Index)] Completed" 'Completed' $a
        }
#>
<#
    }
    catch {
        Write-PSYErrorLog $_ "Error in Invoke-ForEach."
    }
#>
}

