# Represents the abstract base class for the DataProvider interface, and includes some functionality common to all providers
class MSSQLDataProvider : DataProvider {
    [int] $Timeout
    [string] $TempTableName

    MSSQLDataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.Timeout = $this.GetConfigSetting("Timeout", 3600)
        $this.SetDefaultScript("AutoCreateScript", "MSSQLAutoCreate.sql")
        $this.SetDefaultScript("AutoSwapScript", "MSSQLAutoSwap.sql")
        $this.SetDefaultScript("AutoIndexScript", "MSSQLAutoIndex.sql")
        $this.SetDefaultScript("ExtractScript", "MSSQLExtract.sql")
    }

    [hashtable] Prepare() {
        return $this.RunScript("PrepareScript", $true, $null)
    }

    [object[]] Extract() {
        # Attempt to load the Extract Script
        $sql = $this.CompileScript("ExtractScript", $this.Configuration)

        # Execute the Extraction and return the results to the caller.  Note that the connection
        # remains open at this point, until the provider's Close method is called.
        $this.Connection = New-Object System.Data.SqlClient.SQLConnection($this.ConnectionString)
        $this.Connection.Open()
        $cmd = $this.Connection.CreateCommand()
        $cmd.CommandText = $sql
        $cmd.CommandTimeout = $this.Timeout
        $r = $cmd.ExecuteReader()

        # Create the SchemaInfo list using the reader's SchemaTable
        $this.SchemaInfo = New-Object System.Collections.ArrayList
        [System.Data.DataTable] $st = $r.GetSchemaTable()
        foreach ($col in $st) {
            # Create an entry in our schema info array for callers and later use
            $s = New-Object SchemaInformation
            $s.Name = $col[0]
            $s.Size = $col[2]
            $s.DataType = $col[24]
            $s.IsNullable = $col[13]
            $s.Precision = $col[3]
            $s.Scale = $col[4]
            # If size is MAX, convert to -1 to indicate unlimited (PowerSync convention)
            if ($s.Size -eq 2147483647) {
                $s.Size = -1
            }
            # Detect if special type Geography
            if ($s.DataType.Contains("geography")) {
                $s.DataType = "geography"
            }
            $this.SchemaInfo.Add($s)
        }        

        return $r, $this.SchemaInfo
    }

    [hashtable] Load([System.Data.IDataReader] $DataReader, [System.Collections.ArrayList] $SchemaInfo) {
        if ($this.Schema -eq $null -or $this.Table -eq $null) {
            throw "Provider configuration missing Schema and/or Table."
        }

        # If AutoCreate is set, execute the create script.
        $loadTableName = ""
        $additionalConfig = $null
        if ($this.GetConfigSetting("AutoCreate", $true) -eq $true) {
            # Convert the SchemaInfo array into SQL statement in the INSERT VALUES format i.e. ('Field', Field), ('Field', Field).
            # Passing an array to a script is tricky, so we do this so it's easy to create a table for processing.
            $s = ""
            foreach ($i in $SchemaInfo) {
                $s += "('$($i.Name)', $($i.Size), $($i.Precision), $($i.Scale), $([int]$i.IsKey), $([int]$i.IsNullable), $([int]$i.IsIdentity), '$($i.DataType)'),"
            }
            $s = $s.Substring(0, $s.Length - 1)
            
            # The new table will have the RuntimeID appended to make it unique, and provide a correlation ID.
            $loadTableName = $this.ConcatTableName($this.Table, $this.Configuration.RuntimeID)

            # If the table name was enclosed in brackets, reapply the brackets
            # Create additional configuration parameters for execution of AutoCreateScript.
            $additionalConfig = @{
                "$($this.Namespace)SchemaInfo" = $s
                "$($this.Namespace)LoadTable" = $loadTableName
            }
            [void] $this.RunScript("AutoCreateScript", $false, $additionalConfig)
        }
        else {
            # Otherwise, load into the pre-created table defined in the manifest
            $loadTableName = $this.Table
        }
        
        # Use SqlBulkCopy to import the data
        $blk = New-Object Data.SqlClient.SqlBulkCopy($this.ConnectionString)
        $blk.DestinationTableName = "$($this.Schema).$loadTableName"
        $blk.BulkCopyTimeout = $this.Timeout
        $blk.BatchSize = $this.GetConfigSetting("BatchSize", 10000)
        $blk.WriteToServer($DataReader)

        # If AutoIndex is set, execute AutoIndex script
        if ($this.GetConfigSetting("AutoIndex", $true) -eq $true) {
            [void] $this.RunScript("AutoIndexScript", $false, $additionalConfig)
        }

        # If AutoCreate is set, we must swap the "temp" load table as the final one.
        if ($this.GetConfigSetting("AutoCreate", $true) -eq $true) {
            [void] $this.RunScript("AutoSwapScript", $false, $additionalConfig)
        }

        return $null;
    }

    [hashtable] Transform() {
        # Try Catch with $global:pLog 
        return $this.RunScript("TransformScript", $true, $null)
    }

    # Clean up any open connections
    [void] Close() {
        if ($this.Connection -ne $null -and $this.Connection.State -eq "Open") {
            $this.Connection.Close()
        }
    }

    #
    [string] ConcatTableName([string] $TableName, [string] $Text) {
        if ($TableName.StartsWith("[")) {
            $unenclosedName = $TableName.Substring(1, $TableName.Length - 2)
            return "[$unenclosedName$Text]"
        }
        else {
            return "$TableName$Text"
        }
    }

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
}