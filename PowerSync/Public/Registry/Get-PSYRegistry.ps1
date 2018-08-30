function Get-PSYRegistry {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository

        # Get the from the repository.
        return $repo.CriticalSection({            
            $existing = $this.FindEntity('Registry', 'Name', $Name)
            if ($existing.Count -eq 0) {
                throw "No registry entry found with name '$Name'."
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