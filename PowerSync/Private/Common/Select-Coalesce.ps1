function Select-Coalesce {
    param (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [object[]] $InputObject
    )

    foreach ($o in $InputObject) {
        if ($o) {
            return $o
        }
    }

}