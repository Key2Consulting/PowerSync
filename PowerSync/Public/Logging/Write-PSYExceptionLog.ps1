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
        $repo = New-RepositoryFromFactory       # instantiate repository
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
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1]
                }
                $this.CreateEntity('ExceptionLog', $o)
            })            
        }
        # Print to console
        if ($ErrorRecord) {
            Write-Error -ErrorRecord $ErrorRecord -ErrorAction Continue     # we continue so we can append the full stack trace
            Write-Host $stackTrace -ForegroundColor Red
            if ($ErrorActionPreference -eq "Stop") {        # if a terminating error, throw it again.
                throw $ErrorRecord
            }
        }
        else {
            Write-Host -Object $exception -ForegroundColor DarkRed -ErrorAction Continue     # we continue so we can append the full stack trace
            Write-Host $stackTrace -ForegroundColor Red
            if ($ErrorActionPreference -eq "Stop") {        # if a terminating error, throw it again.
                throw $exception
            }
        }
    }
    catch {
        # PSY must not be initialized, so at least display something
        Write-Error -ErrorRecord $_
        Write-Error -ErrorRecord $ErrorRecord
    }
}