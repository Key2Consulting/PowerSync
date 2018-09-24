<#
.SYNOPSIS
Write a message to the console.

.DESCRIPTION
Imitates the Write-Log function, but safely uses Console.WriteLine when executing in an environment where Write-Host is unavailable (i.e. WebJobs).

See Write-Log for additional documentation.
#>
function Write-PSYHost {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [object] $Object,
        [Parameter(Mandatory = $false)]
        [switch] $NoNewline,
        [Parameter(Mandatory = $false)]
        [object] $Seperator,
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor] $ForegroundColor,
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor] $BackgroundColor
    )

    # If the host supports Write-Host, use that since it provides nice color formatting.
    if ($PSYSession.UserInteractive) {
        if ($ForegroundColor -and $BackgroundColor) {
            Write-Host -Object $Object -NoNewline:$NoNewline -Separator $Seperator -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
        }
        elseif ($ForegroundColor) {
            Write-Host -Object $Object -NoNewline:$NoNewline -Separator $Seperator -ForegroundColor $ForegroundColor
        }
        elseif ($BackgroundColor) {
            Write-Host -Object $Object -NoNewline:$NoNewline -Separator $Seperator -BackgroundColor $BackgroundColor
        }
        else {
            Write-Host -Object $Object -NoNewline:$NoNewline -Separator $Seperator
        }
    }
    else {
        # Otherwise just use .NET's Console.WriteLine.
        if ($NoNewline) {
            [console]::Write($Object.ToString())
        }
        else {
            [console]::WriteLine($Object.ToString())
        }
    }
}