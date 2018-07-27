# Represents the abstract base class for the LogProvider interface
class LogProvider : Provider {
    [System.Collections.ArrayList] $CallStack       # list of GUIDs representing logging scope (think parent/child processes)

    LogProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.CallStack = New-Object System.Collections.ArrayList
    }

    [void] BeginLog() {
        $this.CallStack.Add((New-Guid).ToString())
        $this.ProcessLog("BeginLog", $null, "LogID", $this.GetLogID())
    }

    [void] EndLog() {
        $this.ProcessLog("EndLog", $null, "LogID", $this.GetLogID())
        $this.CallStack.RemoveAt($this.CallStack.Count - 1)
    }

    [string] GetLogID() {
        return $this.CallStack[$this.CallStack.Count - 1].ToString()
    }

    [void] WriteInformation([string] $Message) {
        $this.ProcessLog("Information", $Message, $null, $null)
    }
    
    [void] WriteVariable([string] $VariableName, [object] $VariableValue) {
        $this.ProcessLog("Variable", $null, $VariableName, $VariableValue)
    }

    [void] WriteException([object] $Exception, [bool] $Rethrow) {
        $this.ProcessLog("Exception", $Exception.ToString(), $null, $null)
        if ($Rethrow -eq $true) {
            throw $Exception
        }
    }

    # Generic processing of log message
    [void] ProcessLog([string] $MessageType, [string] $Message, [string] $VariableName, [object] $VariableValue) {
        # Always output to the screen
        if ($VariableName.Length -ne 0) {
            Write-Host "${MessageType}: $VariableName = $VariableValue"
        }
        else {
            Write-Host "${MessageType}: $Message"
        }
        # Call derived class specific implementation of log saving
        $this.WriteLog((Get-Date), $MessageType, $Message, $VariableName, $VariableValue)
    }
    
    # Saves the log entry (this method must be overridden in derived classes)
    [void] WriteLog([datetime] $MessageDate, [string] $MessageType, [string] $Message, [string] $VariableName, [object] $VariableValue) {
        throw "Not Implemented"
    }

    [void] ArchiveLog([int] $ExpirationInDays) {
        throw "Not Implemented"
    }
}