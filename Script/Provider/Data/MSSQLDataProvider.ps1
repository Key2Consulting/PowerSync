# Represents the abstract base class for the DataProvider interface, and includes some functionality common to all providers
class MSSQLDataProvider : DataProvider {
    [int] $Timeout
    [string] $TempTableName

    MSSQLDataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.Timeout = $this.GetConfigSetting("Timeout", 3600)
        $this.SetDefaultScript("AutoCreateScript", "MSSQLAutoCreate.sql")
        $this.SetDefaultScript("AutoSwapScript", "MSSQLAutoSwap.sql")
        $this.SetDefaultScript("AutoIndexScript", "MSSQLAutoIndex.sql")
        # Always remove any name enclosures (i.e. brackets), making the logic in script templates easier to process.
        $this.Schema = $this.Schema.Replace("[", "").Replace("]", "")
        $this.Table = $this.Table.Replace("[", "").Replace("]", "")
    }

    [hashtable] Prepare() {
        return $this.ExecQuery("PrepareScript", $true, $null)
    }

    [object[]] Extract() {
        # Attempt to load the Extract Script
        $sql = $this.CompileScript("ExtractScript", $this.Configuration)
        if ($sql -eq $null) {
            throw "No ExtractScript set."
        }

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
            $this.SchemaInfo.Add($s)
        }        

        return $r, $this.SchemaInfo
    }

    [hashtable] Load([System.Data.IDataReader] $DataReader, [System.Collections.ArrayList] $SchemaInfo) {
        if ($this.Schema -eq $null -or $this.Table -eq $null) {
            throw "Provider configuration missing Schema and/or Table."
        }

        # If AutoCreate is set, execute the create script
        $loadTableFQName = ""
        $additionalConfig = $null
        if ($this.GetConfigSetting("AutoCreate", $true) -eq $true) {
            # Convert the SchemaInfo array into SQL statement in the INSERT VALUES format i.e. ('Field', Field), ('Field', Field).
            # Passing an array to a script is tricky, so we do this so it's easy to create a table for processing.
            $s = ""
            foreach ($i in $SchemaInfo) {
                $s += "('$($i.Name)', $($i.Size), $($i.Precision), $($i.Scale), $([int]$i.IsKey), $([int]$i.IsNullable), $([int]$i.IsIdentity), '$($i.DataType)'),"
            }
            $s = $s.Substring(0, $s.Length - 1)
            # Create additional configuration parameters for execution of AutoCreateScript.
            $additionalConfig = @{
                "$($this.Namespace)SchemaInfo" = $s
                "$($this.Namespace)LoadTable" = "$($this.Table)$($this.Configuration.RuntimeID)"
            }
            $this.ExecQuery("AutoCreateScript", $false, $additionalConfig)
            # We now must load into the load table
            $loadTableFQName = "[$($this.Schema)].[$($this.Table)$($this.Configuration.RuntimeID)]"
        }
        else {
            # Otherwise, load into the pre-created table defined in the manifest
            $loadTableFQName = "[$($this.Schema)].[$($this.Table)]"
        }
        
        # Use SqlBulkCopy to import the data
        $blk = New-Object Data.SqlClient.SqlBulkCopy($this.ConnectionString)
        $blk.DestinationTableName = $loadTableFQName
        $blk.BulkCopyTimeout = $this.Timeout
        $blk.BatchSize = $this.GetConfigSetting("BatchSize", 10000)
        $blk.WriteToServer($DataReader)

        # If AutoIndex is set, execute AutoIndex script
        if ($this.GetConfigSetting("AutoIndex", $true) -eq $true) {
            $this.ExecQuery("AutoIndexScript", $false, $additionalConfig)
        }

        # If AutoCreate is set, we must swap the "temp" load table as the final one.
        if ($this.GetConfigSetting("AutoCreate", $true) -eq $true) {
            $this.ExecQuery("AutoSwapScript", $false, $additionalConfig)
        }

        return $null;
    }

    [hashtable] Transform() {
        return $this.ExecQuery("TransformScript", $true, $null)
    }

    [void] Close() {
        # If a connection is established, close connection now.
        if ($this.Connection -ne $null -and $this.Connection.State -eq "Open") {
            $this.Connection.Close()
        }
    }

    [hashtable] ExecQuery([string] $ScriptName, [bool] $SupportWriteback, [hashtable] $AdditionalConfiguration) {
        # If caller has additional configuration to apply on top of provider configuration
        if ($AdditionalConfiguration) {
            $h = $this.Configuration + $AdditionalConfiguration
        }
        else {
            $h = $this.Configuration
        }
        # Compile and Execute the script
        $sql = $this.CompileScript($ScriptName, $h)
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