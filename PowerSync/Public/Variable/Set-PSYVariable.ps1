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
        
        Write-PSYVariableLog $Name $Value       # log
        
        # Set the state in the repository.  If it doesn't exist, it will be created if Overwrite is set.
        return $repo.CriticalSection({
            
            # Determine if an existing variable
            $existing = $null
            if ($Name) {            # either name was used
                $existing = $this.FindEntity('Variable', 'Name', $Name)
                if ($existing.Count -gt 0) {
                    throw "Multiple variables found with name $Name."
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
                    $existing = $this.ReadEntity('Variable', $Name)
                }
                else {
                    throw "Incorrect variable specified for Set-PSYVariable: $($Variable.ToString())"
                }
            }
            else {
                throw "Unknown variable in Set-PSYVariable. Either Name or Variable parameter must be set."
            }
            
            # If not exists then create, otherwise update.
            if (-not $existing) {
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Name = $Name
                    Value = $Value
                    UserType = $UserType
                    CreatedDateTime = Get-Date
                    ModifiedDateTime = Get-Date
                    ReadDateTime = Get-Date
                }
                $this.CreateEntity('Variable', $o)
                return $o
            }
            elseif ($Overwrite) {
                $existing.Value = $Value
                $existing.ModifiedDateTime = Get-Date
                return $this.UpdateEntity('Variable', $existing)
            }
            else {
                throw "Variable $($Variable.ToString()) already exists, with no Overwrite switch set."
            }
        })
    }
    catch {
        Write-PSYExceptionLog $_ "Error setting variable '$Name'."
    }
}