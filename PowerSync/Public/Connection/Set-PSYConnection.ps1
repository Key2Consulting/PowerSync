<#
.SYNOPSIS
Sets (or creates) a PowerSync connection in the connected repository.

.DESCRIPTION
Connections define all of the required information required to establish a connection to a source or target system. All importers/exporters require connections to perform their work. The specific properties required depend on the provider of a connection, but most providers support a Connection String.

.PARAMETER Name
The name of the connection.

.PARAMETER Provider
The provider of the connection (e.g. SQLServer, TextFile, Json, MySql). Controls what class is instantiated to establish the connection.

.PARAMETER ConnectionString
A Connection String used by the given provider.

.PARAMETER Server
If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.

.PARAMETER Database
If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.

.PARAMETER Properties
Additional properties used by the provider. These vary from provider to provider. See online examples for more information.

.PARAMETER Credentials
The credentials to use when establishing the connection. If no credentials are defined, the credentials of the current user are used.

.PARAMETER AsObject
A connection object is created and returned, without saving to the repository.

.EXAMPLE
Set-PSYConnection -Name 'MySource' -Provider SqlServer -ConnectionString 'Server=MyServer;Integrated Security=true;Database=MyDatabase'
#>
function Set-PSYConnection {
    param (
        [Parameter(Mandatory = $false)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [PSYDbConnectionProvider] $Provider,
        [Parameter(Mandatory = $false)]
        [string] $ConnectionString,
        [parameter(Mandatory = $false)]
        [string] $Server,
        [parameter(Mandatory = $false)]
        [string] $Database,
        [Parameter(Mandatory = $false)]
        [hashtable] $Properties,
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credentials,
        [Parameter(Mandatory = $false)]
        [switch] $AsObject
    )

    try {
        $repo = New-FactoryObject -Repository
        
        if (-not $AsObject) {
            # Log
            Write-PSYVariableLog "Connection.$Name" "Provider = $Provider, ConnectionString = $ConnectionString, Properties = $Properties"
        }

        # If ConnectionString is omitted, attempt to create a default connection string. Can only perform this for databases which support trusted connections.
        if (-not $ConnectionString) {
            if ($Provider -eq [PSYDbConnectionProvider]::SqlServer) {
                $ConnectionString = "Server=$Server;Integrated Security=true;Database=$Database"
            }
            else {
                throw "Unable to infer ConnectionString."
            }
        }

        # Determine if existing
        if (-not $AsObject) {
            $existing = $repo.FindEntity('Connection', 'Name', $Name)
            if ($existing.Count -eq 0) {
                $existing = $null
            }
            else {
                $existing = $existing[0]
            }
        }

        # If not exists then create, otherwise update.
        if (-not $existing) {
            $o = @{
                ID = $null                          # let the repository assign the surrogate key
                Name = $Name
                Provider = $Provider
                ConnectionString = $ConnectionString
                Properties = $Properties
                CreatedDateTime = Get-Date | ConvertTo-PSYCompatibleType
                ModifiedDateTime = Get-Date | ConvertTo-PSYCompatibleType
            }
            [void] $repo.CreateEntity('Connection', $o)
        }
        else {
            $existing.Provider = $Provider
            $existing.ConnectionString = $ConnectionString
            $existing.Properties = $Properties
            $existing.ModifiedDateTime = Get-Date | ConvertTo-PSYCompatibleType
            [void] $repo.UpdateEntity('Connection', $existing)
        }

        # If an object was requested, return it.
        if ($AsObject) {
            if (-not $o.Name) {     # if we don't have a name, make up something unique to correlate with logging
                $o.Name = (New-Guid).ToString()
            }
            $o
        }        
    }
    catch {
        Write-PSYErrorLog $_
    }
}