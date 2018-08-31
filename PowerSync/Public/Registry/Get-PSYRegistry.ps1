function Get-PSYRegistry {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $DefaultValue
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository

        # Get the from the repository.
        return $repo.CriticalSection({            
            $existing = $this.FindEntity('Registry', 'Name', $Name)
            if ($existing.Count -eq 0) {
                Write-PSYVerboseLog -Message "No registry entry found with name '$Name'."
                return $DefaultValue
            }
            else {
                return $existing[0].Value
            }

        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error getting registry $Name."
    }
}