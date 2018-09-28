<#
.SYNOPSIS
Receives and executes a PowerSync Activity from a queue.

.DESCRIPTION
TODO

Multiple receivers can monitor the same queue for scalability purposes. Receivers can be hosted in variety of hosting platforms, including:
 - WebJobs
 - One or more Virtual Machines (up to one receiver per core, depending on network capacity)
 - Same desktop where the activity originated for development purposes.

.PARAMETER Queue
The queue to monitor.

.PARAMETER Continous
Process will never exist, and will continously monitor the queue indefinitely. When omitted (useful for development purposes), Receive-PSYActivity exits immediately and returns a Job.

.PARAMETER Throttle
Maximum number of parallel executions. Throtting is handled in the repository and applies to all receivers regardless of where they execute.

.EXAMPLE
Receive-PSYActivity -Queue 'MyQueue' -Continous -Throttle 5
Write-PSYHost "You will never see this message."

.EXAMPLE
$job = Receive-PSYActivity -Queue 'MyQueue' -Throttle 5
Write-PSYHost "You will see this message."
Receive-Job -Job $job

.NOTES
TODO
#>
function Invoke-PSYActivityHandler {
    param
    (
        [Parameter(HelpMessage = "The queue to monitor.", Mandatory = $true)]
        [string] $Queue,
        [Parameter(HelpMessage = "Will continously monitor the queue indefinitely.", Mandatory = $false)]
        [switch] $Continous,
        [Parameter(HelpMessage = "Maximum number of parallel executions", Mandatory = $false)]
        [int] $Throttle = 3
    )

    try {
        # Progress doesn't work well in an unattended environment.
        if (-not $PSYSession.UserInteractive) {
            $ProgressPreference = "SilentlyContinue"        # certain hosting environments will fail b/c they don't support Write-Progress
        }

        # Control parameters
        $queuePollingInterval = Get-PSYVariable -Name 'PSYQueuePollingInterval' -DefaultValue 5000
        
        $continueProcessing = $true
        while ($continueProcessing) {
            
            # If we're not processing continously, exit immediately once no more messages are available on the queue.
            if (-not $Continous) {
                $continueProcessing = $false
            }

            # While there are still messages on the queue
            $repo = New-FactoryObject -Repository
            $msg = $repo.CriticalSection({ $this.GetMessage($Queue) })

            while ($msg) {
                $scriptBlock = [Scriptblock]::Create($msg.ScriptBlock)
                Start-PSYActivity -Name "$($msg.Name) (Remote Execution)" -Async -ScriptBlock $scriptBlock | Wait-PSYActivity
                $msg = $repo.CriticalSection({ $this.GetMessage($Queue) })
            }
        }
    }
    catch {
        Write-PSYErrorLog $_
    }    
}