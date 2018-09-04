<#
.SYNOPSIS
Imports data into a text file.

.DESCRIPTION
Imports data into a text file defined by the supplied connection. Importers are intended to be paired with Exporters via the pipe command.

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
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Format,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Header
    )

    try {
        
    }
    catch {
        Write-PSYErrorLog $_ "Error in Import-PSYTextFile."
    }
}