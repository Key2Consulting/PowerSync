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
                    QueryName = $Entity.QueryName
                    Query = $Entity.Query
                    QueryParam = $Entity.QueryParam
                })
                $Entity.ID = $r[0].QueryLogID
            }
            'VariableLog' {
                $r = $this.Exec("[VariableLogCreate]", $false, [ordered] @{
                    ActivityID = $Entity.ActivityID
                    Type = $Entity.Type
                    VariableName = $Entity.VariableName
                    VariableValue = $Entity.VariableValue
                })
                $Entity.ID = $r[0].VariableLogID    
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
            default {
                throw "Unknown entity type '$EntityType'. found in UpdateEntity."
            }
        }
    }

    [void] DeleteEntity([string] $EntityType, [object] $EntityID) {
        switch ($EntityType) {
            default {
                throw "Unknown entity type '$EntityType'. found in DeleteEntity."
            }
        }
    }

    [object] FindEntity([string] $EntityType, [string] $EntityField, [object] $EntityFieldValue, [bool] $Wildcards) {
        switch ($EntityType) {
            default {
                throw "Unknown entity type '$EntityType'. found in FindEntity."
            }
        }
        return $null
    }

    [object] SearchLogs([string[]] $SearchTerms, [bool] $Wildcards) {
        throw "Method should be overridden by derived classes."
    }

    # Removes an activity from a queue, blocking other concurrent processes which might be doing the same.
    [object] DequeueActivity([string] $Queue) {
        throw "Method should be overridden by derived classes."
    }    
}