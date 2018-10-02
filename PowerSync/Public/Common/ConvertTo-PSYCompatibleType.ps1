<#
.SYNOPSIS
Converts a given data type to/from a compatible type supported by PowerSync.

.DESCRIPTION
Certain data types, like DateTime, don't work well within PowerSync. This function converts to/from those data types to a more suitable format.

.PARAMETER Object
The object to convert to a compatible type.

.EXAMPLE
ConvertFrom-PSYCompatibleType -Object (Get-Date)
#>
function ConvertTo-PSYCompatibleType {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
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
                    $hash[$k] = ConvertTo-PSYCompatibleType $hash[$k]
                }
            }
            elseif ($type -eq 'pscustomobject') {                           # Convert PSCustomObject to HashTable
                $hash = @{}
                foreach ($p in $InputObject.PSObject.Properties) {
                    $hash[$p.Name] = ConvertTo-PSYCompatibleType $p.Value
                    #if ($p.Value -is [System.Management.Automation.PSCustomObject]) {
                }
                return $hash
            }
            elseif ($type -eq 'arraylist') {                                 # ArrayList is our native type, but it's values may not be, so enumerate
                $new = [System.Collections.ArrayList]::new()
                foreach ($o in $InputObject) {
                    [void] $new.Add((ConvertTo-PSYCompatibleType $o))
                }
            }
            elseif ($type -eq 'OleDbDataReader' -or $type -eq 'SqlDataReader') {
                $reader = $InputObject
                if ($reader.HasRows) {
                    $recordList = [System.Collections.ArrayList]::new()
                    if ($reader.HasRows) {
                        while ($reader.Read()) {
                            $result = [ordered] @{}
                            for ($i=0;$i -lt $reader.FieldCount; $i++) {
                                $col = $reader.GetName($i)
                                $result."$col" = $reader[$i]
                            }
                            [void] $recordList.Add($result)
                        }
                    }
                    if ($recordList.Count -gt 0) {
                        return $recordList
                    }
                }                
            }
            else {
                # Assume it's a primitive type TODO: SHOULD EXPLICITLY CHECK FOR PRIMITIVE TYPES
                return $InputObject
            }
        }
        catch {
            Write-PSYErrorLog $_
        }
    }

    end {
    }
}