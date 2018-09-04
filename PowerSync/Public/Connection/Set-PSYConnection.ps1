<#
.SYNOPSIS
Sets (or creates) a PowerSync connection.

.DESCRIPTION
Connections define all of the required information required to establish a connection to a source or target system. All importers/exporters require connections
to perform their work. The specific properties required depend on the provider of a connection, but most providers support a Connection String.

.PARAMETER Name
The name of the connection.

.PARAMETER Provider
The provider of the connection (e.g. SQLServer, TextFile, Json, MySql). Controls what class is instantiated to establish the connection.

.PARAMETER ConnectionString
A Connection String used by the given provider.

.PARAMETER Properties
Additional properties used by the provider. These vary from provider to provider. See online examples for more information.

.PARAMETER Credentials
The credentials to use when establishing the connection. If no credentials are defined, the credentials of the current user are used.

.EXAMPLE
Invoke-PSYCmd -Connection 'MyConnection' -Name "PublishMyDataSets" -Param @{ProcessingMode = 'Full'; AllowNulls = $true}

.NOTES
 - This function will recursively search for files matching the Name parameter within all folders defined by the PSYCmdPath variable. 
 - The following example sets the path: Set-PSYVariable -Name 'PSYCmdPath' -Value $PSScriptRoot
 - It's recommended to set the path to your root project folder so that any Stored Command is recursively found.
#>
function Set-PSYConnection {
    param
    (
        [Parameter(HelpMessage = "The name of the connection.", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "The provider of the connection (e.g. SQLServer, TextFile, Json, MySql).", Mandatory = $true)]
        [PSYDbConnectionProvider] $Provider,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $ConnectionString,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [hashtable] $Properties,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [SecureString] $Credentials
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Log
        Write-PSYVariableLog "Connection.$Name" "Provider = $Provider, ConnectionString = $ConnectionString, Properties = $Properties"

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
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                    ModifiedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                $this.CreateEntity('Connection', $o)
                return $o
            }
            else {
                $existing.Provider = $Provider
                $existing.ConnectionString = $ConnectionString
                $existing.Properties = $Properties
                $existing.ModifiedDateTime = Get-Date | ConvertTo-PSYNativeType
                return $this.UpdateEntity('Connection', $existing)
            }
        })
    }
    catch {
        Write-PSYErrorLog $_ "Error setting connection '$Name'."
    }
}