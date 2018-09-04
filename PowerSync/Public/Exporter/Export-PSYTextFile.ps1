<#
.SYNOPSIS
Exports data from text file.

.DESCRIPTION
Exports data from a text file defined by the supplied connection. Exporters are intended to be paired with Importers via the pipe command.

.PARAMETER Connection
Name of the connection to extract from.

.PARAMETER Path
Path of the file to export. A TextFile connection can supply the root path, which is then prefixed with this path parameter.

.PARAMETER Format
The format of the file (CSV, Tab).

.PARAMETER Header
Whether the first row of the text file contains header information.

.EXAMPLE
Export-PSYTextFile -Connection "TestSource" -Path "Sample100.csv" -Format CSV -Header `
| Import-PSYSqlServer -Connection "TestTarget" -Table "dbo.Sample100" -Create -Index -Concurrent

.NOTES
If the file is a compressed as a ZIP file, it will be decompressed prior to the export operation. All files contained within the ZIP archive are exported as a single stream.
 #>
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
        Write-PSYErrorLog $_ "Error in Export-PSYTextFile."
    }
}