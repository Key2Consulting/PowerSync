class OleDbRepository : Repository {
    [string] $SPPrefix

    # The initial construction of the OleDbRepository
    OleDbRepository ([string] $ConnectionString, [string] $Schema, [hashtable] $State) : base([hashtable] $State) {
        $State.ConnectionString = $ConnectionString
        if ($Schema) {
            $State.SPPrefix = "$Schema."
        }
    }

    # The rehydration of the Repository via the factory
    OleDbRepository ([hashtable] $State) : base([hashtable] $State) {
    }

    # Executes a stored procedure against the database returning the results as a hashtable. 
    # NOTE
    #   - All interaction to and from the database must take place through stored procedures, for performance and interface contract purposes.
    #   - The order of the parameters must match the order in the stored procedure (use [ordered] hashtable).
    [object] Exec([string] $StoredProcedure, [bool] $isQuery, [object] $Parameters) {
        
        $connection = $null
        $returnValue = $null

        try {
            # Establish a connection to the database, and create a command to the given stored procedure.
            $connection = [System.Data.OleDb.OleDbConnection]::new($this.State.ConnectionString)
            $cmd = $connection.CreateCommand()
            $cmd.CommandType = [System.Data.CommandType]::StoredProcedure
            $cmd.CommandText = "$($this.State.SPPrefix)$StoredProcedure"        # apply stored procedure prefix, if specified (some databases support schemas)

            # Add each passed in parameter to the command.
            foreach ($parameterName in $Parameters.Keys) {
                $parameterValue = $Parameters[$parameterName]
                $parameterDirection = [System.Data.ParameterDirection]::Input
                $p = $cmd.Parameters.AddWithValue($parameterName, $parameterValue)
            }
            $connection.Open()
            $reader = $cmd.ExecuteReader()

            # Copy results into arraylist of hashtables
            if ($reader.HasRows) {
                $returnValue = [System.Collections.ArrayList]::new()
                if ($reader.HasRows) {
                    while ($reader.Read()) {
                        $result = [ordered] @{}
                        for ($i=0;$i -lt $reader.FieldCount; $i++) {
                            $col = $reader.GetName($i)
                            $result."$col" = $reader[$i]
                        }
                        [void] $returnValue.Add($result)
                    }
                }
            }
        }
        finally {
            if ($connection) {
                if ($connection.State -eq "Open") {
                    $connection.Close()
                }
                $connection.Dispose()
            }
        }
        return $returnValue
    }

    [void] CreateEntity([string] $EntityType, [object] $Entity) {
        switch ($EntityType) {
            'ErrorLog' {
                $r = $this.Exec("[ErrorLogCreate]", $false, [ordered] @{
                    ActivityID = $Entity.ID
                    Type = $Entity.Type
                    Message = $Entity.Message
                    Exception = $Entity.Exception
                    StackTrace = $Entity.StackTrace
                    Invocation = $Entity.Invocation
                })
                $Entity.ID = $r[0].ErrorLogID
            }
            'MessageLog' {
                $r = $this.Exec("[MessageLogCreate]", $false, [ordered] @{
                    ActivityID = $Entity.ActivityID
                    Type = $Entity.Type
                    Category = $Entity.Category
                    Message = $Entity.Message
                })
                $Entity.ID = $r[0].MessageLogID    
            }
            'QueryLog' {
                $r = $this.Exec("[QueryLogCreate]", $false, [ordered] @{
                    ActivityID = $Entity.ActivityID
                    Type = $Entity.Type
                    Connection = $Entity.Connection
                    QueryName = $Entity.Name
                    Query = $Entity.Query
                    QueryParam = $Entity.QueryParam
                })
                $Entity.ID = $r[0].QueryLogID
            }
            'VariableLog' {
                [string] $ValueString = ""
               
                #If The Value Type is  Hashtable or Array, Flaten all the rows in the Hashtable into a String.
                if ($Entity.Value -is [HashTable] -or $Entity.Value -is [array]){
                    $ValueString = $Entity.Value | ConvertTo-Json -Depth 3 
                    } 
                else {
                    $ValueString = $Entity.Value
                }
                $r = $this.Exec("[VariableLogCreate]", $false, [ordered] @{
                    ActivityID = $Entity.ActivityID
                    Type = $Entity.Type
                    Name = $Entity.Name
                    Value = $ValueString
                })
                $Entity.ID = $r[0].VariableLogID    
            }
            'Variable' {
                [string] $ValueString = ""
               
                #If The Value Type is  Hashtable or Array, Flaten all the rows in the Hashtable into a String.
                if ($Entity.Value -is [HashTable] -or $Entity.Value -is [array]){
                    $ValueString = $Entity.Value | ConvertTo-Json -Depth 3 
                    } 
                else {
                    $ValueString = $Entity.Value
                }

                $r = $this.Exec("[VariableCreate]", $false, [ordered] @{
                    Name = $Entity.Name
                    Value = $ValueString 
                    DataType = $Entity.Value.GetType().FullName
                })
                $Entity.ID = $r[0].ID
            }
            'Connection' {
                #If The Properties Type is  Hashtable or Array, Flaten all the rows in the Hashtable into a String.
                if ($Entity.Properties -is [HashTable] -or $Entity.Properties -is [array]){
                    $PropertiesString = $Entity.Properties | ConvertTo-Json -Depth 3 
                    } 
                else {
                    $PropertiesString = $Entity.Properties
                }

                $r = $this.Exec("[ConnectionCreate]", $false, [ordered] @{
                    Name = $Entity.Name
                    Provider = $Entity.Provider
                    ConnectionString = $Entity.ConnectionString
                    Properties = $PropertiesString
                })
                $Entity.ID = $r[0].ConnectionID              
            }
            'Activity'{
                if ($Entity.Error -is [HashTable] -or $Entity.Error -is [array] -or $Entity.Error -is [System.Object] ){
                    $ErrorText = $Entity.Error | ConvertTo-Json -Depth 3 
                    } 
                else {
                    $ErrorText = $Entity.Error
                }
                
                $r = $this.Exec("[ActivityCreate]", $false, [ordered] @{
                    ParentActivityID = $Entity.ParentID
                    Name = $Entity.Name
                    Status = $Entity.Status
                    StartDateTime = $Entity.StartDateTime
                    ExecutionDateTime = $Entity.ExecutionDateTime
                    EndDateTime = $Entity.EndDateTime
                    Queue = $Entity.Queue
                    OriginatingServer = $Entity.OriginatingServer
                    ExecutionServer = $Entity.ExecutionServer
                    #ExecutionPID = $Entity.ExecutionPID
                    InputObject = $Entity.InputObject
                    ScriptBlock = $Entity.ScriptBlock
                    ScriptPath = $Entity.ScriptPath
                    JobInstanceID = $Entity.JobInstanceID
                    OutputObject = $Entity.OutputObject
                    HadErrors = $Entity.HadErrors
                    Error = $ErrorText
                })
                $Entity.ID = $r[0].ActivityID     
                
            }
            default { 
                throw "Unknown entity type '$EntityType'. found in CreateEntity."
            }
        }
    }
    
    [object] ReadEntity([string] $EntityType, [object] $EntityID) {
        switch ($EntityType) {
            default { 
                throw "Unknown entity type '$EntityType'. found in ReadEntity."
            }
        }
        return $null
    }

    [void] UpdateEntity([string] $EntityType, [object] $Entity) {
        switch ($EntityType) {
            'Variable' {
                [string] $ValueString = ""
               
                #If The Value Type is  Hashtable or Array, Flaten all the rows in the Hashtable into a String.
                if ($Entity.Value -is [HashTable] -or $Entity.Value -is [array]){
                    $ValueString = $Entity.Value | ConvertTo-Json -Depth 3 
                    } 
                else {
                    $ValueString = $Entity.Value
                }
                $r = $this.Exec("[VariableUpdate]", $false, [ordered] @{
                    Name = $Entity.Name
                    Value = $ValueString
                    DataType = $Entity.Value.GetType().FullName
                })
            }
            'Connection' {
                [string] $PropertiesString = ""

                 #If The Properties Type is  Hashtable or Array, Flaten all the rows in the Hashtable into a String.
                 if ($Entity.Properties -is [HashTable] -or $Entity.Properties -is [array] -or $Entity.Properties -is [System.Object] ){
                    $PropertiesString = $Entity.Properties | ConvertTo-Json -Depth 3 
                    } 
                else {
                    $Propertiestring = $Entity.Properties
                }

                $r = $this.Exec("[ConnectionUpdate]", $false, [ordered] @{
                    Name = $Entity.Name
                    Provider = $Entity.Provider
                    ConnectionString = $Entity.ConnectionString
                    Properties = $PropertiesString
                })
            }
            'Activity' {
                if ($Entity.Error -is [HashTable] -or $Entity.Error -is [array] -or $Entity.Error -is [System.Object] ){
                    $ErrorText = $Entity.Error | ConvertTo-Json -Depth 3 
                    } 
                else {
                    $ErrorText = $Entity.Error
                }

                $r = $this.Exec("[ActivityUpdate]", $false, [ordered] @{
                    ActivityID = $Entity.ID
                    Status = $Entity.Status
                    ExecutionDateTime = $Entity.ExecutionDateTime
                    EndDateTime = $Entity.EndDateTime
                    Queue = $Entity.Queue
                    InputObject = $Entity.InputObject
                    OutputObject = $Entity.OutputObject
                    HadErrors = $Entity.HadErrors
                    Error = $ErrorText
                })
            }
            default {
                throw "Unknown entity type '$EntityType'. found in UpdateEntity."
            }
        }
    }

    [void] DeleteEntity([string] $EntityType, [object] $EntityID) {
        switch ($EntityType) {
            
            'Connection' {
                $r = $this.Exec("[ConnectionDelete]", $false, [ordered] @{
                    ConnectionID = $EntityID
                })
            }
            'Variable' {
                $r = $this.Exec("[VariableDelete]", $false, [ordered] @{
                    EntityID = $EntityID
                })
              
            }
            
            default {
                throw "Unknown entity type '$EntityType'. found in DeleteEntity."
            }
        }
    }

    [object] FindEntity([string] $EntityType, [string] $EntityField, [object] $EntityFieldValue, [bool] $Wildcards) {
        $entityList = [System.Collections.ArrayList]::new()
        
        switch ($EntityType) {
            'Connection' {
                $r = $this.Exec("[ConnectionFind]", $false, [ordered] @{
                    EntityField = $EntityField
                    EntityFieldValue = $EntityFieldValue
                    Wildcards = $Wildcards
                })

                if($r){
                    $r | ForEach-Object {
                        #Convert the Properties to a Hash
                        $PropertiesHash = $_.Properties
                        $_.Properties = $null
                        $_.Properties = $PropertiesHash | ConvertFrom-Json

                        #Convert the Provider to PSYDbConnectionProvider
                        $providerName = [Enum]::GetName([PSYDbConnectionProvider], [int] $_.Provider)
                        $_.Provider = $null
                        $_.Provider = [PSYDbConnectionProvider] $providerName
                        
                    }
                }
                
                $entityList = $r
            }
            'Variable' {
                $r = $this.Exec("[VariableFind]", $false, [ordered] @{
                    EntityField = $EntityField
                    EntityFieldValue = $EntityFieldValue
                    Wildcards = $Wildcards
                })
               
                if($r){
                    $r | ForEach-Object {
                
                        #Create a variable as the datatype from the column DataType
                        $DataType =  [System.Type]::GetType($($_.DataType))
                        
                        #Treat the Text as string if the DataType is not defined
                        if(!$DataType){
                            $DataType = [string]
                        }

                        #If the Data Type is Hashtable, convert from the text to hashtable
                        if($DataType -eq [Hashtable] -or $DataType -eq [System.Object[]]){
                            $VariableHash = $_.Value
                            $_.Value = $null
                            $_.Value = $VariableHash | ConvertFrom-Json
                        }

                        #convert all other datatypes with -as
                        else {
                            $_.Value = $_.Value -as $DataType
                        }

                        #Add ID to Results
                        $_.ID = $_.Name
                        
                    }
                }
                   
                $entityList = $r


            }
            default {
                throw "Unknown entity type '$EntityType'. found in FindEntity."
            }
        }
        return $entityList 
    }

    [object] SearchLogs([string] $Search, [bool] $Wildcards) {
        throw "Method should be overridden by derived classes."
    }

    # Removes an activity from a queue, blocking other concurrent processes which might be doing the same.
    [object] DequeueActivity([string] $Queue) {
        throw "Method should be overridden by derived classes."
    }    
}