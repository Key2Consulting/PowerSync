function Write-PSYExceptionLog {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [System.Management.Automation.ErrorRecord] $ErrorRecord,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Message,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Rethrow
    )

    # Validation
    Confirm-PSYInitialized($Ctx)

    # Write Log and output to screen
    if ($ErrorRecord) {
        $exception = $ErrorRecord.Exception.ToString()
        $stackTrace = $ErrorRecord.ScriptStackTrace
        $exceptionMsg = $ErrorRecord.Exception.Message
    }
    $Ctx.System.Repository.LogException($Ctx.System.ActivityStack[$Ctx.System.ActivityStack.Count - 1], $Message, $exception, $stackTrace)
    Write-Host "$Message $exceptionMsg" -ForegroundColor DarkRed
    
    if ($ErrorRecord) {
        Write-Host $stackTrace -ForegroundColor Red
        Write-Host $exception
    }

    if ($Rethrow) {
        throw
    }
}