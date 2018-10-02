function Get-EnumName {
    param(
        [Parameter(Mandatory = $false)]
        [object] $Member
    )
    
    [Enum]::GetName($Member.GetType(), $Member)
}