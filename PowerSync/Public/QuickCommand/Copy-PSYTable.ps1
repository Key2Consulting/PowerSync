<#
.SYNOPSIS
Quick command to copy a table from a source to target. Does not require a repository connection to work, but will use one if exists.

.DESCRIPTION
Copies a table from source to target. Automatically creates the table if doesn't exist. Supports database tables and files sources/targets.

This function makes certain assumptions about the copy operation. If these assumptions don't fit your need, use Export | Import instead.
 - Copies the entirety of the source table.
 - Never copies data in a transactionally consistent manner for performance purposes.
 - Always Overwrites the target table. If the table already exists, will not recreate it.
 - Automatically creates an index on the target table, if possible.
 - Never compresses the target table.
 
Source and Target parameters prefixed with S and T respectively.

.PARAMETER SProvider
The provider of the connection (e.g. SQLServer, TextFile, Json, MySql). Controls what class is instantiated to establish the connection.

.PARAMETER SConnectionString
A Connection String used by the given provider.

.PARAMETER SServer
If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.

.PARAMETER SDatabase
If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.

.PARAMETER SFormat
The format of the file (CSV, Tab).

.PARAMETER SHeader
Whether the first row of the text file contains header information.

.PARAMETER TTable
The table to copy from.

.PARAMETER TProvider
The provider of the connection (e.g. SQLServer, TextFile, Json, MySql). Controls what class is instantiated to establish the connection.

.PARAMETER TConnectionString
A Connection String used by the given provider.

.PARAMETER TServer
If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.

.PARAMETER TDatabase
If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.

.PARAMETER TFormat
The format of the file (CSV, Tab).

.PARAMETER THeader
Whether the first row of the text file contains header information.

.PARAMETER TTable
The table to copy to.

.PARAMETER Compress
Compresses the table or the text file.

.PARAMETER Timeout
Timeout before aborting the copy operation. If no Timeout is specified, uses value of PSYDefaultCommandTimeout environment variable.

.EXAMPLE

#>
function Copy-PSYTable {
    [CmdletBinding()]
    param (
        [parameter(HelpMessage = "The provider of the connection (e.g. SQLServer, TextFile, Json, MySql). Controls what class is instantiated to establish the connection.", Mandatory = $false)]
        [PSYDbConnectionProvider] $SProvider,
        [parameter(HelpMessage = "A Connection String used by the given provider.", Mandatory = $false)]
        [string] $SConnectionString,
        [parameter(HelpMessage = "If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.", Mandatory = $false)]
        [string] $SServer,
        [parameter(HelpMessage = "If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.", Mandatory = $false)]
        [string] $SDatabase,
        [Parameter(HelpMessage = "The format of the file (CSV, Tab).", Mandatory = $false)]
        [PSYTextFileFormat] $SFormat,
        [Parameter(HelpMessage = "Whether the first row of the text file contains header information.", Mandatory = $false)]
        [switch] $SHeader,
        [parameter(HelpMessage = "The table to copy.", Mandatory = $false)]
        [string] $STable,
        [parameter(HelpMessage = "The provider of the connection (e.g. SQLServer, TextFile, Json, MySql). Controls what class is instantiated to establish the connection.", Mandatory = $false)]
        [PSYDbConnectionProvider] $TProvider,
        [parameter(HelpMessage = "A Connection String used by the given provider.", Mandatory = $false)]
        [string] $TConnectionString,
        [parameter(HelpMessage = "If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.", Mandatory = $false)]
        [string] $TServer,
        [parameter(HelpMessage = "If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.", Mandatory = $false)]
        [string] $TDatabase,
        [Parameter(HelpMessage = "The format of the file (CSV, Tab).", Mandatory = $false)]
        [PSYTextFileFormat] $TFormat,
        [Parameter(HelpMessage = "Whether the first row of the text file contains header information.", Mandatory = $false)]
        [switch] $THeader,
        [parameter(HelpMessage = "The table to copy to.", Mandatory = $false)]
        [string] $TTable,
        [parameter(HelpMessage = "Compresses the table or the text file.", Mandatory = $false)]
        [switch] $TCompress,
        [Parameter(HelpMessage = "Timeout before aborting the copy operation.", Mandatory = $false)]
        [int] $Timeout
    )

    try {
        # If we're not already connected, use a local JSON repository
        if (-not $PSYSession.Initialized) {
            Remove-PSYJsonRepository -Path 'TempRepository.json'            # remove if already exists
            New-PSYJsonRepository -Path 'TempRepository.json'
            Connect-PSYJsonRepository -Path 'TempRepository.json'
        }

        # Register source and target connections
        Set-PSYConnection -Name 'Source' -Provider $SProvider -ConnectionString $SConnectionString -Server $SServer -Database $SDatabase
        Set-PSYConnection -Name 'Target' -Provider $TProvider -ConnectionString $TConnectionString -Server $TServer -Database $TDatabase
        
        # Names of source and target providers
        $sProviderName = [Enum]::GetName([PSYDbConnectionProvider], $SProvider)
        $tProviderName = [Enum]::GetName([PSYDbConnectionProvider], $TProvider)

        # Process the work items
        Start-PSYActivity -Name "Copying table $SServer.$SDatabase.$STable to $TServer.$TDatabase.$TTable." -ScriptBlock {

            $autoCreate = $true
            $autoIndex = $true

            # Export Data (depending on source provider)
            if ($SProvider -eq [PSYDbConnectionProvider]::SqlServer) {
                $exportedData = Export-PSYSqlServer -Connection 'Source' -Table $STable -Timeout $Timeout
            }
            elseif ($SProvider -eq [PSYDbConnectionProvider]::OleDb) {
                $exportedData = Export-PSYOleDbServer -Connection 'Source' -Table $STable -Timeout $Timeout
            }
            elseif ($SProvider -eq [PSYDbConnectionProvider]::TextFile) {
                $autoIndex = $false         # can't auto index in this case as text files produce incompatible types
                $exportedData = Export-PSYTextFile -Connection 'Source' -Path '' -Header:$SHeader -Format $SFormat     # assumes connection includes the file path
            }

            # Import Data (depending on target provider)
            if ($TProvider -eq [PSYDbConnectionProvider]::SqlServer) {
                $autoCreate = -not (Invoke-PSYCmd -Connection 'Target' -Name "$tProviderName.CheckIfTableExists" -Param @{Table = $TTable}).TableExists
                $exportedData | Import-PSYSqlServer -Connection 'Target' -Table $TTable -Timeout $Timeout -Create:$autoCreate -Index:$autoIndex -Overwrite -Compress:$TCompress
            }
            elseif ($TProvider -eq [PSYDbConnectionProvider]::OleDb) {
                $autoCreate = -not (Invoke-PSYCmd -Connection 'Target' -Name "$tProviderName.CheckIfTableExists" -Param @{Table = $TTable}).TableExists
                $exportedData | Import-PSYOleDbServer -Connection 'Target' -Table $TTable -Timeout $Timeout -Create:$autoCreate -Index:$autoIndex -Overwrite -Compress:$TCompress
            }
            elseif ($TProvider -eq [PSYDbConnectionProvider]::TextFile) {
                $exportedData | Import-PSYTextFile -Connection 'Target' -Path '' -Header:$THeader -Format $TFormat -Compress:$TCompress     # assumes connection includes the file path
            }
        }
    }
    catch {
        Write-PSYErrorLog $_ "Error in Copy-PSYTable."
    }
}