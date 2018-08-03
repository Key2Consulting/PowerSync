class MSSQLLogProvider : LogProvider {
    [int] $Timeout
    
    # Object Constructor 
    MSSQLLogProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
          $this.Timeout = $this.GetConfigSetting("Timeout", 3600)
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
        
        #
        $h = $this.Configuration + $event 

        $this.ExecQuery("LogScript",$false, $h)
    }
    
    [void] ArchiveLog([int] $ExpirationInDays) {
        throw "Not Implemented"
    }

    #COMMENTS

    [hashtable] ExecQuery([string] $ScriptName, [bool] $SupportWriteback, [hashtable] $AdditionalConfiguration) {
        $sql = $this.CompileScript($ScriptName, $AdditionalConfiguration)
        $h = $this.Configuration
        if ($sql -ne $null) {
            try {
                # Execute Query
                $this.Connection = New-Object System.Data.SqlClient.SQLConnection($this.ConnectionString)
                $this.Connection.Open()
                $cmd = $this.Connection.CreateCommand()
                $cmd.CommandText = $sql
                $cmd.CommandTimeout = $this.Timeout
                $r = $cmd.ExecuteReader()

                if ($SupportWriteback) {
                    # Copy results into hashtable (only single row supported)
                    $b = $r.Read()
                    for ($i=0;$i -lt $r.FieldCount; $i++) {
                        $col = $r.GetName($i)
                        if ($h.ContainsKey($col)) {
                            $h."$col" = $r[$col]
                        }
                    }
                }
            }
            finally {
                # If a connection is established, close connection now.
                if ($this.Connection -ne $null -and $this.Connection.State -eq "Open") {
                    $this.Connection.Close()
                }
            }
        }
        return $h
    }
}