<#
.SYNOPSIS
Exports data from Sql Server database.

.DESCRIPTION
Exports data from Sql Server database defined by the supplied connection and extract query (or table). Exporters are intended to be paired with Importers via the pipe command.

.PARAMETER Connection
Name of the connection to extract from.

.PARAMETER ExtractQuery
Query which extracts data from the database. Can use Stored Commands (i.e. Resolve-PSYCmd) to supply this parameter. Table parameter is ignored if ExtractQuery is specified.

.PARAMETER Table
The table to extract against. Not used if ExtractQuery is specified.

.PARAMETER Timeout
The command timeout used when executing the extract query. If no Timeout is specified, uses value of PSYDefaultCommandTimeout environment variable.

.EXAMPLE
Export-PSYSqlServer -Connection "TestSource" -Table "MySchema.MyTable" `
| Import-PSYSqlServer -Connection "TestTarget" -Table "MySchema.MyTable" -Create -Index

.EXAMPLE
Export-PSYSqlServer -Connection "TestSource" -ExtractQuery "SELECT * FROM MySchema.MyTable WHERE Category = '$category'" `
| Import-PSYSqlServer -Connection "TestTarget" -Table "MySchema.MyTable" -Consistent

.NOTES
Exporters return a hashtable of two distinct variables:
 - DataReader: A IDataReader compliant interface for reading the exported data.
 - Provider: The provider used for the export to inform downstream importers of where the data originated.
 #>
function Export-PSYSqlServer {
    param (
        [Parameter(Mandatory = $true)]
        [object] $Connection,
        [Parameter(Mandatory = $false)]
        [string] $ExtractQuery,
        [Parameter(Mandatory = $false)]
        [string] $Table,
        [Parameter(Mandatory = $false)]
        [int] $Timeout
    )

    try {
        # If the passed Connection is a name, load it. Otherwise it's an actual object, so just us it.
        if ($Connection -is [string]) {
            $connDef = Get-PSYConnection -Name $Connection
        }
        else {
            $connDef = $Connection
        }

        # Initialize source connection
        $providerName = [Enum]::GetName([PSYDbConnectionProvider], $connDef.Provider)
        $conn = New-FactoryObject -Connection -TypeName $providerName

        # Prepare query
        if (-not $ExtractQuery) {
            $ExtractQuery = "SELECT * FROM $Table"
        }

        # Execute query
        $conn.ConnectionString = $connDef.ConnectionString
        $conn.Open()
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $ExtractQuery
        $cmd.CommandTimeout = Select-Coalesce @(($Timeout), (Get-PSYVariable 'PSYDefaultCommandTimeout'))
        $readers = [System.Collections.ArrayList]::new()
        $readers.Add($cmd.ExecuteReader())
        
        # Log
        if ($Table) {
            Write-PSYInformationLog -Message "Exported $providerName data from [$($connDef.Name)]:$Table"
        }
        else {
            $extractSnippet = $ExtractQuery
            if ($extractSnippet.Length -gt 100) {
                $extractSnippet = $extractSnippet.SubString(0,100)
            }
            Write-PSYInformationLog -Message "Exported $providerName data from [$($connDef.Name)]:$extractSnippet"
        }

        # Return the reader, as well as some general information about what's being exported. This is to inform the importer
        # of some basic contextual information, which can be used to make decisions on how best to import.
        @{
            DataReaders = $readers
            Provider = [PSYDbConnectionProvider]::SqlServer
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}