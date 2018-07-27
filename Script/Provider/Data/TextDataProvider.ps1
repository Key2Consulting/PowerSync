class TextDataProvider : DataProvider {
    [string] $FilePath
    [bool] $Header
    [string] $Format

    TextDataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
    }
    
    [object] GetQuerySchema([string]$Query) {
        # adapted from https://blog.netnerds.net/2015/01/powershell-high-performance-techniques-for-importing-csv-to-sql-server/

        #$reader = New-Object System.IO.StreamReader($this.FilePath)
        $schemaList = New-Object System.Collections.ArrayList
        if ($this.Header) {
            $columns = (Get-Content $this.FilePath -First 1).Split(',')
            foreach ($col in $columns) {
                $item = @{
                    "name" = $col;
                    "size" = -1;
                    "precision" = 0;
                    "scale" = 0;
                    "isNullable" = $true;
                    "type" = "NVARCHAR";
                }
                $schemaList.Add($item);
            }            
        }
        else {
            throw "Not Implemented:  TextProvider no header option"
        }

        # $csvsplit += '(?=(?:[^"]|"[^"]*")*$)'
        # $regexOptions = [System.Text.RegularExpressions.RegexOptions]::ExplicitCapture
        # $columns = [regex]::Split($firstLine, $csvSplit, $regexOptions)

        #$reader.readLine()

        return $schemaList
    }

    [string] ScriptCreateTable([string]$TableName, [object]$SchemaTable) {
        return $null
    }

    [string] GetSchemaName([string]$TableName) {
        return $null
    }

    [string] GetTableName([string]$TableName) {
        return $null
    }

    [void] BulkCopyData([System.Data.Common.DbDataReader]$DataReader, [string]$TableName) {
    }

    [void] RenameTable([string]$OldTableName, [string]$NewTableName, [switch]$Overwrite) {
    }

    [void] CreateAutoIndex([string]$TableName) {
    }

    [void] DropTable([string]$TableName) {
    }
}