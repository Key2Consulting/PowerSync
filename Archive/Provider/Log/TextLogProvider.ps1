class TextLogProvider : LogProvider {

    [string] $FilePath 

    TextLogProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.FilePath = $this.ConnectionStringParts['filepath']   
       # $this.InitLog()
    }

    [void] WriteLog([string] $LogID, [string] $ParentLogID, [datetime] $MessageDate, [string] $MessageType, [string] $Message, [string] $VariableName, [object] $VariableValue) {
        
        # Create a hash for the log data
        $LogRow = [pscustomobject]@{
            LogID = $LogID
            ParentLogID = $ParentLogID
            MessageDate = $MessageDate
            MessageType = $MessageType
            Message = $Message
            VariableName = $VariableName
            VariableValue = $VariableValue
        }

        $LogRow  | Export-Csv -Path $this.FilePath -NoTypeInformation -Append

    }
    
    [void] ArchiveLog([int] $ExpirationInDays) {
        throw "Not Implemented"
    }
}