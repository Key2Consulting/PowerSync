<#
.SYNOPSIS
Write to the query log, but never displays the query in the console since queries are too verbose to be useful.

.DESCRIPTION
The query log is used to capture TSQL commands and parameters issued against a database. It is recommended to log prior to query execution since queries can error during execution.

.PARAMETER Name
The name of the Stored Query.

.PARAMETER Connection
The name of the connection the query executed against.

.PARAMETER Query
The TSQL text executed against the database.

.PARAMETER Param
Any parameters passed into the Stored Command.
 #>
function Write-PSYQueryLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $Name,
        [Parameter(Mandatory = $false)]
        [object] $Connection,
        [Parameter(Mandatory = $false)]
        [string] $Query,
        [Parameter(Mandatory = $false)]
        [object] $Param
    )

    try {
        $repo = New-FactoryObject -Repository
        
        # If the passed Connection is a name, load it. Otherwise it's an actual object, so just us it.
        if ($Connection -is [string]) {
            $connectionName = $Connection
        }
        else {
            $connectionName = $Connection.Name
        }

        # Write Log and output to screen
        if ($PSYSession.Initialized) {
            $o = @{
                ID = $null                          # let the repository assign the surrogate key
                Type = 'Query'
                Name = $Name
                Connection = $connectionName
                Query = $Query
                Param = ConvertTo-Json -InputObject $Param -Depth 3 -Compress
                CreatedDateTime = Get-Date | ConvertTo-PSYCompatibleType
            }
            if ($o.Param -and $o.Param.Length -gt 2000) {
                $o.Param = $o.Param.Substring(0, 2000);
            }
            if ($PSYSession.ActivityStack.Count -gt 0) {
                $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1]
            }
            [void] $repo.CreateEntity('QueryLog', $o)
        }
        # Don't output to console since queries can get rather large.
    }
    catch {
        Write-PSYErrorLog $_
    }
}