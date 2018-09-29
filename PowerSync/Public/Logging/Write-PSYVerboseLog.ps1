<#
.SYNOPSIS
Write to the message log, and displays in the console if -Verbose is set.

.DESCRIPTION
Similar to the information log, the verbose log should narrate the work being performed, but at a more detailed level. The verbose log provides an extra level of detail the information log does not.

.PARAMETER Message
The primary text describing something useful regarding the log.

.PARAMETER Category
An optional category to help organize different messages.
#>
function Write-PSYVerboseLog {
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
                    Type = 'Verbose'
                    Category = $Category
                    Message = $Message
                    CreatedDateTime = Get-Date | ConvertTo-PSYCompatibleType
                }
                if ($PSYSession.ActivityStack.Count -gt 0) {
                    $o.ActivityID = $PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1]
                }
                $this.CreateEntity('MessageLog', $o)
            })
        }
        $logCategory = if ($Category) {"($Category) "} else {""}
        Write-Verbose -Message "Verbose: $logCategory$Message"
    }
    catch {
        Write-PSYErrorLog $_
    }
}