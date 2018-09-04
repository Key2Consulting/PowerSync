function Sync-PSYTextToDb {
    [CmdletBinding()]
    param(
        [parameter(HelpMessage = "TODO", Mandatory = $false, ValueFromPipeline = $true)]
        [object] $InputObject
    )

    begin {
    }

    process {
        try {
        }
        catch {
            Write-PSYErrorLog $_ "Error in Sync-PSYTextToDb."
        }
    }

    end {
    }
}