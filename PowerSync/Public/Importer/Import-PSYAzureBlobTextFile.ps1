<#
.SYNOPSIS
Imports data into a text file, with optional compression.

.DESCRIPTION
Imports data into a text file defined by the supplied connection. Importers are intended to be paired with Exporters via the pipe command.

The full path to the file is a combination of the base ConnectionString and the Path. Either of those could be omitted, as long as the other supplies the full path.

If the file extension .gz is used, the file will be compressed using Gzip compression.

.PARAMETER Connection
Name of the connection to import into.

.PARAMETER Container
Azure blob storage container.

.PARAMETER Path
Path of the file to import. A TextFile connection can supply the root path, which is then prefixed with this path parameter.

If the file extension .gz is used, the file will be compressed using Gzip compression.

.PARAMETER Format
The format of the file (CSV, Tab).

.PARAMETER Header
Whether the first row of the text file contains header information.

.EXAMPLE
Export-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Sample10000.csv" -Format CSV -Header `
| Import-PSYAzureBlobTextFile -Connection "TestAzureBlob" -Container 'data' -Path "Temp/AzureDownloadSample10000.gz" -Format CSV -Header

 #>
function Import-PSYAzureBlobTextFile {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(Mandatory = $false)]
        [string] $Connection,
        [Parameter(Mandatory = $false)]
        [string] $Container,
        [Parameter(Mandatory = $false)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [PSYTextFileFormat] $Format,
        [Parameter(Mandatory = $false)]
        [switch] $Header
    )

    try {
        # Initialize source connection
        $connDef = Get-PSYConnection -Name $Connection

        # Create the Blob
        $ctx = New-AzureStorageContext -ConnectionString $connDef.ConnectionString
        $c = Get-AzureStorageContainer -Name $Container -Context $ctx
        $blob = $c.CloudBlobContainer.GetBlockBlobReference($Path)
        $blobStream = $blob.OpenWrite()

        if ($Path.Contains('*') -or $Path.Contains('?')) {
            throw "Wildcards not implemented."      # TODO: Support wildcards and multiple readers.
        }

        # If we're compressing
        if ($Path.EndsWith('.gz')) {
            $gzStream = [System.IO.Compression.GzipStream]::new($blobStream, [IO.Compression.CompressionMode]::Compress, $false)
        }
        else {
            $gzStream = $blobStream
        }

        # Write the file
        $writer = [PowerSync.TextFileDataWriter]::new($gzStream, $Format, $Header)
        $writer.Write($InputObject.DataReaders[0])
        Write-PSYInformationLog -Message "Uploaded $Format text data to Blob [$Connection]:$Container/$Path."
    }
    catch {
        Write-PSYErrorLog $_
    }
    finally {
        # Dispose of all data readers now that import is complete.
        foreach ($reader in $InputObject.DataReaders) {
            $reader.Dispose()
        }
    }
}