class MSSQLProvider : DataProvider
{   
    MSSQLProvider ([String] $ConnectionString) : base($ConnectionString)
    {
        $this.Connection = New-Object System.Data.SqlClient.SQLConnection($this.ConnectionString)
        $this.Connection.Open()
    }
    
    [object] GetQuerySchema([string]$Query)
    {
        $cmd = $this.CreateCommand("SET FMTONLY ON; $Query")
        $reader = $cmd.ExecuteReader()
        $schemaTable = $reader.GetSchemaTable()
        $reader.Close()
        return $schemaTable
    }

    [string] ScriptCreateTable([string]$TableName, [object]$SchemaTable)
    {
        $colScript = ""
        foreach ($col in $SchemaTable)
        {
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
            if ($type -eq 'VARCHAR' -or $type -eq 'NVARCHAR' -or $type -eq 'CHAR')
            {
                if ($size -eq 2147483647)
                {
                    $colScript + '(MAX)'
                }
                else 
                {
                    $colScript += "($size)"
                }
            }
            elseif ($type -eq 'DECIMAL')
            {
                $colScript += "($precision, $scale)"
            }
            if ($isNullable)
            {
                $colScript += ' NULL'
            }
            else
            {
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

    [string] GetSchemaName([string]$TableName)
    {
        $parts = $TableName.Split('.').Replace('[', '').Replace(']', '')
        return $parts[0]
    }

    [string] GetTableName([string]$TableName)
    {
        $parts = $TableName.Split('.').Replace('[', '').Replace(']', '')
        return $parts[1]
    }

    [void] BulkCopyData([System.Data.Common.DbDataReader]$DataReader, [string]$TableName)
    {
        $blk = New-Object Data.SqlClient.SqlBulkCopy($this.ConnectionString)
        $blk.DestinationTableName = $TableName
        $blk.BulkCopyTimeout = $this.Timeout
        $blk.BatchSize = 10000
        $blk.WriteToServer($DataReader)
    }

    [void] RenameTable([string]$OldTableName, [string]$NewTableName, [switch]$Overwrite)
    {
        $t = $this.GetTableName($NewTableName)

        # If overwrite is enabled, drop target table first.
        if ($Overwrite)
        {
            $this.ExecScript(`
                "
                SET XACT_ABORT ON
                BEGIN TRAN
                IF (OBJECT_ID('$NewTableName') IS NOT NULL)
                    DROP TABLE $NewTableName
                EXECUTE sp_rename N'$OldTableName', N'$t', 'OBJECT'
                COMMIT TRAN
                ")
        }
        else
        {
            $this.ExecScript("EXECUTE sp_rename N'$OldTableName', N'$t', 'OBJECT'")
        }
    }

    [void] CreateAutoIndex([string]$TableName)
    {
        $s = $this.GetSchemaName($TableName)
        $t = $this.GetTableName($TableName)
        $i = $s + '_' + $t.Substring(0, $t.Length - 32)
        $this.ExecScript("CREATE CLUSTERED COLUMNSTORE INDEX [CCIX_$i] ON $TableName WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)")
    }

    [void] DropTable([string]$TableName)
    {
        $this.ExecScript(`
        "IF (OBJECT_ID('$TableName') IS NOT NULL)
            DROP TABLE $TableName")
    }
}