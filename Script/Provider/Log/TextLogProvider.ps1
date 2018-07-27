class TextLogProvider : LogProvider {

    TextLogProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
    }

    [void] WriteLog([datetime] $MessageDate, [string] $MessageType, [string] $Message, [string] $VariableName, [object] $VariableValue) {
    }
    
    [void] ArchiveLog([int] $ExpirationInDays) {
        throw "Not Implemented"
    }
}