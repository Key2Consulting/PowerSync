function Unprotect-PSYText {
    [CmdletBinding()]
    param (
        [parameter(HelpMessage = "TODO", Mandatory = $false, ValueFromPipeline = $true)]
        [string] $InputObject
    )

    $secureText = $InputObject | ConvertTo-SecureString
    
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'dummy', $secureText
    $cred.GetNetworkCredential().Password

}