<#
.SYNOPSIS
Converts a given data type to/from a compatible type supported by PowerSync.

.DESCRIPTION
Certain data types, like DateTime, don't work well within PowerSync. This function converts to/from those data types to a more suitable format.

.PARAMETER Object
The object to convert back.

.PARAMETER Type
The desired type.

.EXAMPLE
ConvertFrom-PSYCompatibleType -Object '2018-09-02T21:35:01.378Z' -Type [DateTime]
#>
function ConvertFrom-PSYCompatibleType {
    [CmdletBinding()]
    param (
        [parameter(HelpMessage = "The object to convert from a compatible type.", Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = 'Pipe')]
        [object] $InputObject,
        [Parameter(HelpMessage = "The desired type.", Mandatory = $false)]
        [type] $Type
    )

    process {
        try {
            $sourceType = $InputObject.GetType().Name

            # If source is ISO 8601 date string, convert back to DateTime
            if ($Type.Name -eq 'datetime' -and $sourceType -eq 'string') {
                [datetime]::Parse($InputObject, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
            }
        }
        catch {
            Write-PSYErrorLog $_
        }
    }
}