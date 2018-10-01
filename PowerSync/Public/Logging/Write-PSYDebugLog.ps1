<#
.SYNOPSIS
Write to the debug log, and displays in the console if -Debug is set.

.DESCRIPTION
The debug log should be used to log technical operations internal to the system, and useful for debugging purposes.

.PARAMETER Message
The primary text describing something useful regarding the log.

.PARAMETER Category
An optional category to help organize different messages.
 #>
function Write-PSYDebugLog {
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "The primary text describing something useful regarding the log.", Mandatory = $true)]
        [string] $Message,
        [Parameter(HelpMessage = "An optional category to help organize different messages.", Mandatory = $false)]
        [string] $Category
    )

    try {
        $repo = New-FactoryObject -Repository        

        # Write Log and output to screen    
        if ($PSYSession.Initialized) {
            [void] $repo.CriticalSection({
                $o = @{
                    ID = $null                          # let the repository assign the surrogate key
                    Type = 'Debug'
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
        Write-Debug -Message "Debug: $logCategory$Message"
    }
    catch {
        Write-PSYErrorLog $_
    }

}