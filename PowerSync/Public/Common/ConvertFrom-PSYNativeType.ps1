<#
.SYNOPSIS
Converts a given data type to/from a native type supported by PowerSync.

.DESCRIPTION
Certain data types, like DateTime, don't work well within PowerSync. This function converts to/from those data types to a more suitable format.

.PARAMETER Object
The object to convert back.

.PARAMETER Type
The desired type.

.EXAMPLE
ConvertFrom-PSYNativeType -Object '2018-09-02T21:35:01.378Z' -Type [DateTime]
#>
function ConvertFrom-PSYNativeType {
    [Parameter(HelpMessage = "The object to convert back.", Mandatory = $false)]
    [object] $Object,
    [Parameter(HelpMessage = "The desired type.", Mandatory = $false)]
    [object] $Type

    try {
        $sourceType = $SourceObject.GetType().Name
        $targetType = $Type.ToString()

        #if ()
    }
    catch {
        Write-PSYErrorLog $_
    }
}