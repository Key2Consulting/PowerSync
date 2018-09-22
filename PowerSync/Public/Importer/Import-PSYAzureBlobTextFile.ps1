<#
.SYNOPSIS
Imports data into a text file.

.DESCRIPTION
Imports data into a text file defined by the supplied connection. Importers are intended to be paired with Exporters via the pipe command.

The full path to the file is a combination of the base ConnectionString and the Path. Either of those could be omitted, as long as the other supplies the full path.

.PARAMETER Connection
Name of the connection to import into.

.PARAMETER Container
Azure blob storage container.

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
function Import-PSYAzureBlobTextFile {
    param (
        [Parameter(HelpMessage = "Piped data from Exporter (containing data reader and export provider information)", Mandatory = $true, ValueFromPipeline = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "Name of the connection to import into.", Mandatory = $false)]
        [string] $Connection,
        [Parameter(HelpMessage = "Azure blob storage container.", Mandatory = $false)]
        [string] $Container,
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

        # Extract the file name and prepare temp folder.
        $tempFolder = Get-PSYVariable -Name 'PSYTempFolder'
        if (-not $tempFolder) {
            throw "PSYTempFolder environment variable isn't set. A folder to store temporary files is required when using Azure Blob functionality."
        }
        $fileName = Split-Path -Path $Path -Leaf
        $tempChildFolder = Join-Path -Path $tempFolder -ChildPath "$(New-Guid)"
        $downloadedPath = "$tempChildFolder\$fileName"
        New-Item -ItemType Directory -Force -Path (Split-Path -Path $downloadedPath -Parent)

        # Delegate the Import to the existing File Importer.
        $InputObject | Import-PSYTextFile -Path $downloadedPath -Format $Format -Header:$Header -Compress:$Compress

        # Update the file from temp folder to Azure Blob Storage.
        $ctx = New-AzureStorageContext -ConnectionString $connDef.ConnectionString
        Set-AzureStorageBlobContent -File $downloadedPath -Container $Container -Blob $Path -Context $ctx -Force
        Write-PSYInformationLog -Message "Uploaded $Format text data to Blob [$Connection]:$Container/$Path."

        # Removes the temp files.
        Remove-Item -Path $tempChildFolder -Recurse
    }
    catch {
        Remove-Item -Path $tempChildFolder -Recurse -ErrorAction SilentlyContinue       # try to clean again, just in case
        Write-PSYErrorLog $_
    }
    finally {
        # Dispose of all data readers now that import is complete.
        foreach ($reader in $InputObject.DataReaders) {
            $reader.Dispose()
        }
    }
}