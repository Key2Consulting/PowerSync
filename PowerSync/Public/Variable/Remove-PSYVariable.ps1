<#
.SYNOPSIS
Removes or deletes a PowerSync variable from the connected repository, and creates a null entry in the variable log.

.DESCRIPTION
Variables are discrete state managed by PowerSync. The primary benefits of using variables over simple PowerShell variables is that they are persisted and they work with parallel processes.

Variables are simple name/value pairs which are stored in the repository. The value can be a primitive type (e.g. numbers or text), or complex types (e.g. hashtables or array lists).

An important consideration is variable read/write operations are performed as a single atomic unit of work. In other words, there's no way to update just part of a variable when performing concurrent updates.  

Variable access can also be synchronized across parallel processes via Lock-PSYVariable. If that doesn't meet your requirements, look to using Stored Commands instead and creating your own state structures within a database repository.

.PARAMETER Name
Name of the variable. Variable names must be unique.

.PARAMETER Wildcards
Determines whether to use wildcards when searching the variable name. Supports wildcards (i.e. *, ?).

.EXAMPLE
Remove-PSYVariable -Name 'MyVar'

.EXAMPLE
Remove-PSYVariable -Name 'MyList[*]' -Wildcards
#>
function Remove-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "Name of the variable. Variable names must be unique.", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "Determines whether to use wildcards when searching the variable name. Supports wildcards (i.e. *, ?).", Mandatory = $false)]
        [switch] $Wildcards
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository
        
        # Log
        Write-PSYVariableLog "Variable.$Name" $null

        if ($Wildcards) {throw "Remove-PSYVariable Wildcards Not Implemented"}      # can use Get-PSYVariable and delete each one

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
        Write-PSYErrorLog $_ "Error removing variable '$Name'."
    }
}