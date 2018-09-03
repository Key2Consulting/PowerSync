function Remove-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Log
        Write-PSYVariableLog "Variable.$Name" $null

        # Set the in the repository.  If it doesn't exist, it will be created.
        return $repo.CriticalSection({
            
            # Determine if existing
            $existing = $this.FindEntity('Variable', 'Name', $Name)
            if ($existing.Count -eq 0) {
                return
            }
            else {
                $existing = $existing[0]
            }

            $this.DeleteEntity('Variable', $existing.ID)
        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error removing variable '$Name'."
    }
}