function Write-PSYExceptionLog {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [System.Management.Automation.ErrorRecord] $ErrorRecord,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Message,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Rethrow
    )

    # Validation
    Confirm-PSYInitialized($Ctx)

    # Write Log and output to screen
    $exception = $ErrorRecord.Exception.ToString()
    $stackTrace = $ErrorRecord.ScriptStackTrace
    $Ctx.System.Repository.LogException($Ctx.System.ActivityStack[$Ctx.System.ActivityStack.Count - 1], $Message, $exception, $stackTrace)
    Write-Host "$Message $($ErrorRecord.Exception.Message)" -ForegroundColor DarkRed
    Write-Host $stackTrace -ForegroundColor Red
    Write-Host $exception

    if ($Rethrow) {
        throw
    }
}