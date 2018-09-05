<#
.SYNOPSIS
Exports data from text file.

.DESCRIPTION
Exports data from a text file defined by the supplied connection. Exporters are intended to be paired with Importers via the pipe command.

The full path to the file is a combination of the base ConnectionString and the Path. Either of those could be omitted, as long as the other supplies the full path.

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
        [Parameter(HelpMessage = "Name of the connection to extract from.", Mandatory = $false)]
        [string] $Connection,
        [Parameter(HelpMessage = "Path of the file to export. A TextFile connection can supply the root path, which is then prefixed with this path parameter.", Mandatory = $false)]
        [string] $Path,
        [Parameter(HelpMessage = "The format of the file (CSV, Tab).", Mandatory = $true)]
        [PSYTextFileFormat] $Format,
        [Parameter(HelpMessage = "Whether the first row of the text file contains header information.", Mandatory = $false)]
        [switch] $Header
    )

    try {
        # Initialize source connection
        $connDef = Get-PSYConnection -Name $Connection
        
        # Construct the full path to the file, which for files is a combination of the base ConnectionString and the Path. Either
        # of those could be omitted.
        if ($connDef.ConnectionString -and $Path) {
            $filePath = $connDef.ConnectionString.Trim('\') + '\' + $Path.TrimStart('\')
        }
        elseif ($Path) {
            $filePath = $Path
        }
        elseif ($connDef.ConnectionString) {
            $filePath = $connDef.ConnectionString
        }

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
        Write-PSYInformationLog -Message "Exported $Format text data from $filePath."

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