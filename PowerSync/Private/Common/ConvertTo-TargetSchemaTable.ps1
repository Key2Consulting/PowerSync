function ConvertTo-TargetSchemaTable {
    param (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [PSYDbConnectionProvider] $SourceProvider,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [PSYDbConnectionProvider] $TargetProvider,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [System.Data.DataTable] $SchemaTable
    )

    try {
        # Create new schema table to hold the results of the map.
        $newSchemaTable = [System.Data.DataTable]::new()
        [void] $newSchemaTable.Clear()
        [void] $newSchemaTable.Columns.Add("ColumnName");
        [void] $newSchemaTable.Columns.Add("ColumnOrdinal");
        [void] $newSchemaTable.Columns.Add("ColumnSize");
        [void] $newSchemaTable.Columns.Add("DataTypeName");
        [void] $newSchemaTable.Columns.Add("AllowDBNull");
        [void] $newSchemaTable.Columns.Add("NumericPrecision");
        [void] $newSchemaTable.Columns.Add("NumericScale");
        [void] $newSchemaTable.Columns.Add("TransportDataTypeName");

        foreach ($srcCol in $SchemaTable) {
            $col = $newSchemaTable.NewRow()
            $col["ColumnName"] = $srcCol["ColumnName"]
            $col["ColumnOrdinal"] = $srcCol["ColumnOrdinal"]
            $col["ColumnSize"] = $srcCol["ColumnSize"]
            $col["DataTypeName"] = Select-Coalesce @($srcCol["DataTypeName"], $srcCol["DataType"].ToString(), $srcCol["UdtAssemblyQualifiedName"])      # odd types don't have simple type name, so get next best
            $col["AllowDBNull"] = $srcCol["AllowDBNull"]
            $col["NumericPrecision"] = $srcCol["NumericPrecision"]
            $col["NumericScale"] = $srcCol["NumericScale"]
            $col["TransportDataTypeName"] = $null
            [void] $newSchemaTable.Rows.Add($col);
            
            # Debugging columns
            $columnName = $col["ColumnName"]
            $dataTypeName = $col["DataTypeName"]
            $columnSize = $col["ColumnSize"]

            # Apply map rules
            if ($col["DataTypeName"].Contains('CHAR')) {
                # If size is greater than 8000 chars, convert to -1 to indicate unlimited.
                if ($col["ColumnSize"] -gt 8000) {
                    $s.Size = -1
                }
            }

            if ($col["DataTypeName"].Contains('string')) {
                $col["DataTypeName"] = 'VARCHAR'        # map 'string' to 'varchar'
                if ($col["ColumnSize"] -gt 8000 -or -not $col["ColumnSize"]) {      # set size to max if empty or exceeds 8000 characters
                    $col["ColumnSize"] = -1
                }
            }
            
            # Special purpose data types (i.e. Geography) causes issues when being transported via SqlBulkCopy. We get around this by converting it to
            # binary during the transportion/reading of the data.
            #
            # Sql Server Geography
            if ($col["DataTypeName"].Contains("geography")) {
                $col["DataTypeName"] = "geography"
                $col["TransportDataTypeName"] = "BINARY"
            }
            # Sql Server Geometry
            if ($col["DataTypeName"].Contains("geometry")) {
                $col["DataTypeName"] = "geometry"
                $col["TransportDataTypeName"] = "BINARY"
            }
            # SqlServer Hierarchyid
            if ($col["DataTypeName"].Contains("hierarchyid")) {
                $col["DataTypeName"] = "hierarchyid"
                $col["TransportDataTypeName"] = "BINARY"
            }
        }

        # Return converted schema table adapted for target system
        return $newSchemaTable

        # Translate the schema table into an array of hashtables representing the
        # various IDataReader SchemaTable properties. In addition, translate any
        # provider specific types to standard ANSI SQL data types which can be used
        # by any importer regardless of the provider.
        <#$schemaTable = $InputObject.DataReader.GetSchemaTable()
        $schemaTableList = New-Object System.Collections.ArrayList
        foreach ($col in $schemaTable) {
            $schemaTableCol = [ordered] @{
                ColumnName = $col["ColumnName"]
                ColumnOrdinal = $col["ColumnOrdinal"]
                ColumnSize = $col["ColumnSize"]
                DataType = $col["DataType"]
                AllowDBNull = $col["AllowDBNull"]
                NumericPrecision = $col["NumericPrecision"]
                NumericScale = $col["NumericScale"]
            }
        
        # Conversions based on the following
        # https://www.postgresql.org/docs/9.5/static/datatype.html
        # https://docs.oracle.com/cd/B14117_01/server.101/b10758/sqlqr06.htm
        # https://msdn.microsoft.com/en-us/library/office/ff195814.aspx?f=255&MSPPError=-2147217396
        $map = @(
            # SQL Type, ANSI Type
            @('BINARY', 'BIT')
            ,@('VARBINARY', 'BIT VARYING')
            ,@('BIT', 'BOOLEAN')
            ,@('TINYINT', 'SMALLINT')
            ,@('MONEY', 'FLOAT')
            ,@('DATETIME', 'TIMESTAMP')
            ,@('DATETIME2', 'TIMESTAMP')
            ,@('UNIQUEIDENTIFIER', 'CHAR')
            ,@('DECIMAL', 'DECIMAL')
            ,@('FLOAT', 'FLOAT')
            ,@('INT', 'INTEGER')
            ,@('IMAGE', 'BIT VARYING')
            ,@('TEXT', 'CHARACTER VARYING')
            ,@('CHAR', 'CHARACTER')
            ,@('VARCHAR', 'CHARACTER VARYING')
            ,@('NCHAR', 'NATIONAL CHARACTER')
            ,@('NVARCHAR', 'NATIONAL CHARACTER VARYING')
        )
        #>
    }
    catch {
        Write-PSYExceptionLog $_ "Error in ConvertTo-TargetSchemaTable."
    }
}