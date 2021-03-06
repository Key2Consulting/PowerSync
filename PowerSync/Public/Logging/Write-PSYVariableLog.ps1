<#
.SYNOPSIS
Write to the variable log, and displays in the console if -Debug is set.

.DESCRIPTION
The variable log is used to capture state changes for all variables managed by PowerSync.

.PARAMETER Name
The variable name.

.PARAMETER Value
The new value of the variable.
 #>
 function Write-PSYVariableLog {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $false)]
        [object] $Value
    )

    try {
        $repo = New-FactoryObject -Repository
        
        # Write Log and output to screen
        if ($PSYSession.Initialized) {
            $logValue = ConvertTo-Json -InputObject $Value -Compress
            if ($logValue) {
                $logValue = $Value
            }
            $o = @{
                ID = $null                          # let the repository assign the surrogate key
                Type = 'Variable'
                Name = $Name
                Value = $logValue
                CreatedDateTime = Get-Date | ConvertTo-PSYCompatibleType
            }
            if ($PSYSession.ActivityStack.Count -gt 0) {
                $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1]
            }
            [void] $repo.CreateEntity('VariableLog', $o)
        }
        Write-Debug -Message "Variable: $Name = $Value"
    }
    catch {
        Write-PSYErrorLog $_
    }
}