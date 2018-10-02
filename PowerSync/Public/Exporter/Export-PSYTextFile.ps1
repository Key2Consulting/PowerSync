<#
.SYNOPSIS
Exports data from text file.

.DESCRIPTION
Exports data from a text file defined by the supplied connection. Exporters are intended to be paired with Importers via the pipe command.

The full path to the file is a combination of the base ConnectionString and the Path. Either of those could be omitted, as long as the other supplies the full path.

If the file extension .gz is used, the file will be decompressed using Gzip compression.

.PARAMETER Connection
Name of the connection to extract from.

.PARAMETER Path
Path of the file or files to export (supports wildcards). A TextFile connection can supply the root path, which is then prefixed with this path parameter. If path is a Zip archive, will be uncompressed prior to execution.

If the file extension .gz is used, the file will be decompressed using Gzip compression.

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
        [Parameter(HelpMessage = "Path of the file or files to export (supports wildcards).", Mandatory = $false)]
        [string] $Path,
        [Parameter(HelpMessage = "The format of the file (CSV, Tab).", Mandatory = $true)]
        [PSYTextFileFormat] $Format,
        [Parameter(HelpMessage = "Whether the first row of the text file contains header information.", Mandatory = $false)]
        [switch] $Header
    )
    
    try {
        # Initialize source connection
        if ($Connection) {
            $connDef = Get-PSYConnection -Name $Connection
        }
        else {
            $connDef = $null
        }

        # Construct the full path to the file, which for files is a combination of the base ConnectionString and the Path. Either
        # of those could be omitted.
        if ($connDef -and $connDef.ConnectionString -and $Path) {
            $filePath = $connDef.ConnectionString.Trim('\') + '\' + $Path.TrimStart('\')
        }
        elseif ($Path) {
            $filePath = $Path
        }
        elseif ($connDef.ConnectionString) {
            $filePath = $connDef.ConnectionString
        }

        if ($filePath.Contains('*') -or $filePath.Contains('?')) {
            throw "Wildcards not implemented."      # TODO: Support wildcards and multiple readers.
        }

        # Open the file stream.
        $stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open)

        # If the file path points to a Gzip archive.
        if ($filePath.EndsWith('.gz')) {
            $gzStream = [System.IO.Compression.GzipStream]::new($stream, [IO.Compression.CompressionMode]::Decompress, $false)
        }
        else {
            $gzStream = $stream
        }

        $reader = [PowerSync.TextFileDataReader]::new($gzStream, $Format, $Header)

        Write-PSYInformationLog -Message "Exported $Format text data from $filePath."

        # Return the reader, as well as some general information about what's being exported. This is to inform the importer
        # of some basic contextual information, which can be used to make decisions on how best to import.
        @{
            DataReaders = @($reader)
            Provider = [PSYDbConnectionProvider]::TextFile
            FilePath = $filePath
            Format = $Format
            Header = $Header
            OnCompleteInputObject = $expandedPath
            OnCompleteScriptBlock = {
                # If we unzipped an archive, clean up uncompressed files
                if ($Input) {
                    Remove-Item -Path $Input -Recurse
                }
            }
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}