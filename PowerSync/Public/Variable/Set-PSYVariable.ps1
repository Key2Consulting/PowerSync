function Set-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Value,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Parent,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Variable,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $UserType,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Overwrite
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository
        
        # Log the variable state change. If the variable entity was passed, extract the Name/Value from it.     TODO: log Name and ID properties
        $logVarName = $null
        if ($Variable) {
            if (-not $Variable.Name) {
                $logVarName = $Variable.ID
                Write-PSYVariableLog $logVarName $Variable.Value       # variables without names are typically list items      TODO: Add parent name?
            }
            else {
                $logVarName = $Variable.Name
                Write-PSYVariableLog $Variable.Name $Variable.Value
            }
        }
        else {
            # Just because a variable wasn't passed, doesn't mean we have a Name parameter, as is the case
            # when adding items to a list (i.e. added by index).
            if ($Name) {
                $logVarName = $Name
                Write-PSYVariableLog $logVarName $Value
            }
            else {
                $logVarName = "ParentID $($Parent.ID)"
                Write-PSYVariableLog $logVarName $Value
            }
        }

        # Set the state in the repository.  If it doesn't exist, it will be created if Overwrite is set.
        return $repo.CriticalSection({
            
            # Determine if an existing variable
            $existing = $null
            if ($Name) {            # either name was used
                $existing = $this.FindEntity('Variable', 'Name', $Name)
                if ($existing.Count -gt 0) {
                    throw "Multiple variables found with name '$logVarName'."
                }
                elseif ($existing.Count -eq 1) {
                    $existing = $existing[0]
                }
                else {
                    $existing = $null
                }
            }
            elseif ($Variable) {    # or actual variable entity
                # If variable is a hashtable, check if it has an ID column
                if ($Variable.ContainsKey('ID')) {
                    $existing = $this.ReadEntity('Variable', $Variable.ID)
                }
                else {
                    throw "Incorrect variable specified for Set-PSYVariable: '$logVarName'."
                }
            }
            elseif (-not $Parent) {
                throw "Unknown variable in Set-PSYVariable for '$logVarName'. Either Name, Variable, or Parent parameters must be set."
            }
            
            # If not exists then create, otherwise update.
            if (-not $existing) {
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    ParentID = $null
                    Name = $Name
                    Value = $Value
                    UserType = $UserType
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                    ModifiedDateTime = Get-Date | ConvertTo-PSYNativeType
                    ReadDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if ($Parent) {
                    $o.ParentID = $Parent.ID
                }
                $this.CreateEntity('Variable', $o)
                return $o
            }
            elseif ($Overwrite) {
                # If a variable entity was passed in, use it instead of the one we just read.
                if ($Variable) {
                    $existing = $Variable
                }
                # If a value wasn't explicit passed, assume the caller already updated Value field on the entity itself.
                if ($PSBoundParameters.ContainsKey('Value')) {
                    $existing.Value = $Value
                }
                $existing.ModifiedDateTime = Get-Date | ConvertTo-PSYNativeType
                return $this.UpdateEntity('Variable', $existing)
            }
            else {
                throw "Variable '$logVarName' already exists, with no Overwrite switch set."
            }
        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error setting variable '$logVarName'."
    }
}