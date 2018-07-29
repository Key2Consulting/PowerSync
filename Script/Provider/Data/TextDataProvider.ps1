class TextDataProvider : DataProvider, System.Data.IDataReader {
    [string] $FilePath
    [string] $Format
    [bool] $Header
    [bool] $Quoted
    [string] $RowDelim = '`r`n'
    [string] $ColDelim = ','
    [string] $QuoteDelim = '"'
    [System.IO.StreamReader] $FileReader
    [System.Collections.ArrayList] $ReadBuffer

    TextDataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.FilePath = $this.ConnectionStringParts["filepath"]
        $this.Format = $this.ConnectionStringParts["format"]
        $this.Header = $this.ConnectionStringParts["header"]
        $this.Quoted = $this.ConnectionStringParts["quoted"]
    }

    [hashtable] Prepare() {
        # Can text providers support scripting?  Regex?
        return $null;
    }

    [object[]] Extract() {
        # Open target file, and extract schema information. Note that we only support
        # text data types since the tex files don't come with data type information.
        $this.FileReader = New-Object System.IO.StreamReader $this.FilePath

        $this.Read()
        $colIndex = 1
        $this.SchemaInfo = New-Object System.Collections.ArrayList
        foreach ($c in $this.ReadBuffer) {
            $s = New-Object SchemaInformation
            if ($this.Header) {
                $s.Name = $c
            }
            else {
                $s.Name = $colIndex++
            }
            $s.Size = -1
            $s.DataType = "VARCHAR"
            $s.IsNullable = $true
            $this.SchemaInfo.Add($s)
        }

        # If header isn't first line, must reset read back to beginning
        if ($this.Header -ne $true) {
            $this.FileReader.Position = 0
            $this.FileReader.DiscardBufferedData()
        }
        return [System.Data.IDataReader]$this, $this.SchemaInfo
    }

    [hashtable] Load([System.Data.IDataReader] $DataReader, [System.Collections.ArrayList] $SchemaInfo) {
        throw "Not Implemented"
    }
    
    [hashtable] Transform() {
        # Can text providers support scripting?  Regex?
        return $null;
    }

    [void] Close() {
    }


    ###############################################################
    # System.Data.IDataReader Interface Implementation
    ###############################################################

    # The following interface elements are invoked by SqlBulkCopy
    #
    [int] get_FieldCount() {
        return $this.SchemaInfo.Count
    }

    [bool] Read() {
        $l = $this.FileReader.ReadLine()        # how can row delimeter be applied?
        if ($l -eq $null -or $l.Length -eq 0) {
            $this.FileReader.Close()
            return $false
        }
        $this.ReadBuffer = New-Object System.Collections.ArrayList
        
        # from https://stackoverflow.com/questions/18144431/regex-to-split-a-csv        
        $regex = '(?:^|,)(?=[^"]|(")?)"?((?(1)[^"]*|[^,"]*))"?(?=,|$)'
        $matches = [regex]::Matches($l, $regex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)        
        
        foreach ($match in $matches) {
            [string]$s = $match.Value.ToString()
            if ($s.StartsWith($this.ColDelim)) {
                $s = $s.Substring($this.ColDelim.Length, $s.Length - $this.ColDelim.Length)
            }
            $this.ReadBuffer.Add($s)
        }
        
        return $true
    }

    [object] GetValue([int] $I) {
        return $this.ReadBuffer[$I]
    }

    # Ignore the following interface elements until they're needed.
    #

    [System.Data.DataTable] GetSchemaTable() {
        return $null
    }

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

    # ALREADY IMPLEMENTED BY Provider [void] Close() { throw "TextDataProvider Interface not Implemented" }

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