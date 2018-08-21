class Repository {

    Repository () {
    }

    [void] SaveEntity([object] $O) {
        throw "The repository SaveEntity method should be overridden by derived classes."
    }

    [object] GetEntity([type] $EntityType, [object] $EntityID) {
        throw "The repository GetEntity method should be overridden by derived classes."
    }

    [void] DeleteEntity([type] $EntityType, [object] $EntityID) {
        throw "The repository DeleteEntity method should be overridden by derived classes."
    }

    [object] CriticalSection([scriptblock] $Script) {
        throw "The repository CriticalSection method should be overridden by derived classes."
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
        $this.CriticalSection({
            $this.SaveEntity($o)
        })
        return $o
    }
    
    [void] EndActivity([ActivityLog] $Activity, [string] $Status) {
        $this.CriticalSection({
            $Activity.Status = $Status
            $Activity.EndDateTime = Get-Date
            $this.SaveEntity($Activity)
        })
    }

    [void] LogException([ActivityLog] $Activity, [object] $Exception, [bool] $Rethrow) {
        $o = New-Object ExceptionLog
        $o.ID = New-Guid
        $o.ActivityID = $Activity.ID
        $o.Exception = $Exception.ToString()
        $o.CreatedDateTime = Get-Date
        $this.CriticalSection({
            $this.SaveEntity($o)
        })
    }

    [void] LogInformation([ActivityLog] $Activity, [string] $Category, [string] $Message) {
        $o = New-Object InformationLog
        $o.ID = New-Guid
        $o.ActivityID = $Activity.ID
        $o.Category = $Category
        $o.Message = $Message
        $o.CreatedDateTime = Get-Date
        $this.CriticalSection({
            $this.SaveEntity($o)
        })
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
        $this.CriticalSection({
            $this.SaveEntity($o)
        })
    }
    
    [void] SaveState([string] $Name, [object] $Data) {
        $this.CriticalSection({
            $existing = $this.GetEntity([State], $Name)
            if (-not $existing) {
                throw "State $Name not found."
            }
            $existing.Value = $Data
            $this.SaveEntity($existing)
        })
    }
    
    [object] GetState([string] $Name) {
        $o = $this.CriticalSection({
            return $this.GetEntity([State], $Name)
        })
        return $o.Value
    }

    [object] RegisterState([string] $Name, [object] $Data, [StateType] $Type, [string] $CustomType) {
        $o = New-Object State
        $o.ID = New-Guid
        $o.Name = $Name
        $o.Type = $Type
        $o.Value = $Data
        $o.CreatedDateTime = Get-Date
        $o.ModifiedDateTime = Get-Date
        $o.ReadDateTime = Get-Date
        $this.CriticalSection({
            $existing = $this.GetEntity([State], $Name)
            if (-not $existing) {
                $this.SaveEntity($o)
            }
            else {
                $o = $existing
            }
        })
        return $o.Value
    }

    [void] DeleteState([string] $Name) {
        $o = $this.CriticalSection({
            return $this.DeleteEntity([State], $Name)
        })
    }
    
    [void] SaveConnection([string] $Name, [string] $Class, [string] $ConnectionString) {
    }
    
    [void] GetConnection([string] $Name) {
    }
}