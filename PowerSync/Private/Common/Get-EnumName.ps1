function Get-EnumName {
    param(
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Member
    )
    
    [Enum]::GetName($Member.GetType(), $Member)
}