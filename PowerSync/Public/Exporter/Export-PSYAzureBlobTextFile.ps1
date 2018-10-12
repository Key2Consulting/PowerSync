<#
.SYNOPSIS
Exports data from text file stored in Azure Blob storage, with optional decompression.

.DESCRIPTION
Exports data from a text file defined by the supplied connection. Exporters are intended to be paired with Importers via the pipe command.

The full path to the file is a combination of the base ConnectionString and the Path. Either of those could be omitted, as long as the other supplies the full path.

If the file extension .gz is used, the file will be decompressed using Gzip compression.

.PARAMETER Connection
Name of the connection to extract from.

.PARAMETER Container
Azure blob storage container.

.PARAMETER Path
Path of the file or files to export (supports wildcards). A TextFile connection can supply the root path, which is then prefixed with this path parameter. If path is a Zip archive, will be uncompressed prior to execution.

If the file extension .gz is used, the file will be decompressed using Gzip compression.

.PARAMETER Format
The format of the file (CSV, Tab).

.PARAMETER Header
Whether the first row of the text file contains header information.

.PARAMETER Stream
Streams the file from Blob storage, oppose to downloading it by default. Most times, Downloading first is generally faster than Streaming, and is cheaper due to Azure operation transaction costs.
https://stackoverflow.com/questions/13020158/reading-line-by-line-from-blob-storage-in-windows-azure

.EXAMPLE
Export-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Sample10000.csv" -Format CSV -Header `
| Import-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Temp/AzureDownloadSample10000.gz" -Format CSV -Header
 #>
 function Export-PSYAzureBlobTextFile {
    param (
        [Parameter(Mandatory = $false)]
        [object] $Connection,
        [Parameter(Mandatory = $false)]
        [string] $Container,
        [Parameter(Mandatory = $false)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [PSYTextFileFormat] $Format,
        [Parameter(Mandatory = $false)]
        [switch] $Header,
        [Parameter(Mandatory = $false)]
        [switch] $Stream
    )
    
    try {
        # If the passed Connection is a name, load it. Otherwise it's an actual object, so just us it.
        if ($Connection -is [string]) {
            $connDef = Get-PSYConnection -Name $Connection
        }
        else {
            $connDef = $Connection
        }
        
        # Connect to the Blob
        $ctx = New-AzureStorageContext -ConnectionString $connDef.ConnectionString
        $blob = Get-AzureStorageBlob -Container $Container -Blob $Path -Context $ctx
        $blobStream = $blob.ICloudBlob.OpenRead()

        if ($Path.Contains('*') -or $Path.Contains('?')) {
            throw "Wildcards not implemented."      # TODO: Support wildcards and multiple readers.
        }

        # If the file is compressed, decompress it during the read operation. Can only support streaming compatible compression.
        if ($Path.EndsWith('.gz')) {
            $gzStream = [System.IO.Compression.GzipStream]::new($blobStream, [IO.Compression.CompressionMode]::Decompress, $false)
        }
        else {
            $gzStream = $blobStream
        }

        $reader = [PowerSync.TextFileDataReader]::new($gzStream, $Format, $Header)

        Write-PSYInformationLog -Message "Exported $Format text data from $Container/$Path."

        # Return the reader, as well as some general information about what's being exported. This is to inform the importer
        # of some basic contextual information, which can be used to make decisions on how best to import.
        @{
            DataReaders = @($reader)
            Provider = [PSYDbConnectionProvider]::AzureBlobStorage
            Container = $Container
            Path = $Path
            Format = $Format
            Header = $Header
            OnCompleteInputObject = @{
                Stream = $blobStream
            }
            OnCompleteScriptBlock = {
                if ($Input) {
                    $Input.Stream.Dispose()
                }
            }
        }            
    }
    catch {
        # If we started processing any of the files, clean them up, then log.
        if ($blobStream) {
            $blobStream.Dispose()
        }
        if ($reader) {
            $reader.Dispose()
        }
        try {
            Remove-Item -Path $tempChildFolder -Recurse -ErrorAction SilentlyContinue       # try to clean again, just in case
        }
        catch {}
        Write-PSYErrorLog $_
    }
}