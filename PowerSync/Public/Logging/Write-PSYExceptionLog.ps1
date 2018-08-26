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

        if ((Confirm-PSYInitialized -NoTerminate)) {
            $PSYSessionRepository.LogException($PSYSessionState.System.ActivityStack[$PSYSessionState.System.ActivityStack.Count - 1], $Message, $exception, $stackTrace)
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