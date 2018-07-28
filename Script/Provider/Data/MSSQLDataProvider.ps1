# Represents the abstract base class for the DataProvider interface, and includes some functionality common to all providers
class MSSQLDataProvider : DataProvider {

    MSSQLDataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
    }

    [hashtable] Prepare() {
        return $this.ExecWriteback("PrepareScript")
    }

    [object] Extract() {
        return $null;
    }

    [hashtable] Load([object] $DataReader) {
        return $null;
    }
    
    [hashtable] Transform() {
        return $this.Configuration;     # todo
    }

    [hashtable] ExecWriteback([string] $ScriptName) {
        $sql = $this.CompileScript($ScriptName)
        $h = $this.Configuration
        if ($sql -ne $null) {
            try {
                # Execute Query
                $this.Connection = New-Object System.Data.SqlClient.SQLConnection($this.ConnectionString)
                $this.Connection.Open()
                $cmd = $this.Connection.CreateCommand()
                $cmd.CommandText = $sql
                $cmd.CommandTimeout = $this.GetConfigSetting("Timeout", 3 * 3600)
                $reader = $cmd.ExecuteReader()

                # Copy results into hashtable (only single row supported)
                $b = $reader.Read()
                for ($i=0;$i -lt $reader.FieldCount; $i++) {
                    $col = $reader.GetName($i)
                    if ($h.ContainsKey($col)) {
                        $h."$col" = $reader[$col]
                    }
                }
            }
            finally {
                if ($this.Connection -ne $null -and $this.Connection.State -eq "Open") {
                    $this.Connection.Close()
                }
            }
        }
        return $h
    }
}

<#
class MSSQLDataProvider : DataProvider {
    MSSQLDataProvider ([String] $ConnectionString) : base($ConnectionString) {
        $this.Connection = New-Object System.Data.SqlClient.SQLConnection($this.ConnectionString)
        $this.Connection.Open()
    }
    
    [object] GetQuerySchema([string]$Query) {
        $cmd = $this.CreateCommand("SET FMTONLY ON; $Query")
        $reader = $cmd.ExecuteReader()
        c
        $reader.Close()
        $cmd.CommandText = "SET FMTONLY OFF"
        $cmd.ExecuteNonQuery()
        return $schemaTable
    }

    [string] ScriptCreateTable([string]$TableName, [object]$SchemaTable) {
        $colScript = ""
        foreach ($col in $SchemaTable) {
            # Extract key variables from the Table Schema
            $name = $col[0]
            $size = $col[2]
            $precision = $col[3]
            $scale = $col[4]
            $isKey = $col[6]
            $isNullable = $col[13]
            $isIdentity = $col[14]
            $type = $col[24]

            # Append column to create script
            $colScript += "`r`n [$name] [$type]"

            # Some data types require special processing...
            if ($type -eq 'VARCHAR' -or $type -eq 'NVARCHAR' -or $type -eq 'CHAR') {
                if ($size -eq 2147483647) {
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
        $s = $this.GetSchemaName($TableName)
        $t = $this.GetTableName($TableName)
        return "CREATE TABLE [$s].[$t]($colScript)"
    }

    [string] GetSchemaName([string]$TableName) {
        $parts = $TableName.Split('.').Replace('[', '').Replace(']', '')
        return $parts[0]
    }

    [string] GetTableName([string]$TableName) {
        $parts = $TableName.Split('.').Replace('[', '').Replace(']', '')
        return $parts[1]
    }

    [void] BulkCopyData([System.Data.Common.DbDataReader]$DataReader, [string]$TableName) {
        $blk = New-Object Data.SqlClient.SqlBulkCopy($this.ConnectionString)
        $blk.DestinationTableName = $TableName
        $blk.BulkCopyTimeout = $this.Timeout
        $blk.BatchSize = 10000
        $blk.WriteToServer($DataReader)
    }

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

    [void] CreateAutoIndex([string]$TableName) {
        try {
            $s = $this.GetSchemaName($TableName)
            $t = $this.GetTableName($TableName)
            $i = $s + '_' + $t.Substring(0, $t.Length - 32)
            $this.ExecNonQuery("CREATE CLUSTERED COLUMNSTORE INDEX [CCIX_$i] ON $TableName WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)")
        }
        catch {
            # If the error is due to a column that cannot participate in a CCIX, then 
            # create the next best kind of index
            # TODO: DECIDE ON ANOTHER INDEX TYPE, EITHER NONCLUSTERED CCIX WITH THE INVALID COLS REMOVED, OR ???
        }
    }

    [void] DropTable([string]$TableName) {
        $this.ExecNonQuery(`
                "IF (OBJECT_ID('$TableName') IS NOT NULL)
            DROP TABLE $TableName")
    }
}
#>