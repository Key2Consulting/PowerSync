<#
.SYNOPSIS
.DESCRIPTION

.PARAMETER Manifest

.EXAMPLE
PowerSync `
    -Source @{
        ConnectionString = "PSProvider=TextDataProvider;FilePath=$C:\Temp\TestCSVToSQL\Sample100.csv;Header=False;Format=CSV;Quoted=True";
    } `
    -Target @{
        ConnectionString = "PSProvider=MSSQLDataProvider;Server=$sqlServerInstance;Integrated Security=true;Database=$testDBPath;";
        Schema = "dbo"
        Table = "TestCSVToSQL100"
        AutoCreate = $true;
        Overwrite = $true;
    }
.NOTES
 #>

# Conversions based on the following
# https://www.postgresql.org/docs/9.5/static/datatype.html
# https://docs.oracle.com/cd/B14117_01/server.101/b10758/sqlqr06.htm
# https://msdn.microsoft.com/en-us/library/office/ff195814.aspx?f=255&MSPPError=-2147217396
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
            
            # Convenience variables
            $columnName = $col["ColumnName"]
            $dataTypeName = $col["DataTypeName"]
            $columnSize = [int] $col["ColumnSize"]

            # Apply map rules
            if ($col["DataTypeName"] -match 'CHAR') {
                # If size is greater than 8000 chars or 400 nchars, convert to -1 to indicate unlimited.
                if ($col["DataTypeName"] -match 'N' -and $columnSize -gt 4000) {
                    $col["ColumnSize"] = -1
                }
                elseif ($columnSize -gt 8000) {
                    $col["ColumnSize"] = -1
                }
            }

            if ($col["DataTypeName"] -match 'string') {
                $col["DataTypeName"] = 'VARCHAR'        # map 'string' to 'varchar'
                if ($columnSize -gt 8000 -or -not $col["ColumnSize"]) {      # set size to max if empty or exceeds 8000 characters
                    $col["ColumnSize"] = -1
                }
            }
            
            # Special purpose data types (i.e. Geography) causes issues when being transported via SqlBulkCopy. We get around this by converting it to
            # binary during the transportion/reading of the data.
            #
            # Sql Server Geography
            if ($col["DataTypeName"] -match "geography") {
                $col["DataTypeName"] = "geography"
                $col["TransportDataTypeName"] = "BINARY"
            }
            # Sql Server Geometry
            if ($col["DataTypeName"] -match "geometry") {
                $col["DataTypeName"] = "geometry"
                $col["TransportDataTypeName"] = "BINARY"
            }
            # SqlServer Hierarchyid
            if ($col["DataTypeName"] -match "hierarchyid") {
                $col["DataTypeName"] = "hierarchyid"
                $col["TransportDataTypeName"] = "BINARY"
            }
        }

        # Return converted schema table adapted for target system
        return $newSchemaTable
    }
    catch {
        Write-PSYErrorLog $_
    }
}