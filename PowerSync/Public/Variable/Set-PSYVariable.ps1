<#
.SYNOPSIS
Sets (or creates) a PowerSync variable in the connected repository, and creates an entry in the variable log.

.DESCRIPTION
Variables are discrete state managed by PowerSync. The primary benefits of using variables over simple PowerShell variables is that they are persisted and they work with parallel processes.

Variables are simple name/value pairs which are stored in the repository. The value can be a primitive type (e.g. numbers or text), or complex types (e.g. hashtables or arrays).

An important consideration is variable read/write operations are performed as a single atomic unit of work. In other words, there's no way to update just part of a variable when performing concurrent updates.  

Variable access can also be synchronized across parallel processes via Lock-PSYVariable. If that doesn't meet your requirements, look to using Stored Commands instead and creating your own state structures within a database repository.

.PARAMETER Name
Name of the variable. Variable names must be unique.

.PARAMETER Value
The value assigned to the variable. Support primitive or complex types as long as they support PowerShell serialization.

.PARAMETER Category
An optional and custom name given by the user describing the type of this variable. Can be used to control the physical storage location in a database repository, or as additional metadata.

.EXAMPLE
Set-PSYVariable -Name 'MyVar' -Value 'Hello World'

.EXAMPLE
Set-PSYVariable -Name 'MyVar' -Value @{Prop1 = 123; Prop2 = 456}

.NOTES
The benefits of variables is process synchronization and logging. If you require a multi-row variable, consider creating multiple variables with a name differing by an index and using wildcards. 
For example:
    Set-PSYVariable -Name 'MyVar[0]' -Value 'Blue'
    Set-PSYVariable -Name 'MyVar[1]' -Value 'Red'
    Set-PSYVariable -Name 'MyVar[2]' -Value 'Green'
    foreach ($var in (Get-PSYVariable -Name 'MyVar[*]' -Wildcards)) {
        Write-PSYHost "Color is $($var)"
    }
    Remove-PSYVariable -Name 'MyVar[*]' -Wildcards
#>
function Set-PSYVariable {
    param
    (
        [Parameter(Mandatory = $false)]
        [string] $Name,
        [Parameter(Mandatory = $false)]
        [object] $Value,
        [Parameter(Mandatory = $false)]
        [string] $Category
    )

    try {
        $repo = New-FactoryObject -Repository
        
        # Determine if existing
        $existing = $repo.FindEntity('Variable', 'Name', $Name)
        if ($existing.Count -eq 0) {
            $existing = $null
        }
        else {
            $existing = $existing[0]
        }

        # If not exists then create, otherwise update.
        if (-not $existing) {
            $o = @{
                ID = $null                          # let the repository assign the surrogate key
                Name = $Name
                Value = $Value
                Category = $Category
                CreatedDateTime = Get-Date | ConvertTo-PSYCompatibleType
                ModifiedDateTime = Get-Date | ConvertTo-PSYCompatibleType
                ReadDateTime = Get-Date | ConvertTo-PSYCompatibleType
            }
            $repo.CreateEntity('Variable', $o)
        }
        else {
            $existing.Value = $Value
            $existing.ModifiedDateTime = Get-Date | ConvertTo-PSYCompatibleType
            return $repo.UpdateEntity('Variable', $existing)
        }

        # Log
        Write-PSYVariableLog -Name $Name -Value $Value
    }
    catch {
        Write-PSYErrorLog $_
    }
}