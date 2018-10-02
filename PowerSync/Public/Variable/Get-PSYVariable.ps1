<#
.SYNOPSIS
Gets one or more PowerSync variables from the connected repository, and updates its ReadDateTime property. By default, only the value is returned even though internally variables have more state associated to the entry.

.DESCRIPTION
State Variables are discrete state managed by PowerSync. The primary benefits of using PowerSync State Variables over native PowerShell variables is that they are persisted and they work with parallel processes.

State Variables are simple name/value pairs which are stored in the repository. The value can be a primitive type (e.g. numbers or text), or complex types (e.g. hashtables or array lists).

An important consideration is variable read/write operations are performed as a single atomic unit of work. In other words, there's no way to update just part of a variable when performing concurrent updates.  

Variable access can also be synchronized across parallel processes via Lock-PSYVariable. If that doesn't meet your requirements, look to using Stored Commands instead and creating your own state structures within a database repository.

.PARAMETER Name
Name of the variable. Variable names must be unique.

.PARAMETER DefaultValue
If the variable is not found, the default value is returned.

.PARAMETER Wildcards
Determines whether to use wildcards when searching the variable name. Supports wildcards (i.e. *, ?).

.PARAMETER Extended
Returns all known information about a variable as a hashtable.

.EXAMPLE
$x = (Get-PSYVariable -Name 'MyVar') + 1

.EXAMPLE
Get-PSYVariable -Name 'MyVar' -DefaultValue 500

.EXAMPLE
foreach ($var in (Get-PSYVariable -Name 'Table[?]')) {
    Write-PSYHost $var.Name
}

.NOTES
See https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/string-wildcard-syntax for information on wildcards.
#>
function Get-PSYVariable {
    param
    (
        [Parameter(Mandatory = $false)]
        [string] $Name,
        [Parameter(Mandatory = $false)]
        [object] $DefaultValue,
        [Parameter(Mandatory = $false)]
        [switch] $Wildcards,
        [Parameter(Mandatory = $false)]
        [switch] $Extended
    )

    try {
        $repo = New-FactoryObject -Repository

        # Get the from the repository.
        $existing = $repo.FindEntity('Variable', 'Name', $Name, $Wildcards)
        if ($existing.Count -eq 0) {
            Write-PSYVerboseLog -Message "No variable entry found with name '$Name'."
            return $DefaultValue
        }
        elseif (-not $Wildcards -and $existing.Count -gt 1) {
            throw "Multiple variables found with name $Name."
        }
        
        # Flag as read and return
        foreach ($entity in $existing) {
            $entity.ReadDateTime = Get-Date | ConvertTo-PSYCompatibleType
            $repo.UpdateEntity('Variable', $entity)
            # If not showing extended properties, just output the value
            if (-not $Extended) {
                $entity.Value
            }
            else {
                # Otherwise, caller wants additional information about the variable (i.e. modified date, ID, etc).
                $entity
            }
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}