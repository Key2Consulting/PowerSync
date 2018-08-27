Start-PSYActivity -Name 'Test State Types' -Debug -Verbose -ScriptBlock {
    
    Set-PSYStateVar 'TestVariable' "Initial value"

    Start-PSYActivity -Name 'Test ForEach' -Parallel -ScriptBlock {
        Write-PSYInformationLog -Message "Here"
    }

    Remove-PSYStateVar 'TestVariable'
}

@{
    ID = 'Surrogate Key'
    Value = 'Can be anything serializable'
    CustomFields = 'Or could do this'
    Children = @()
}
    
    $list = New-PSYStateVar -Name 'My List'		# var contains ID and Value fields
    $list.Value.MyField = 123			# which one?

    foreach ($i in (1..10)) {
        $math = 5 * $i
        $newItem = New-PSYStateVar -Parent $list -Value $math -Name "I'm optional, but unique $i"
        $newItem.Value = 6 * $i
        Set-PSYStateVar $newItem
    }

    $entity = Set-PSYStateVar -Name 'Entity' -Value @{BrandNew = $true; ModifiedDate = Get-Date}       # overwrites if exists, creates if it doesn't
    
    $tableList = Set-PSYStateVar -Name 'TableList' -UserType 'MyCustomTable'
    $row = New-PSYStateVar -Parent $tableList
    $row.Value.SourceTable = 'foo'          # these fields should already be present, retrieved from the database schema
    $row.Value.TargetTable = 'bar'

    $find1 = Get-PSYStateVar -Name 'My List'          # the entire table
    $find2 = Get-PSYStateVar -Name "I'm optional, but unique 1"       # is this even useful?
    
    Remove-PSYStateVar $find2
    foreach ($i in $find1.Children) {
        if ($i % 2) {
            Remove-PSYStateVar $i
        }
    }