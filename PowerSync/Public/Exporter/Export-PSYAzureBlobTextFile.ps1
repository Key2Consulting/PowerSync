<#
.SYNOPSIS
Exports data from text file stored in Azure Blob storage.

.DESCRIPTION
Exports data from a text file defined by the supplied connection. Exporters are intended to be paired with Importers via the pipe command.

The full path to the file is a combination of the base ConnectionString and the Path. Either of those could be omitted, as long as the other supplies the full path.

Supports Zip archives, and multiple files via wildcards.

.PARAMETER Connection
Name of the connection to extract from.

.PARAMETER Container
Azure blob storage container.

.PARAMETER Path
Path of the file or files to export (supports wildcards). A TextFile connection can supply the root path, which is then prefixed with this path parameter. If path is a Zip archive, will be uncompressed prior to execution.

.PARAMETER Format
The format of the file (CSV, Tab).

.PARAMETER Header
Whether the first row of the text file contains header information.

.PARAMETER Stream
Streams the file from Blob storage, oppose to downloading it by default. Most times, Downloading first is generally faster than Streaming, and is cheaper due to Azure operation transaction costs.
https://stackoverflow.com/questions/13020158/reading-line-by-line-from-blob-storage-in-windows-azure

.EXAMPLE
Export-PSYTextFile -Connection "TestSource" -Path "Sample100.csv" -Format CSV -Header `
| Import-PSYSqlServer -Connection "TestTarget" -Table "dbo.Sample100" -Create -Index -Concurrent

.NOTES
If the file is a compressed as a ZIP file, it will be decompressed prior to the export operation. All files contained within the ZIP archive are exported as a single stream.
 #>
 function Export-PSYAzureBlobTextFile {
    param (
        [Parameter(HelpMessage = "Name of the connection to extract from.", Mandatory = $false)]
        [string] $Connection,
        [Parameter(HelpMessage = "Azure blob storage container.", Mandatory = $false)]
        [string] $Container,
        [Parameter(HelpMessage = "Path of the file or files to export (supports wildcards).", Mandatory = $false)]
        [string] $Path,
        [Parameter(HelpMessage = "The format of the file (CSV, Tab).", Mandatory = $true)]
        [PSYTextFileFormat] $Format,
        [Parameter(HelpMessage = "Whether the first row of the text file contains header information.", Mandatory = $false)]
        [switch] $Header,
        [Parameter(HelpMessage = "Streams the file from Blob storage, oppose to downloading it by default.", Mandatory = $false)]
        [switch] $Stream
    )
    
    try {
        # Initialize source connection
        $connDef = Get-PSYConnection -Name $Connection

        # If not streaming, download from Azure to temp folder, and process from there.
        if (-not $Stream) {
            # Extract the file name and prepare target download folder.
            $tempFolder = Get-PSYVariable -Name 'PSYTempFolder'
            $downloadedPath = Join-Path -Path $tempFolder -ChildPath $Path.Replace('/', '\')
            New-Item -ItemType Directory -Force -Path (Split-Path -Path $downloadedPath -Parent)

            # Download the file from Azure Blob Storage.
            $ctx = New-AzureStorageContext -ConnectionString $connDef.ConnectionString
            Get-AzureStorageBlobContent -Container $Container -Blob $Path -Destination $downloadedPath -Context $ctx -Force
            Write-PSYInformationLog -Message "Downloaded $Format text data from Blob [$Connection]:$Container/$Path."

            # Now that the file is local, delegate the Import to the existing File Importer.
            $r = Export-PSYTextFile -Path $downloadedPath -Format $Format -Header:$Header

            # Add a cleanup routine that removes the temp files. If one already exists, it's from Export-PSYTextFile and we can ignore
            # since our cleanup removes everything.
            $r.OnCompleteInputObject = $downloadedPath
            $r.OnCompleteScriptBlock = {
                Remove-Item -Path $Input
            }
            $r
        }
        else {
            # Otherwise, we're streaming directly from the blob.
            $ctx = New-AzureStorageContext -ConnectionString $connDef.ConnectionString
            $blob = Get-AzureStorageBlob -Container $Container -Blob $Path -Context $ctx
            $blobStream = $blob.ICloudBlob.OpenRead()
            $streamReader = New-Object System.IO.StreamReader $blobStream

            # TODO: Support wildcards and multiple readers.
            $reader = New-Object PowerSync.TextFileDataReader($streamReader, $Format, $Header)
    
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
                    StreamReader = $streamReader
                }
                OnCompleteScriptBlock = {
                    # If we unzipped an archive, clean up uncompressed files
                    if ($Input) {
                        $Input.Stream.Dispose()
                        $Input.StreamReader.Dispose()
                    }
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
    
        Write-PSYErrorLog $_
    }
}