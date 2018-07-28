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
    [int] get_Depth() {
        return 0
    }
}