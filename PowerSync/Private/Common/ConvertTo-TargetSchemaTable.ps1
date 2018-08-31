function New-TypeConversionTable {
    param (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [PSYDbConnectionProvider] $SourceProvider,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [PSYDbConnectionProvider] $TargetProvider,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [object] $SchemaTable
    )

    try {
        # Translate the schema table into an array of hashtables representing the
        # various IDataReader SchemaTable properties. In addition, translate any
        # provider specific types to standard ANSI SQL data types which can be used
        # by any importer regardless of the provider.
        $schemaTable = $InputObject.DataReader.GetSchemaTable()
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
            
            # Translate basic types
            # https://www.postgresql.org/docs/9.5/static/datatype.html
            # https://docs.oracle.com/cd/B14117_01/server.101/b10758/sqlqr06.htm
            # https://msdn.microsoft.com/en-us/library/office/ff195814.aspx?f=255&MSPPError=-2147217396
            # TODO: THIS IS A WORK IN PROGRESS. CONSIDER HOW WE COULD MAKE THE MAP DATA DRIVEN I.E. A CSV FILE.
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
            if ($schemaTableCol.DataType -eq 'VARCHAR') {
                $s.Size = -1
            }

            # If size is greater than 8000 chars, convert to -1 to indicate unlimited.
            if ($schemaTableCol.ColumnSize -gt 8000) {
                $s.Size = -1
            }

            # Detect if special type Geography
            if ($schemaTableCol.DataType.Contains("geography")) {
                $schemaTableCol.DataType = "geography"
            }

            [void] $schemaTableList.Add($schemaTableCol)
        }
        
        return $schemaTableList
    }
    catch {
        Write-PSYExceptionLog $_ "Error in ConvertTo-UniversalSchema."
    }
}