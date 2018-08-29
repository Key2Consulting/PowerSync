function ConvertTo-PSYNativeType {
    [CmdletBinding()]
    param(
        [parameter(HelpMessage = "TODO", Mandatory = $false, ValueFromPipeline = $true)]
        [object] $InputObject
    )

    begin {
    }

    process {
        try {
            if (-not $InputObject) {
                return $null
            }

            $type = $InputObject.GetType().Name
            if ($type -eq 'datetime') {                                     # Convert dates to ISO 8601 format
                return $InputObject.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")    # https://stackoverflow.com/questions/114983/given-a-datetime-object-how-do-i-get-an-iso-8601-date-in-string-format
            }
            elseif ($type -eq 'hashtable') {                                # Hashtable is our native type, but it's values may not be, so enumerate
                foreach ($k in $InputObject.Keys) {
                    $hash[$k] = ConvertTo-PSYNativeType $hash[$k]
                }
            }
            elseif ($type -eq 'pscustomobject') {                           # Convert PSCustomObject to HashTable
                $hash = @{}
                foreach ($p in $InputObject.PSObject.Properties) {
                    $hash[$p.Name] = ConvertTo-PSYNativeType $p.Value
                    #if ($p.Value -is [System.Management.Automation.PSCustomObject]) {
                }
                return $hash
            }
            elseif ($type -eq 'arraylist') {                                 # ArrayList is our native type, but it's values may not be, so enumerate
                $new = New-Object System.Collections.ArrayList
                foreach ($o in $InputObject) {
                    [void] $new.Add((ConvertTo-PSYNativeType $o))
                }
            }
            else {
                # Assume it's a primitive type TODO: SHOULD EXPLICITLY CHECK FOR PRIMITIVE TYPES
                return $InputObject
            }
        }
        catch {
            Write-PSYExceptionLog $_ "Error in ConvertTo-Type $($InputObject.ToString())."
        }
    }

    end {
    }
}