class MSSQLLogProvider {

    MSSQLLogProvider ([hashtable] $Configuration) {
        $this.Configuration = $Configuration
    }

    [void] WriteLog([datetime] $MessageDate, [string] $MessageType, [string] $Message, [string] $VariableName, [object] $VariableValue) {
        #throw "Not Implemented"
    }
    
    [void] ArchiveLog([int] $ExpirationInDays) {
        throw "Not Implemented"
    }
}