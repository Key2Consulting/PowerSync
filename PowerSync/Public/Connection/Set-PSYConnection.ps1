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

.EXAMPLE
Set-PSYConnection -Name 'MySource' -Provider SqlServer -ConnectionString 'Server=MyServer;Integrated Security=true;Database=MyDatabase'
#>
function Set-PSYConnection {
    param (
        [Parameter(HelpMessage = "The name of the connection.", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "The provider of the connection (e.g. SQLServer, TextFile, Json, MySql).", Mandatory = $true)]
        [PSYDbConnectionProvider] $Provider,
        [Parameter(HelpMessage = "A Connection String used by the given provider.", Mandatory = $false)]
        [string] $ConnectionString,
        [parameter(HelpMessage = "If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.", Mandatory = $false)]
        [string] $Server,
        [parameter(HelpMessage = "If ConnectionString is omitted, Set-PSYConnection will infer ConnectionString from Server and Database parameters.", Mandatory = $false)]
        [string] $Database,
        [Parameter(HelpMessage = "Additional properties used by the provider. These vary from provider to provider.", Mandatory = $false)]
        [hashtable] $Properties,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [System.Management.Automation.PSCredential] $Credentials
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Log
        Write-PSYVariableLog "Connection.$Name" "Provider = $Provider, ConnectionString = $ConnectionString, Properties = $Properties"

        # If ConnectionString is omitted, attempt to create a default connection string. Can only perform this for databases which support trusted connections.
        if (-not $ConnectionString) {
            if ($Provider -eq [PSYDbConnectionProvider]::SqlServer) {
                $ConnectionString = "Server=$Server;Integrated Security=true;Database=$Database"
            }
            else {
                throw "Unable to infer ConnectionString."
            }
        }

        # Set the in the repository.  If it doesn't exist, it will be created.
        [void] $repo.CriticalSection({
            
            # Determine if existing
            $existing = $this.FindEntity('Connection', 'Name', $Name)
            if ($existing.Count -eq 0) {
                $existing = $null
            }
            else {
                $existing = $existing[0]
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
                $this.CreateEntity('Connection', $o)
                return $o
            }
            else {
                $existing.Provider = $Provider
                $existing.ConnectionString = $ConnectionString
                $existing.Properties = $Properties
                $existing.ModifiedDateTime = Get-Date | ConvertTo-PSYCompatibleType
                return $this.UpdateEntity('Connection', $existing)
            }
        })
    }
    catch {
        Write-PSYErrorLog $_
    }
}