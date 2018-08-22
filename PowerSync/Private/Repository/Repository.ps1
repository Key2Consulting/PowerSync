class Repository {

    Repository () {
    }

    [void] CreateEntity([string] $EntityType, [object] $Entity) {
        throw "The repository CreateEntity method should be overridden by derived classes."
    }

    # CRUD operations. Note that deserializers like JSON convert into a PSObject, so we can't use strong typing. Instead, we
    # use a simple string representing the type.
    [object] ReadEntity([string] $EntityType, [object] $EntityID) {
        throw "The repository ReadEntity method should be overridden by derived classes."
    }

    [void] UpdateEntity([string] $EntityType, [object] $Entity) {
        throw "The repository UpdateEntity method should be overridden by derived classes."
    }

    [void] DeleteEntity([string] $EntityType, [object] $EntityID) {
        throw "The repository DeleteEntity method should be overridden by derived classes."
    }

    [hashtable] StartActivity([hashtable] $Parent, [string] $Name, [string] $Server, [string] $ScriptFile, [string] $ScriptAst, [string] $Status) {
        $o = @{
            ID = New-Guid
            ParentID = $Parent.ID
            Name = $Name
            Server = $Server
            ScriptFile = $ScriptFile
            Status = $Status
            ScriptAst = $ScriptAst
            StartDateTime = Get-Date
        }
        $this.CreateEntity('ActivityLog', $o)
        return $o
    }
    
    [void] EndActivity([hashtable] $Activity, [string] $Status) {
        $Activity.Status = $Status
        $Activity.EndDateTime = Get-Date
        $this.UpdateEntity('ActivityLog', $Activity)
    }

    [void] LogException([hashtable] $Activity, [string] $Message, [string] $Exception, [string] $StackTrace) {
        $o = @{
            ID = New-Guid
            ActivityID = $Activity.ID
            Message = $Message
            Exception = $Exception
            StackTrace = $StackTrace
            CreatedDateTime = Get-Date
        }
        $this.CreateEntity('ExceptionLog', $o)
    }

    [void] LogInformation([hashtable] $Activity, [string] $Category, [string] $Message) {
        $o = @{
            ID = New-Guid
            ActivityID = $Activity.ID
            Category = $Category
            Message = $Message
            CreatedDateTime = Get-Date
        }
        $this.CreateEntity('InformationLog', $o)
    }

    [void] LogVariable([hashtable] $Activity, [string] $VariableName, [object] $VariableValue) {
        $logValue = ConvertTo-Json $VariableValue
        if ($logValue) {
            $logValue = $VariableValue
        }
        $o = @{
            ID = New-Guid
            ActivityID = $Activity.ID
            VariableName = $VariableName
            VariableValue = $logValue
            CreatedDateTime = Get-Date
        }
        $this.CreateEntity('VariableLog', $o)
    }
    
    [object] GetState([string] $Name) {
        return $this.ReadEntity('State', $Name).Value
    }

    [void] SetState([string] $Name, [object] $Value, [string] $Type, [string] $CustomType) {
        $o = @{
            ID = New-Guid
            Name = $Name
            Type = $Type
            Value = $Value
            CreatedDateTime = Get-Date
            ModifiedDateTime = Get-Date
            ReadDateTime = Get-Date
        }
        # If not exists then create, otherwise update.
        $existing = $this.ReadEntity('State', $Name)
        if (-not $existing) {
            $this.CreateEntity('State', $o)
        }
        else {
            $existing.Value = $Value
            $this.UpdateEntity('State', $existing)
        }
    }

    [void] DeleteState([string] $Name) {
        $o = $this.CriticalSection({
            return $this.DeleteEntity('State', $Name)
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