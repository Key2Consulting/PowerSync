class Repository {
    [System.Collections.ArrayList] $ActivityLog
    [System.Collections.ArrayList] $ExceptionLog
    [System.Collections.ArrayList] $InformationLog
    [System.Collections.ArrayList] $VariableLog

    Repository () {
        $this.ActivityLog = New-Object System.Collections.ArrayList
        $this.ExceptionLog = New-Object System.Collections.ArrayList
        $this.InformationLog = New-Object System.Collections.ArrayList
        $this.VariableLog = New-Object System.Collections.ArrayList
    }

    [void] Initialize() {
        throw "The repository Initialize method should be overridden by derived classes."
    }

    [void] Save([object] $O) {
        throw "The repository Save method should be overridden by derived classes."
    }

    [ActivityLog] StartActivity([ActivityLog] $Parent, [string] $Name, [string] $Server, [string] $ScriptFile, [string] $ScriptAst, [string] $Status) {
        $o = New-Object ActivityLog
        $o.ID = New-Guid
        $o.ParentID = $Parent.ID
        $o.Name = $Name
        $o.Server = $Server
        $o.ScriptFile = $ScriptFile
        $o.Status = $Status
        $o.ScriptAst = $ScriptAst
        $o.StartDateTime = Get-Date
        $this.Save($o)
        return $o
    }
    
    [void] EndActivity([string] $ID, [string] $Status) {
        $o = $this.ActivityLog.Where({$_.ID -eq $ID})[0]
        $o.Status = $Status
        $o.EndDateTime = Get-Date
        $this.Save($o)
    }

    [void] LogException([ActivityLog] $Activity, [object] $Exception, [bool] $Rethrow) {
        $o = New-Object ExceptionLog
        $o.ID = New-Guid
        $o.ActivityID = $Activity.ID
        $o.Exception = $Exception.ToString()
        $o.CreatedDateTime = Get-Date
        $this.Save($o)
    }

    [void] LogInformation([ActivityLog] $Activity, [string] $Category, [string] $Message) {
        $o = New-Object ExceptionLog
        $o.ID = New-Guid
        $o.ActivityID = $Activity.ID
        $o.Category = $o.Category
        $o.Message = $o.Message
        $o.CreatedDateTime = Get-Date
        $this.Save($o)
    }

    [void] LogVariable([ActivityLog] $Activity, [string] $VariableName, [string] $VariableValue) {
        $o = New-Object ExceptionLog
        $o.ID = New-Guid
        $o.ActivityID = $Activity.ID
        $o.VariableName = $o.VariableName
        $o.VariableValue = $o.VariableValue
        $o.CreatedDateTime = Get-Date
        $this.Save($o)
    }
}