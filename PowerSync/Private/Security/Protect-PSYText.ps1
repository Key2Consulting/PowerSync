function Protect-PSYText {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string] $InputObject
    )

    $secureText = $InputObject | ConvertTo-SecureString -AsPlainText -Force
    $secureText | ConvertFrom-SecureString
}