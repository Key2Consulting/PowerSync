function Import-PSYOleDb {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Table,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Timeout
    )

    try {
        # TODO
    }
    catch {
        Write-PSYErrorLog $_ "Error in Import-PSYDb."
    }
}