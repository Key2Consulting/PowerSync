function Select-Coalesce {
    param (
        [Parameter(Mandatory = $true)]
        [object[]] $InputObject
    )

    foreach ($o in $InputObject) {
        if ($o) {
            return $o
        }
    }

}