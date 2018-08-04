class MSSQLLogProvider : LogProvider {
    [int] $Timeout
    
    # Object Constructor 
    MSSQLLogProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
          $this.Timeout = $this.GetConfigSetting("Timeout", 60)
    }

    [void] WriteLog([string] $LogID, [string] $ParentLogID, [datetime] $MessageDate, [string] $MessageType, [string] $Message, [string] $VariableName, [object] $VariableValue) {
        $event = @{
            MessageDate = $MessageDate
            Message = $Message
            MessageType = $MessageType
            VariableName = $VariableName
            VariableValue = $VariableValue
            LogID = $LogID
            ParentLogID = $ParentLogID
        }
        
        $null = $this.RunScript("LogScript",$false, $event)
    }
    
    [void] ArchiveLog([int] $ExpirationInDays) {
        throw "Not Implemented"
    }

    #COMMENTS

    # Executes a compiled script against the configured data source
    [object] ExecScript([string] $CompiledScript) {
        try {
            # Execute Query
            $this.Connection = New-Object System.Data.SqlClient.SQLConnection($this.ConnectionString)
            $this.Connection.Open()
            $cmd = $this.Connection.CreateCommand()
            $cmd.CommandText = $CompiledScript
            $cmd.CommandTimeout = $this.Timeout
            $r = $cmd.ExecuteReader()
            return $r
        }
        catch {
            $this.HandleException($_.exception)
        }
        return $null
    }

    # Clean up any open connections
    [void] Close() {
        if ($this.Connection -ne $null -and $this.Connection.State -eq "Open") {
            $this.Connection.Close()
        }
    }
}