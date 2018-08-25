function Write-PSYExceptionLog {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [System.Management.Automation.ErrorRecord] $ErrorRecord,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Message
    )

    try {
        # Write Log and output to screen
        if ($ErrorRecord) {
            $exception = $ErrorRecord.Exception.ToString()
            $stackTrace = $ErrorRecord.ScriptStackTrace
            $exceptionMsg = $ErrorRecord.Exception.Message
        }
        if ((Confirm-PSYInitialized -NoTerminate)) {
            $PSYSessionRepository.LogException($PSYSessionState.System.ActivityStack[$PSYSessionState.System.ActivityStack.Count - 1], $Message, $exception, $stackTrace)
        }
        if ($ErrorRecord) {
            Write-Error -ErrorRecord $ErrorRecord -ErrorAction Continue     # we continue so we can append the full stack trace
            Write-Host $stackTrace -ForegroundColor Red
            # If a terminating error, throw it again.
            if ($ErrorActionPreference -eq "Stop") {
                throw $ErrorRecord
            }
        }
    }
    catch {
        # PSY must not be initialized, so at least display something
        Write-Error -ErrorRecord $ErrorRecord
    }
}