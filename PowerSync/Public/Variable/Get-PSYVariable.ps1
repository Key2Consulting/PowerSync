function Get-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $DefaultValue,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Wildcards,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Extended
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository

        # Get the from the repository.
        return $repo.CriticalSection({
            $existing = $this.FindEntity('Variable', 'Name', $Name, $Wildcards)
            if ($existing.Count -eq 0) {
                Write-PSYVerboseLog -Message "No variable entry found with name '$Name'."
                return $DefaultValue
            }
            elseif (-not $Wildcards -and $existing.Count -gt 1) {
                throw "Multiple variables found with name $Name."
            }
            
            # Flag as read and return
            foreach ($entity in $existing) {
                $entity.ReadDateTime = Get-Date | ConvertTo-PSYNativeType
                $this.UpdateEntity('Variable', $entity)
                # If not showing extended properties, just output the value
                if (-not $Extended) {
                    $entity.Value
                }
                else {
                    # Otherwise, caller wants additional information about the variable (i.e. modified date, ID, etc).
                    $entity
                }
            }
        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error getting variable $Name."
    }
}