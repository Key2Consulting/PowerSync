function Export-PSYSqlServer {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $ExtractQuery,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Table,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Timeout
    )

    try {
        # Initialize source connection
        $connDef = Get-PSYConnection -Name $Connection
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
        $cmd.CommandTimeout = (Get-PSYVariable 'PSYDefaultCommandTimeout')
        $reader = $cmd.ExecuteReader()

        # Log
        if ($Table) {
            Write-PSYInformationLog -Message "Exported $providerName data from [$Connection]:$Table"
        }
        else {
            $extractSnippet = $ExtractQuery
            if ($extractSnippet.Length -gt 100) {
                $extractSnippet = $extractSnippet.SubString(0,100)
            }
            Write-PSYInformationLog -Message "Exported $providerName data from [$Connection]:$extractSnippet"
        }

        # Return the reader, as well as some general information about what's being exported. This is to inform the importer
        # of some basic contextual information, which can be used to make decisions on how best to import.
        @{
            DataReader = $reader
            Provider = [PSYDbConnectionProvider]::SqlServer
        }
    }
    catch {
        Write-PSYErrorLog $_ "Error in Export-PSYSqlServer."
    }
}