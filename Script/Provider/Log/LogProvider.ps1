<#
.COPYRIGHT
Copyright (c) Key2 Consulting, LLC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
.DESCRIPTION
Represents the abstract base class for the LogProvider interface. Before any logging takes place, BeginLog must be called. Logging 
can be nested as well, so that logs can have child logs, and those can have children, so on and so forth. Scope is tracked using a 
stack metaphor. Once a scope completes, EndLog is called and the scope is popped off the stack. Every scope is uniquely identified 
using a guid.
#>
class LogProvider : Provider {
    [System.Collections.ArrayList] $CallStack       # list of GUIDs representing logging scope (think parent/child processes)

    LogProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.CallStack = New-Object System.Collections.ArrayList
    }

    # Starts a log scope.
    [void] BeginLog() {
        $this.CallStack.Add((New-Guid).ToString())
        $this.ProcessLog("BeginLog", $null, "LogID", $this.GetLogID())
    }

    # Ends a log scope.
    [void] EndLog() {
        $this.ProcessLog("EndLog", $null, "LogID", $this.GetLogID())
        $this.CallStack.RemoveAt($this.CallStack.Count - 1)
    }

    # TODO: DO WE NEED A ClearStack OR EndLogTo METHOD WHICH WOULD REVERT ALL SCOPES EXCEPT THE ROOT SCOPE?  MAY NEED IT 
    # TO HANDLE EXCEPTIONS WHEN MULTIPLE SCOPES ARE REVERTED DURING A THROW.

    # Identifies the current scope.
    [string] GetLogID() {
        return $this.CallStack[$this.CallStack.Count - 1].ToString()
    }
     
    # Identifies the current scope.
    [string] GetParentLogID([string] $LogID) {
    #TODO: Get Parent from variable
        if ($this.CallStack.Count -gt 1) {
            return $this.CallStack[$this.CallStack.Count - 2].ToString()
        }
        else {
            return $null
        }
    }

    # Writes verbose information to the log.
    [void] WriteInformation([string] $Message) {
        $this.ProcessLog("Information", $Message, $null, $null)
    }
    
    # Writes a discrete variable to the log.
    [void] WriteVariable([string] $VariableName, [object] $VariableValue) {
        $this.ProcessLog("Variable", $null, $VariableName, $VariableValue)
    }

    # Writes an exception to the log, and optionally rethrows it to bubble it up to callers.
    [void] WriteException([object] $Exception, [bool] $Rethrow) {
        $callerName = (Get-PSCallStack)[1].Command
        $this.ProcessLog("Exception", "$callerName - $($Exception.ToString())", $null, $null)
        if ($Rethrow -eq $true) {
            throw $Exception
        }
    }

    # Generic processing of log event.
    [void] ProcessLog([string] $MessageType, [string] $Message, [string] $VariableName, [object] $VariableValue) {
        # Always output to the screen
        if ($VariableName.Length -ne 0) {
            Write-Host "${MessageType}: $VariableName = $VariableValue"
        }
        else {
            Write-Host "${MessageType}: $Message"
        }
        # Call derived class specific implementation of log saving

        $LogID = $this.GetLogID()
        $ParentLogID = $this.GetParentLogID($LogID)
        
        $this.WriteLog($LogID, $ParentLogID, (Get-Date), $MessageType, $Message, $VariableName, $VariableValue)
    }
    
    # Saves the log entry (this method must be overridden in derived classes).
    [void] WriteLog([string] $LogID, [string] $ParentLogID, [datetime] $MessageDate, [string] $MessageType, [string] $Message, [string] $VariableName, [object] $VariableValue) {
        throw "Not Implemented"
    }

    # Archives old entries from a log.
    [void] ArchiveLog([int] $ExpirationInDays) {
        throw "Not Implemented"
    }
}