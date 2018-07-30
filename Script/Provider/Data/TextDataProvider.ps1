class TextDataProvider : DataProvider, System.Data.IDataReader {
    [string] $FilePath
    [string] $Format
    [bool] $Header
    [bool] $Quoted
    [string] $RowDelim = '`r`n'
    [string] $ColDelim
    [string] $QuoteDelim = '"'
    [System.IO.StreamReader] $FileReader
    [string[]] $ReadBuffer
    [string] $Regex
    [string] $CSVRegex = '(?:^|,)(?=[^"]|(")?)"?((?(1)[^"]*|[^,"]*))"?(?=,|$)'      # from https://stackoverflow.com/questions/18144431/regex-to-split-a-csv
    [string] $TabRegex = '(?:^|\t)(?=[^"]|(")?)"?((?(1)[^"]*|[^\t"]*))"?(?=\t|$)'

    TextDataProvider ([string] $Namespace, [hashtable] $Configuration) : base($Namespace, $Configuration) {
        $this.FilePath = $this.ConnectionStringParts["filepath"]
        $this.Format = $this.ConnectionStringParts["format"]
        $this.Header = $this.ConnectionStringParts["header"]
        $this.Quoted = $this.ConnectionStringParts["quoted"]
        if ($this.Format -eq "CSV") {
            $this.Regex = $this.CSVRegex
            $this.ColDelim = ','
        }
        else {      # assume tab
            $this.Regex = $this.TabRegex
            $this.ColDelim = '`t'
        }
    }

    [hashtable] Prepare() {
        # Can text providers support scripting?  Regex?
        return $null;
    }

    [object[]] Extract() {
        # Open target file, and extract schema information. Note that we only support
        # text data types since the tex files don't come with data type information.
        #
        $this.FileReader = New-Object System.IO.StreamReader $this.FilePath

        # Read the first line to extract column information. Even if no header is set, we
        # still need to know how many columns there are.
        $l = $this.FileReader.ReadLine()                
        $matches = [regex]::Matches($l, $this.Regex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)                
        $this.ReadBuffer = (1..$matches.Count)      # preallocate once and only once for performance
        $this.SchemaInfo = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $matches.Count; $i++) {
            $this.ReadBuffer[$i] = $matches[$i].Value
            if ($this.ReadBuffer[$i][0] -eq $this.ColDelim) {
                $this.ReadBuffer[$i] = $this.ReadBuffer[$i].Substring($this.ColDelim.Length, $this.ReadBuffer[$i].Length - $this.ColDelim.Length)
            }
            # Create an entry in our schema info array for callers and later use
            $s = New-Object SchemaInformation
            if ($this.Header) {
                $s.Name = $this.ReadBuffer[$i]
            }
            else {
                $s.Name = $i
            }
            $s.Size = -1            # we only support VARCHAR(MAX) and leave it up to downstream logic to convert
            $s.DataType = "VARCHAR"
            $s.IsNullable = $true
            $this.SchemaInfo.Add($s)
        }

        # If header isn't first line, must reset read back to beginning
        if ($this.Header -ne $true) {
            $this.FileReader.Position = 0
            $this.FileReader.DiscardBufferedData()
        }
        
        # Initialize processing
        $this.ReadBuffer = (1..$this.SchemaInfo.Count)      # preallocate once for performance

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
        if ($l -eq $null) {
            $this.FileReader.Close()
            return $false
        }
        
        # Use REGEX to parse out the CSV fields. Will handle quotes.
        $matches = [regex]::Matches($l, $this.Regex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline)
        for ($i = 0; $i -lt $matches.Count; $i++) {
            $this.ReadBuffer[$i] = $matches[$i].Value
            if ($this.ReadBuffer[$i][0] -eq $this.ColDelim) {
                $this.ReadBuffer[$i] = $this.ReadBuffer[$i].Substring($this.ColDelim.Length, $this.ReadBuffer[$i].Length - $this.ColDelim.Length)
            }
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