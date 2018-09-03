function ConvertFrom-PSYNativeType {
    [Parameter(HelpMessage = "TODO", Mandatory = $false)]
    [object] $Object,
    [Parameter(HelpMessage = "TODO", Mandatory = $false)]
    [object] $Type

    try {
        $sourceType = $SourceObject.GetType().Name
        $targetType = $Type.ToString()

        #if ()
    }
    catch {
        Write-PSYErrorLog $_ "Error in ConvertFrom-Type $($Object.ToString()) $($Type.ToString())."
    }
}