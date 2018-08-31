<#
$c = New-Object System.Data.SqlClient.SqlConnection("Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;Database=SqlServerKit")
#$c = New-Object System.Data.OleDb.OleDbConnection("Provider=SQLNCLI11;Server=(LocalDb)\MSSQLLocalDB;Database=SqlServerKit;Trusted_Connection=yes;")

$c.Open()
$cmd = $c.CreateCommand()
$cmd.CommandText = "SELECT * FROM dbo.OddTypes"
$r = $cmd.ExecuteReader()

# Copy results into arraylist of hashtables
if ($r.HasRows) {
    while ($r.Read()) {
        for ($i=0;$i -lt $r.FieldCount; $i++) {
            $col = $r.GetName($i)
            $typeName = $r.GetDataTypeName($i)
            $fieldType = $r.GetFieldType($i)
            $v1 = $r[$i]
            $v6 = $r.GetValue($i)
            $v2 = [byte[]] $r[$i]
            $buffer = [System.Byte[]]::CreateInstance([System.Byte],100)
            $v3 = $r.GetBytes($i, 0, $buffer, 0, 100)
            #$v3 = $r.GetData()
            #$v4 = $r.GetValue($i)
            #$v5 = $r.GetBytes($i)            
            #$v7 = $r.GetBytes($i)
            $x = 1
        }
    }
}
#>
Add-Type -IgnoreWarnings `
    -ReferencedAssemblies ('System.Data', 'System.Xml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089') `
    -TypeDefinition ([System.IO.File]::ReadAllText("D:\Dropbox\Project\Key2\PowerSync\PowerSync\Private\CSharpLibrary\TypeConversionDataReader.cs"))

Add-Type -IgnoreWarnings `
    -ReferencedAssemblies ('System.Data', 'System.Xml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089') `
    -TypeDefinition '
    using System;
    using System.Data;
    
    namespace PowerSync
    {
        public static class Test
        {
            public static int Write(IDataReader reader, System.Data.SqlClient.SqlConnection conn)
            {
                var r = reader;
                var blk = new System.Data.SqlClient.SqlBulkCopy("Server=(LocalDb)\\MSSQLLocalDB;Integrated Security=true;Database=SqlServerKit");
                blk.DestinationTableName = "dbo.SampleTarget";
                blk.BulkCopyTimeout = 30;
                blk.BatchSize = 10000;
                var dataTable = new System.Data.DataTable("Data");
                var schema = r.GetSchemaTable();
                foreach (DataRow c in schema.Rows) {
                    var dataColumn = new System.Data.DataColumn();
                    dataColumn.ColumnName = c["ColumnName"].ToString();
                    //dataColumn.DataType = c["DataType"].GetType();
                    //dataColumn.AllowDBNull = c["AllowDBNull"];
                    dataTable.Columns.Add(dataColumn);
                }
                var rowList = new DataRow[50000];
                int iRow = 0;
                while (r.Read()) {
                    var row = dataTable.NewRow();
                    for (var i = 0; i < r.FieldCount; i++) {
                        row[i] = r[i];
                    }
                    //dataTable.Rows.Add(row);
                    rowList[iRow++] = row;
                }
                //dataTable.AcceptChanges();
                //blk.WriteToServer(dataTable);
                blk.WriteToServer(rowList);
                return 555;
            }
        }
    }
    '
$src = New-Object System.Data.SqlClient.SqlConnection("Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;Database=SqlServerKit")
#$c = New-Object System.Data.OleDb.OleDbConnection("Provider=SQLNCLI11;Server=(LocalDb)\MSSQLLocalDB;Database=SqlServerKit;Trusted_Connection=yes;")

$src.Open()
$cmd = $src.CreateCommand()
$cmd.CommandText = "SELECT * FROM [dbo].[Sample]"
$r = $cmd.ExecuteReader()
$batchSize = 10000

$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
#$x = [PowerSync.Test]::Write($r, $src)

$blk = New-Object Data.SqlClient.SqlBulkCopy("Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;Database=SqlServerKit")
$blk.DestinationTableName = "dbo.SampleTarget"
$blk.BulkCopyTimeout = 30
$blk.BatchSize = $batchSize

$r2 = New-Object PowerSync.TypeConversionDataReader($r)
$blk.WriteToServer($r2)

<#
$blk = New-Object Data.SqlClient.SqlBulkCopy("Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;Database=SqlServerKit")
$blk.DestinationTableName = "dbo.SampleTarget"
$blk.BulkCopyTimeout = 30
$blk.BatchSize = 10000
$dataTable = New-Object System.Data.DataTable("Data")
$schema = $r.GetSchemaTable()
foreach ($c in $schema) {
    $dataColumn = New-Object System.Data.DataColumn
    $dataColumn.ColumnName = $c["ColumnName"]
    #$dataColumn.ColumnOrdinal = $c["ColumnOrdinal"]
    #$dataColumn.ColumnSize = $c["ColumnSize"]
    $dataColumn.DataType = $c["DataType"]
    $dataColumn.AllowDBNull = $c["AllowDBNull"]
    #$dataColumn.NumericPrecision = $c["NumericPrecision"]
    #$dataColumn.NumericScale = $c["NumericScale"]
    $dataTable.Columns.Add($dataColumn)
}
$rowCount = 0
if ($r.HasRows) {
    while ($r.Read()) {     # -and $rowCount -lt $batchSize
        $row = $dataTable.NewRow()
        for ($i = 0; $i -lt $r.FieldCount; $i++) {
            $row[$i] = $r[$i]
        }
        $dataTable.Rows.Add($row);
    }
    $dataTable.AcceptChanges();
    $blk.WriteToServer($dataTable)
}#>

Write-Host $stopWatch.Elapsed.TotalSeconds

$x = 1
<#
SQLBulkCopy1:   9.367, 9.030, 11.395, 9.907
SQLBulkCopy2:   9.367, 10.278, 11.402, 10.595
Custom1:        47.769, 49.234, 60.715
.NET:           22.93, 25.901
2.28, 2.4
.73 vs .47
.66
11.85, 10.62, 10.55
#>

# Copy results into arraylist of hashtables
if ($r.HasRows) {
    while ($r.Read()) {
        for ($i=0;$i -lt $r.FieldCount; $i++) {
            $col = $r.GetName($i)
            $typeName = $r.GetDataTypeName($i)
            $fieldType = $r.GetFieldType($i)
            $v1 = $r[$i]
            $v6 = $r.GetValue($i)
            $v2 = [byte[]] $r[$i]
            $buffer = [System.Byte[]]::CreateInstance([System.Byte],100)
            $v3 = $r.GetBytes($i, 0, $buffer, 0, 100)
            #$v3 = $r.GetData()
            #$v4 = $r.GetValue($i)
            #$v5 = $r.GetBytes($i)            
            #$v7 = $r.GetBytes($i)
            $x = 1
        }
    }
}