function Select-Coalesce {
    param (
        [Parameter(Mandatory = $false)]
        [object[]] $InputObject
    )

    foreach ($o in $InputObject) {
        if ($o) {
            return $o
        }
    }

}