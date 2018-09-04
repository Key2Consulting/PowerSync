function Set-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Value,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $UserType

    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Set the in the repository.  If it doesn't exist, it will be created.
        [void] $repo.CriticalSection({
            
            # Determine if existing
            $existing = $this.FindEntity('Variable', 'Name', $Name)
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
                    Value = $Value
                    UserType = $UserType
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                    ModifiedDateTime = Get-Date | ConvertTo-PSYNativeType
                    ReadDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                $this.CreateEntity('Variable', $o)
                return $o
            }
            else {
                $existing.Value = $Value
                $existing.ModifiedDateTime = Get-Date | ConvertTo-PSYNativeType
                return $this.UpdateEntity('Variable', $existing)
            }
        })

        # Log
        Write-PSYVariableLog $Name $Value
    }
    catch {
        Write-PSYErrorLog $_ "Error setting variable '$Name'."
    }
}