class Repository {

    Repository () {
    }

    [void] CreateEntity([object] $O) {
        throw "The repository CreateEntity method should be overridden by derived classes."
    }

    [object] ReadEntity([type] $EntityType, [object] $EntityID) {
        throw "The repository ReadEntity method should be overridden by derived classes."
    }

    [void] UpdateEntity([object] $O) {
        throw "The repository UpdateEntity method should be overridden by derived classes."
    }

    [void] DeleteEntity([type] $EntityType, [object] $EntityID) {
        throw "The repository DeleteEntity method should be overridden by derived classes."
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
        
        $this.CreateEntity($o)
        return $o
    }
    
    [void] EndActivity([ActivityLog] $Activity, [string] $Status) {        
        $Activity.Status = $Status
        $Activity.EndDateTime = Get-Date
        $this.UpdateEntity($Activity)
    }

    [void] LogException([ActivityLog] $Activity, [string] $Message, [string] $Exception, [string] $StackTrace) {
        $o = New-Object ExceptionLog
        $o.ID = New-Guid
        $o.ActivityID = $Activity.ID
        $o.Message = $Message
        $o.Exception = $Exception
        $o.StackTrace = $StackTrace
        $o.CreatedDateTime = Get-Date
        $this.CreateEntity($o)
    }

    [void] LogInformation([ActivityLog] $Activity, [string] $Category, [string] $Message) {
        $o = New-Object InformationLog
        $o.ID = New-Guid
        $o.ActivityID = $Activity.ID
        $o.Category = $Category
        $o.Message = $Message
        $o.CreatedDateTime = Get-Date
        $this.CreateEntity($o)
    }

    [void] LogVariable([ActivityLog] $Activity, [string] $VariableName, [object] $VariableValue) {
        $logValue = ConvertTo-Json $VariableValue
        if ($logValue) {
            $logValue = $VariableValue
        }
        $o = New-Object VariableLog
        $o.ID = New-Guid
        $o.ActivityID = $Activity.ID
        $o.VariableName = $o.VariableName
        $o.VariableValue = $logValue
        $o.CreatedDateTime = Get-Date
        $this.CreateEntity($o)
    }
    
    [object] GetState([string] $Name) {
        return $this.ReadEntity([State], $Name).Value
    }

    [void] SetState([string] $Name, [object] $Value, [StateType] $Type, [string] $CustomType) {
        $o = New-Object State
        $o.ID = New-Guid
        $o.Name = $Name
        $o.Type = $Type
        $o.Value = $Value
        $o.CreatedDateTime = Get-Date
        $o.ModifiedDateTime = Get-Date
        $o.ReadDateTime = Get-Date
        
        # If not exists then create, otherwise update.
        $existing = $this.ReadEntity([State], $Name)
        if (-not $existing) {
            $this.CreateEntity($o)
        }
        else {
            $existing.Value = $Value
            $this.UpdateEntity($existing)
        }
    }

    [void] DeleteState([string] $Name) {
        $o = $this.CriticalSection({
            return $this.DeleteEntity([State], $Name)
        })
    }
    
    [void] CreateConnection([string] $Name, [string] $Class, [string] $ConnectionString) {
    }
    
    [void] ReadConnection([string] $Name) {
    }

    [void] UpdateConnection([string] $Name, [string] $Class, [string] $ConnectionString) {
    }

    [void] DeleteConnection([string] $Name, [string] $Class, [string] $ConnectionString) {
    }
    
    [void] CreateRegistry([string] $Name, [string] $Value) {
    }
    
    [void] ReadRegistry([string] $Name) {
    }
    
    [void] UpdateRegistry([string] $Name, [string] $Value) {
    }

    [void] DeleteRegistry([string] $Name) {
    }
}