<#
.SYNOPSIS
Write to the message log, and displays in the console.

.DESCRIPTION
The information log should be to narrate the work being performed at a high level.

.PARAMETER Message
The primary text describing something useful regarding the log.

.PARAMETER Category
An optional category to help organize different messages.
#>
function Write-PSYInformationLog {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName='Pipe')]
            [object] $InputObject,
        [Parameter(Mandatory = $true, ParameterSetName='Explicit', Position=0)]
            [string] $Message,
        [Parameter(Mandatory = $false, ParameterSetName='Explicit', Position=1)]
            [string] $Category
    )

    try {
        $repo = New-FactoryObject -Repository

        # Write Log and output to screen
        if ($PSYSession.Initialized) {
            $o = @{
                ID = $null                          # let the repository assign the surrogate key
                Type = 'Information'
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
        Write-PSYHost "Information: $logCategory$Message"           # print to console
        Write-Information "Information: $logCategory$Message"       # needed when executing parallel or unattended
    }
    catch {
        Write-PSYErrorLog $_
    }
}