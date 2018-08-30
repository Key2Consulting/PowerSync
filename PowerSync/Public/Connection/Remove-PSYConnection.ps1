function Remove-PSYConnection {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Log
        Write-PSYVariableLog "Connection.$Name" $null

        # Set the in the repository.  If it doesn't exist, it will be created.
        return $repo.CriticalSection({
            
            # Determine if existing
            $existing = $this.FindEntity('Connection', 'Name', $Name)
            if ($existing.Count -eq 0) {
                return
            }
            else {
                $existing = $existing[0]
            }

            $this.DeleteEntity('Connection', $existing.ID)
        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error removing connection '$Name'."
    }
}