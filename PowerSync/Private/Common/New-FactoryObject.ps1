function New-FactoryObject {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Repository,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $TypeName
    )

    # Confirm we're connected and initialized
    if (-not $PSYSession -and $PSYSession.Initialized) {
        Write-PSYException "PowerSync is not properly initialized. See Start-PSYMainActivity for more information."
    }

    # Instantial new object based on type
    try {
        if ($Repository) {
            New-Object $PSYSession.RepositoryState.ClassType -ArgumentList $PSYSession.RepositoryState
        }
        elseif ($Connection) {
            if ($TypeName -eq 'SqlServer') {
                return New-Object System.Data.SqlClient.SqlConnection
            }
            elseif ($TypeName -eq 'OleDb') {
                return New-Object System.Data.OleDb.OleDbConnection
            }
            elseif ($TypeName -eq 'ODBC') {
                return New-Object System.Data.Odbc.OdbcConnection
            }
        }
        else {
            throw "Unable to create object from factory, missing switch."
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}
