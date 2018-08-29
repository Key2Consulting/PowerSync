function Set-PSYFileConnection {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $RootPath,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $AdditionalProperties,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [SecureString] $Credentials
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository
        
        # Log
        Write-PSYVariableLog "Connection.$Name" "Provider = $Provider, ConnectionString = $ConnectionString, AdditionalProperties = $AdditionalProperties"

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
                    ConnectionString = $RootPath
                    AdditionalProperties = $AdditionalProperties
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                    ModifiedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                $this.CreateEntity('Connection', $o)
                return $o
            }
            else {
                $existing.ConnectionString = $RootPath
                $existing.AdditionalProperties = $AdditionalProperties
                $existing.ModifiedDateTime = Get-Date | ConvertTo-PSYNativeType
                return $this.UpdateEntity('Connection', $existing)
            }
        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error setting connection '$Name'."
    }
}