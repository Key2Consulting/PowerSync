function Select-TablePart {
    [CmdletBinding()]
    param(
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Table,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Part,
        [parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Clean
    )

    # TODO: Convert to REGEX to be more robust
    $parts = $Table.Split('.')

    # Get the desired part
    if ($Part -eq 'Table') {
        $part = $parts[$parts.Length - 1]
    }
    elseif ($Part -eq 'Schema') {
        $part = $parts[$parts.Length - 2]
    }
    elseif ($Part -eq 'Database' -and $parts.Length -ge 2) {
        # Many database platforms don't use schemas, instead tables are simply organized in databases. If there's at
        # least two parts, and the caller is asking for database, assume it's the first part is the database
        $part = $parts[0]
    }

    # Clean it up, if specified
    if ($Clean) {
        $part = $part.TrimStart('[')
        $part = $part.TrimEnd(']')
    }
    
    return $part
}