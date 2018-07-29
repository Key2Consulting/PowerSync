# Represents the abstract base class for the DataProvider interface, and includes some functionality common to all providers
class MSSQLDataProvider : DataProvider {
    [int] $Timeout
    [string] $TempTableName

    MSSQLDataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.Timeout = $this.GetConfigSetting("Timeout", 3600)
    }

    [hashtable] Prepare() {
        return $this.ExecQuery("PrepareScript", $true)
    }

    [object[]] Extract() {
        throw "TODO: CREATE NEW SCHEMAINFO"
        # Attempt to load the Extract Script
        $sql = $this.CompileScript("ExtractScript")
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
        return $cmd.ExecuteReader()
    }

    [hashtable] Load([System.Data.IDataReader] $DataReader, [System.Collections.ArrayList] $SchemaInfo) {
        if ($this.TableName -eq $null) {
            throw "TableName is a required field."
        }

        # If AutoCreate is set, create the target table using the schema of the incoming data stream. However,
        # always create that table with a unique identifier to avoid any name collisions (will swap out with final
        # table later on).
        $loadIntoTableName = $this.TableName
        if ($this.GetConfigSetting("AutoCreate", $true) -eq $true) {
            $this.TempTableName = $this.GetUniqueID($this.TableName, 128)
            $loadIntoTableName = $this.TempTableName
            $schemaTable = $DataReader.GetSchemaTable()
            $createTableSQL = $this.ScriptCreateTable($this.TempTableName, $SchemaInfo)
            $this.ExecQuery($createTableSQL, $true)
        }
        
        # Use SqlBulkCopy to import the data
        $blk = New-Object Data.SqlClient.SqlBulkCopy($this.ConnectionString)
        $blk.DestinationTableName = $loadIntoTableName
        $blk.BulkCopyTimeout = $this.Timeout
        $blk.BatchSize = $this.GetConfigSetting("BatchSize", 10000)
        $blk.WriteToServer($DataReader)

        # Rename temp table to final table
        if ($this.TempTableName) {
            $this.RenameTable($this.TempTableName, $this.TableName, $this.GetConfigSetting("Overwrite", $true))
        }
        return $null;
    }
    
    [hashtable] Transform() {
        return $this.ExecQuery("TransformScript", $true)
    }

    [hashtable] ExecQuery([string] $ScriptName, [bool] $SupportWriteback) {
        $sql = $this.CompileScript($ScriptName)
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

    [void] Close() {
        # If a connection is established, close connection now.
        if ($this.Connection -ne $null -and $this.Connection.State -eq "Open") {
            $this.Connection.Close()
        }
    }

     [string] ScriptCreateTable([string]$TableName, [System.Collections.ArrayList] $SchemaInfo) {
        $colScript = ""
        foreach ($col in $SchemaInfo) {
            # Extract key variables from the Table Schema
            $name = $col.Name
            $size = $col.Size
            $precision = $col.Precision
            $scale = $col.Scale
            $isKey = $col.IsKey
            $isNullable = $col.IsNullable
            $isIdentity = $col.IsIdentity
            $type = $col.DataType

            # Append column to create script
            $colScript += "`r`n [$name] [$type]"

            # Some data types require special processing...
            if ($type -eq 'VARCHAR' -or $type -eq 'NVARCHAR' -or $type -eq 'CHAR') {
                if ($size -eq -1) {
                    $colScript += '(MAX)'
                }
                else {
                    $colScript += "($size)"
                }
            }
            elseif ($type -eq 'DECIMAL') {
                $colScript += "($precision, $scale)"
            }
            if ($isNullable) {
                $colScript += ' NULL'
            }
            else {
                $colScript += ' NOT NULL'
            }
            $colScript += ", "
        }

        # Remove last comma and return final script
        $colScript = $colScript.Remove($colScript.Length - 2, 2)
        $s = $this.GetTablePart($TableName, 0)
        $t = $this.GetTablePart($TableName, 1)
        return "CREATE TABLE [$s].[$t]($colScript)"
    }

    [string] GetTablePart([string] $TableName, [int] $Token) {
        $parts = $TableName.Split('.')
        if ($parts.Length -le 1) {
            throw "TableName must be in the format Schema.Table"
        }
        return $parts[$Token].Replace('[', '').Replace(']', '')
    }

    [void] CreateAutoIndex([string]$TableName) {
        try {
            $s = $this.GetTablePart($this.TableName, 0)
            $t = $this.GetTablePart($this.TableName, 1)
            $i = $s + '_' + $t.Substring(0, $t.Length - 32)
            $this.ExecNonQuery("CREATE CLUSTERED COLUMNSTORE INDEX [CCIX_$i] ON $TableName WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)")
        }
        catch {
            # If the error is due to a column that cannot participate in a CCIX, then 
            # create the next best kind of index
            # TODO: DECIDE ON ANOTHER INDEX TYPE, EITHER NONCLUSTERED CCIX WITH THE INVALID COLS REMOVED, OR ???
        }
    }

    [void] RenameTable([string] $OldTableName, [string] $NewTableName, [bool] $Overwrite) {
        $t = $this.GetTablePart($NewTableName, 1)

        # If overwrite is enabled, drop target table first.
        if ($Overwrite) {
            $this.ExecQuery("
                SET XACT_ABORT ON
                BEGIN TRAN
                IF (OBJECT_ID('$NewTableName') IS NOT NULL)
                    DROP TABLE $NewTableName
                EXECUTE sp_rename N'$OldTableName', N'$t', 'OBJECT'
                COMMIT TRAN
                ", $false)
        }
        else {
            $this.ExecQuery("EXECUTE sp_rename N'$OldTableName', N'$t', 'OBJECT'", $false)
        }
    }    
}

<#
    [void] RenameTable([string]$OldTableName, [string]$NewTableName, [switch]$Overwrite) {
        $t = $this.GetTableName($NewTableName)

        # If overwrite is enabled, drop target table first.
        if ($Overwrite) {
            $this.ExecNonQuery(`
                    "
                SET XACT_ABORT ON
                BEGIN TRAN
                IF (OBJECT_ID('$NewTableName') IS NOT NULL)
                    DROP TABLE $NewTableName
                EXECUTE sp_rename N'$OldTableName', N'$t', 'OBJECT'
                COMMIT TRAN
                ")
        }
        else {
            $this.ExecNonQuery("EXECUTE sp_rename N'$OldTableName', N'$t', 'OBJECT'")
        }
    }

    [void] DropTable([string]$TableName) {
        $this.ExecNonQuery(`
                "IF (OBJECT_ID('$TableName') IS NOT NULL)
            DROP TABLE $TableName")
    }
}
#>