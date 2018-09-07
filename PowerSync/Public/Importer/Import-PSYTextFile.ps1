<#
.SYNOPSIS
Imports data into a text file.

.DESCRIPTION
Imports data into a text file defined by the supplied connection. Importers are intended to be paired with Exporters via the pipe command.

The full path to the file is a combination of the base ConnectionString and the Path. Either of those could be omitted, as long as the other supplies the full path.

.PARAMETER Connection
Name of the connection to import into.

.PARAMETER Path
Path of the file to import. A TextFile connection can supply the root path, which is then prefixed with this path parameter.

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
        [Parameter(HelpMessage = "Piped data from Exporter (containing data reader and export provider information)", Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "Name of the connection to import into.", Mandatory = $false)]
        [string] $Connection,
        [Parameter(HelpMessage = "Path of the file to import. A TextFile connection can supply the root path, which is then prefixed with this path parameter.", Mandatory = $false)]
        [string] $Path,
        [Parameter(HelpMessage = "The format of the file (CSV, Tab).", Mandatory = $true)]
        [PSYTextFileFormat] $Format,
        [Parameter(HelpMessage = "Whether the first row of the text file contains header information.", Mandatory = $false)]
        [switch] $Header,
        [Parameter(HelpMessage = "Adds compression to the target file via zip format.", Mandatory = $false)]
        [switch] $Compress
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

        # Prepare file for use
        if ((Test-Path $filePath -PathType Leaf)) {
            Remove-Item -Path $filePath -Force
        }
        $filePath = (New-Item $filePath).FullName

        # Write the file
        $writer = New-Object PowerSync.TextFileDataWriter($filePath, $Format, $Header)
        $writer.Write($InputObject.DataReaders[0])

        # If compression is enabled, compress the file.
        if ($Compress) {
            $archivePath = [System.IO.Path]::ChangeExtension($filePath, "zip")
            if ((Test-Path $archivePath -PathType Leaf)) {
                Remove-Item -Path $archivePath -Force
            }
            Compress-Archive -Path $filePath -CompressionLevel Optimal -DestinationPath $archivePath
            Remove-Item -Path $filePath -Force
        }
        Write-PSYInformationLog -Message "Imported $Format text data into $filePath."
    }
    catch {
        Write-PSYErrorLog $_ "Error in Import-PSYTextFile."
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