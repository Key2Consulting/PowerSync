<#
.SYNOPSIS
Imports data into a text file.

.DESCRIPTION
Imports data into a text file defined by the supplied connection. Importers are intended to be paired with Exporters via the pipe command.

The full path to the file is a combination of the base ConnectionString and the Path. Either of those could be omitted, as long as the other supplies the full path.

If the file extension .gz is used, the file will be compressed using Gzip compression.

.PARAMETER Connection
Name of the connection to import into.

.PARAMETER Path
Path of the file to import. A TextFile connection can supply the root path, which is then prefixed with this path parameter.

If the file extension .gz is used, the file will be compressed using Gzip compression.

.PARAMETER Format
The format of the file (CSV, Tab).

.PARAMETER Header
Whether the first row of the text file contains header information.

.PARAMETER Compress
Adds compression to the target file via zip format.

.EXAMPLE
Export-PSYTextFile -Connection "TestSource" -Path "Sample100.csv" -Format CSV -Header `
| Import-PSYTextFile -Connection "TestTarget" -Table "Sample100.txt" -Format Tab -Header
 #>
function Import-PSYTextFile {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(Mandatory = $false)]
        [object] $Connection,
        [Parameter(Mandatory = $false)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [PSYTextFileFormat] $Format,
        [Parameter(Mandatory = $false)]
        [switch] $Header,
        [Parameter(Mandatory = $false)]
        [switch] $Compress
    )

    try {
        # Initialize source connection
        # If the passed Connection is a name, load it. Otherwise it's an actual object, so just us it.
        if ($Connection -is [string]) {
            $connDef = Get-PSYConnection -Name $Connection
        }
        else {
            $connDef = $Connection
        }
        
        # Construct the full path to the file, which for files is a combination of the base ConnectionString and the Path. Either
        # of those could be omitted.
        if ($connDef -and $connDef.ConnectionString -and $Path) {
            $filePath = $connDef.ConnectionString.Trim('\') + '\' + $Path.TrimStart('\')
        }
        elseif ($connDef -and $connDef.ConnectionString) {
            $filePath = $connDef.ConnectionString
        }
        elseif ($Path) {
            $filePath = $Path
        }
        else {
            throw 'Unable to acquire connection as no paths were set by connection or importer.'
        }

        if ($filePath.Contains('*') -or $filePath.Contains('?')) {
            throw "Wildcards not implemented."      # TODO: Support wildcards and multiple readers.
        }

        # Delete if already exists.
        if ((Test-Path $filePath -PathType Leaf)) {
            Remove-Item -Path $filePath -Force
        }
        $filePath = (New-Item $filePath).FullName

        # Open the file stream.
        $stream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open)

        # If the file path points to a Gzip archive.
        if ($filePath.EndsWith('.gz')) {
            $gzStream = [System.IO.Compression.GzipStream]::new($stream, [IO.Compression.CompressionMode]::Compress, $false)
        }
        else {
            $gzStream = $stream
        }

        # Write the file
        $writer = [PowerSync.TextFileDataWriter]::new($gzStream, $Format, $Header)
        $writer.Write($InputObject.DataReaders[0])

        Write-PSYInformationLog -Message "Imported $Format text data into $filePath."
    }
    catch {
        Write-PSYErrorLog $_
    }
    finally {
        # Dispose of all data readers now that import is complete.
        foreach ($reader in $InputObject.DataReaders) {
            $reader.Dispose()
        }
        # If the exporter requires cleanup, invoke their logic now.
        if ($InputObject.ContainsKey('OnCompleteScriptBlock')) {
            Invoke-Command -ScriptBlock $InputObject.OnCompleteScriptBlock -InputObject $InputObject.OnCompleteInputObject
        }
    }
}