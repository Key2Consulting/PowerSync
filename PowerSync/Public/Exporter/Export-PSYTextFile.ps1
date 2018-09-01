function Export-PSYTextFile {
    param (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [PSYTextFileFormat] $Format,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Header
    )

    try {
        # Initialize source connection
        $c = Get-PSYConnection -Name $Connection
        $filePath = $c.ConnectionString.Trim('\') + '\' + $Path.TrimStart('\')

        # Initialize parsing
        [string] $regexParseExpression = ""
        [string] $colDelim = ""
        if ($Format -eq "CSV") {
            $regexParseExpression = '(?:^|,)(?=[^"]|(")?)"?((?(1)[^"]*|[^,"]*))"?(?=,|$)'      # from https://stackoverflow.com/questions/18144431/regex-to-split-a-csv
            $colDelim = ','
        }
        else {      # assume tab
            $regexParseExpression = '(?:^|\t)(?=[^"]|(")?)"?((?(1)[^"]*|[^\t"]*))"?(?=\t|$)'
            $colDelim = '`t'
        }

        $reader = New-Object PowerSync.TextFileDataReader($filePath, $Header, $regexParseExpression, $colDelim)
        Write-PSYInformationLog -Message "Exported $Format text data from [$Connection]:$Path."

        # Return the reader, as well as some general information about what's being exported. This is to inform the importer
        # of some basic contextual information, which can be used to make decisions on how best to import.
        @{
            DataReader = $reader
            Provider = [PSYDbConnectionProvider]::TextFile
            FilePath = $Path
            Format = $Format
            Header = $Header
        }
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Export-PSYTextFile."
    }
}