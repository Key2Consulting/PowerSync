<#
.SYNOPSIS
Write to the warning log, and displays in the console.

.DESCRIPTION
The warning log should be used to log significant issues with processing, but which don't necessitate termination.

.PARAMETER Message
The primary text describing something useful regarding the log.

.PARAMETER Category
An optional category to help organize different messages.
 #>
 function Write-PSYWarningLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Message,
        [Parameter(Mandatory = $false)]
        [string] $Category
    )

    try {
        $repo = New-FactoryObject -Repository        

        # Write Log and output to screen    
        if ($PSYSession.Initialized) {
            $o = @{
                ID = $null                          # let the repository assign the surrogate key
                Type = 'Warning'
                Category = $Category
                Message = $Message
                CreatedDateTime = Get-Date | ConvertTo-PSYCompatibleType
            }
            if ($PSYSession.ActivityStack.Count -gt 0) {
                $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1]
            }
            [void] $repo.CreateEntity('MessageLog', $o)
        }
        $logCategory = if ($Category) {"($Category) "} else {""}
        Write-Warning -Message "Warning: $logCategory$Message"
    }
    catch {
        Write-PSYErrorLog $_
    }

}