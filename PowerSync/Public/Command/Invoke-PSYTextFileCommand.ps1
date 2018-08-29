function Invoke-PSYTextFileCommand {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Connection,
        [Parameter(HelpMessage = "The regular expression used to search the source file. Must use capturing groups to identify what should be replaced.", Mandatory = $true)]
        [string] $RegexSearch,
        [Parameter(HelpMessage = "Array of strings to replace each of the captured groups from the search, in order of the group index.", Mandatory = $true)]
        [string[]] $Replace
    )
}