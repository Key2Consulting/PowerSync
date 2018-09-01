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
        [Parameter(HelpMessage = "The primary text describing something useful regarding the log.", Mandatory = $true)]
        [string] $Message,
        [Parameter(HelpMessage = "An optional category to help organize different messages.", Mandatory = $false)]
        [string] $Category
    )

    try {
        $repo = New-FactoryObject -Repository       # instantiate repository

        # Write Log and output to screen
        if ($PSYSession.Initialized) {
            [void] $repo.CriticalSection({
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Type = 'Information'
                    Category = $Category
                    Message = $Message
                    CreatedDateTime = Get-Date | ConvertTo-PSYNativeType
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1].ID
                }
                $this.CreateEntity('MessageLog', $o)
            })
        }
        $logCategory = if ($Category) {"($Category) "} else {""}
        Write-Host -Message "Information: $logCategory$Message"
    }
    catch {
        Write-PSYErrorLog $_
    }
}