function Write-PSYExceptionLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [System.Management.Automation.ErrorRecord] $ErrorRecord,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Message
    )
    
    # Must be careful trying to connect to repository within an exception handler. The exception could
    # be caused by connectivity issues with the repository. If so, we disconnect before proceeding.
    $repo = $null
    try {
        $repo = New-FactoryObject -Repository -NoLockError       # instantiate repository
    }
    catch {
        Disconnect-PSYRepository
    }

    try {

        # Write Log and output to screen
        $exception = $null
        $stackTrace = $null
        if ($ErrorRecord) {
            $exception = $ErrorRecord.Exception.ToString()
            $stackTrace = $ErrorRecord.ScriptStackTrace
        }
        else {
            $exception = $Message
            $stackTrace = (Get-PSCallStack) -join '`r`n'
        }

        if (($PSYSession.Initialized)) {
            [void] $repo.CriticalSection({
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Message = $Message
                    Exception = $exception
                    StackTrace = $stackTrace
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1].ID
                }
                $this.CreateEntity('ExceptionLog', $o)
            })            
        }
        # Print to console
        if ($ErrorRecord) {
            Write-Error -ErrorRecord $ErrorRecord -ErrorAction Continue     # we continue so we can append the full stack trace
            Write-Host $stackTrace -ForegroundColor Red
        }
        else {
            Write-Host -Object $exception -ForegroundColor DarkRed -ErrorAction Continue     # we continue so we can append the full stack trace
            Write-Host $stackTrace -ForegroundColor Red
        }
    }
    catch {
        # PSY must not be initialized, so at least display something
        Write-Error -ErrorRecord $_
        Write-Error -ErrorRecord $ErrorRecord
    }

    # if a terminating error, throw it again.
    if ($ErrorRecord) {
        if ($ErrorActionPreference -eq "Stop") {
            throw $ErrorRecord
        }
    }
    else {
        if ($ErrorActionPreference -eq "Stop") {
            throw $exception
        }
    }    
}