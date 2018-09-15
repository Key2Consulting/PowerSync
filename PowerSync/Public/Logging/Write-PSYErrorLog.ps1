<#
.SYNOPSIS
Write to the error log, and displays in the console.

.DESCRIPTION
Write-PSYErrorLog handles default and automatic processing of exceptions. 

When PowerSync functions invoke other PowerSync functions, continuing on error is generally avoided since continuing execution when dependent steps failed can have unintended consequences. Therefore, PowerSync will still honor the Error Preferences of callers for the function that's called but not nested functions.

Only the originating exception is every logged/printed, depending on the Error Preference. Rethrown exceptions are never re-logged.

.PARAMETER ErrorRecord
The thrown error caught by PowerShell (i.e. the $_ variable).

.PARAMETER Message
An additional message of information further describing the error or attempted operation.

.EXAMPLE
TODO

.NOTES
Every PowerSync function should have a Try/Catch. Regardless of Error Preference, Try/Catch always catches errors in PowerShell. The catch block will call Write-PSYErrorLog for automatic exception processing. The following table describes the chaining behavior of nested invocations:

Preference      User Code       PSYParent           PSYChild            PSYGrandChild
---------------------------------------------------------------------------------------
Stop            Is Thrown       Catch/Throw         Log, Throw
Stop            Is Thrown       Catch/Throw         Catch/Throw         Log, Throw
Continue        Continue        Catch/Continue      Log, Throw
Continue        Continue        Catch/Continue      Catch/Throw         Log, Throw
SilentContinue  Continue        Catch/Continue      No Log, Throw
SilentContinue  Continue        Catch/Continue      Catch/Throw         No Log, Throw

Internally, all PowerSync functions should use throw when detecting and reporting an error condition, and let the default catch logic handle propogation.
 #>
function Write-PSYErrorLog {
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = 'The thrown error caught by PowerShell (i.e. the $_ variable).', Mandatory = $false)]
            [System.Management.Automation.ErrorRecord] $ErrorRecord
    )
    
    # Determine if this is an originating error (i.e. not a rethrown error).
    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message -eq 'Non-originating') {
        $originating = $false
    }
    else {
        $originating = $true
    }

    # Identify the function catching the exception, and it's caller.
    $stack = Get-PSCallStack
    $handler = $stack[1]        # Write-PSYErrorLog is now index 0
    $caller = $stack[2]

    # Determine if caller is a PowerSync module (must honor Error Preference in that case)
    if ($caller.InvocationInfo.MyCommand.ModuleName -and $caller.InvocationInfo.MyCommand.ModuleName -eq 'PowerSync') {
        $internalCaller = $true
    }
    else {
        $internalCaller = $false
    }

    # Handle the exception based on the factors above
    #

    # If it's an originating exception, and the preference is to log, do that now. We must log at the point of failure because there's
    # important debugging information only available when an exception occurs, and is lost when bubbling the error up.
    if ($originating -and $ErrorActionPreference -ne "SilentlyContinue") {
        # Must be careful trying to connect to repository within an exception handler. The exception could
        # be caused by connectivity issues with the repository. If so, we disconnect before proceeding.
        if ($PSYSession.Initialized) {
            $repo = New-FactoryObject -Repository -ErrorAction SilentlyContinue
        }
        # Log
        if ($repo) {
            [void] $repo.CriticalSection({
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Message = $ErrorRecord.Exception.Message
                    Exception = $ErrorRecord.Exception.ToString()
                    StackTrace = $ErrorRecord.ScriptStackTrace
                    Invocation = "$($handler.FunctionName) ($($handler.InvocationInfo.BoundParameters | ConvertTo-Json -Depth 1 -Compress))"     # we could be as verbose as we wanted here, and include BoundParameters all the way up the stack
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1].ID
                }
                $this.CreateEntity('ErrorLog', $o)
            })
        }
        # Print to Console
        Write-Host $ErrorRecord.Exception.ToString() -ForegroundColor Red
        Write-Host "$($handler.FunctionName) ($($handler.InvocationInfo.BoundParameters | ConvertTo-Json -Depth 1 -Compress))" -ForegroundColor DarkGreen
        Write-Host $ErrorRecord.ScriptStackTrace -ForegroundColor DarkGray

        # Mark exception as non-originating for next throw
        $ErrorRecord.ErrorDetails = 'Non-originating'
    }
    
    # If caller is internal, simply rethrow. No need to log again in this case since
    # it's already been logged, but the caller still needs to know an exception occurred.
    if ($internalCaller) {
        throw $ErrorRecord
    }

    # If caller is external, throw or suppress exception based on Error Preference.
    if (-not $internalCaller) {
        if ($ErrorActionPreference -eq "Stop") {
            throw $ErrorRecord
        }
        elseif ($ErrorActionPreference -eq "Inquire") {
            $continue = Read-Host 'Continue processing? [Y] Yes [N] No [T] Terminate All Processing (default is "Y"):'
            if ($continue -eq 'N') {
                throw $ErrorRecord
            }
            elseif ($continue -eq 'T') {
                exit
            }
        }
    }
}