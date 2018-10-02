function Unprotect-PSYText {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string] $InputObject
    )

    $secureText = $InputObject | ConvertTo-SecureString
    
    $cred = [System.Management.Automation.PSCredential]::new('dummy', $secureText)
    $cred.GetNetworkCredential().Password

}