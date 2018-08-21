enum StateType {
    None = $null
    DiscreteState = 1
    CollectionState = 2
    CustomState = 3
}

class State {
    [object] $ID
    [string] $Name
    [StateType] $Type
    [object] $Value
    [DateTime] $CreatedDateTime
    [DateTime] $ModifiedDateTime
    [DateTime] $ReadDateTime
}

class ActivityLog {
    [object] $ID
    [object] $ParentID
    [string] $Name = $Name
    [string] $Server = $Server
    [string] $ScriptFile = $ScriptFile
    [string] $Status = $Status
    [string] $ScriptAst = $ScriptAst
    [DateTime] $StartDateTime
    [DateTime] $EndDateTime
}

class ExceptionLog {
    [object] $ID
    [object] $ActivityID
    [string] $Message
    [string] $Exception
    [string] $StackTrace
    [DateTime] $CreatedDateTime
}

class InformationLog {
    [object] $ID
    [object] $ActivityID
    [string] $Category
    [string] $Message
    [DateTime] $CreatedDateTime
}

class VariableLog {
    [object] $ID
    [object] $ActivityID
    [string] $VariableName
    [string] $VariableValue
    [DateTime] $CreatedDateTime
}