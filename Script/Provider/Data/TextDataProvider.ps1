class TextDataProvider : DataProvider {
    [string] $FilePath
    [bool] $Header
    [string] $Format

    TextDataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
    }

    [hashtable] Prepare() {
        # Can text providers support scripting?  Regex?
        return $null;
    }

    [System.Data.IDataReader] Extract() {
        $r = New-Object TextDataReader
        #$provider = New-Object TextDataProvider($Namespace, $Configuration)
        return $r
    }

    [hashtable] Load([System.Data.IDataReader] $DataReader) {
        throw "Not Implemented"
    }
    
    [hashtable] Transform() {
        # Can text providers support scripting?  Regex?
        return $null;
    }

    [void] Close() {
    }

    [object] GetQuerySchema() {
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

        return $schemaList
    }
}

class TextDataReader : System.Data.IDataReader {
    [int] $ReadCount

    # The following interface elements are invoked by SqlBulkCopy
    #
    [System.Data.DataTable] GetSchemaTable() {
        return $null
    }

    [bool] Read() {
        return $this.ReadCount++ -lt 100
    }    

    [int] get_FieldCount() {
        $this.ReadCount = 0
        return 1
    }

    [object] GetValue([int] $I) {
        return "foo"
    }

    # Ignore the following interface elements until they're needed.
    #

    [int] get_Depth() {
        throw "TextDataProvider Interface not Implemented"
        return 0
    }

    [bool] get_IsClosed() {
        throw "TextDataProvider Interface not Implemented"
        return $false
    }
    
    [int] get_RecordsAffected() {
        throw "TextDataProvider Interface not Implemented"
        return 0
    }

    [void] Close() {
        throw "TextDataProvider Interface not Implemented"
    }

    [bool] NextResult() {
        throw "TextDataProvider Interface not Implemented"
        return $true;
    }

    [void] Dispose() {
        throw "TextDataProvider Interface not Implemented"
    }    

    [object] get_Item([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [object] get_Item([string] $Name) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [string] GetName([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return ""
    }

    [string] GetDataTypeName([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return ""
    }

    [System.Type] GetFieldType([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [int] GetValues([object[]] $Values) {
        throw "TextDataProvider Interface not Implemented"
        return 0
    }

    [int] GetOrdinal([string] $Name) {
        throw "TextDataProvider Interface not Implemented"
        return 0
    }

    [bool] GetBoolean([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [byte] GetByte([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [long] GetBytes([int] $I, [long] $FieldOffset, [byte[]] $Buffer, [int] $Bufferoffset, [int] $Length) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [char] GetChar([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [long] GetChars([int] $I, [long] $FieldOffset, [char[]] $Buffer, [int] $Bufferoffset, [int] $Length) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [guid] GetGuid([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [int16] GetInt16([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [int32] GetInt32([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [int64] GetInt64([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }
    
    [float] GetFloat([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [double] GetDouble([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [string] GetString([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [decimal] GetDecimal([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [datetime] GetDateTime([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [System.Data.IDataReader] GetData([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }

    [bool] IsDBNull([int] $I) {
        throw "TextDataProvider Interface not Implemented"
        return $null
    }
}