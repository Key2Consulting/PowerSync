function Get-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $ID
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository

        # Get the state from the repository.
        return $repo.CriticalSection({            
            # Determine if an existing variable
            $existing = $null
            if ($Name) {            # either name was used
                $existing = $this.FindEntity('Variable', 'Name', $Name)
                if ($existing.Count -eq 1) {
                    $existing = $existing[0]
                }
                elseif ($existing.Count -gt 1) {
                    throw "Multiple variables found with name $Name."
                }
                else {
                    $existing = $null
                }
            }
            elseif ($ID) {    # or the ID
                # If variable is a hashtable, check if it has an ID column
                $existing = $this.ReadEntity('Variable', $ID)
            }
            else {
                throw "Unknown variable in Set-PSYVariable. Either Name or ID parameter must be set."
            }

            if (-not $existing) {
                throw "Variable $Name$ID not found."
            }

            # Check if this variable has children
            $children = $this.FindEntity('Variable', 'ParentID', $existing.ID)
            if ($children.Count -gt 0) {
                $existing.Children = New-Object System.Collections.ArrayList
                foreach ($child in $children) {
                    [void] $existing.Children.Add($child)
                }
            }

            # Flag as read and return
            $existing.ReadDateTime = Get-Date | ConvertTo-PSYNativeType
            $this.UpdateEntity('Variable', $existing)
            return $existing
        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error getting variable $Name$ID."
    }
}