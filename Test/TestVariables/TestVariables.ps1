Write-PSYInformationLog 'Test State Types'

Start-PSYActivity -Name 'test' -ScriptBlock {
    Write-PSYInformationLog 'hello world'
}

# This is what a state variable generally looks like. A variable can be a discrete/scalar piece of information, it
# can have multiple fields like a hashtable, or it can have children like a list or table.
$stateVarExample = @{
    ID = 'Surrogate Key'
    Name = 'User given unique name'
    Value = 'Can be anything serializable'
    Children = @(
        @{
            ID = "I'm a child"
            Value = @{With = "Complex properties"; And = "Multiple fields"}
        },
        @{
            ID = "I'm another child"
            Value = @{With = "Complex properties"; And = "Multiple fields"}
        }
    )
}

# Single scalar values
try {
    $a = Set-PSYVariable -Name 'a' -Value "Hello World" -Overwrite      # create a new scalar value (overrides if already exists)
    $b = Set-PSYVariable -Name 'b' -Value " Again!"                     # new scalar with default value
    $x = Set-PSYVariable -Name 'x' -Value 555
    $testScalar = (Get-PSYVariable -Name 'a').Value + (Get-PSYVariable -Name 'b').Value
    if ($testScalar -ne 'Hello World Again!') {
        throw "Concat of two strings incorrect"
    }
    if ((Get-PSYVariable -Name 'x').Value -ne 555) {
        throw "Int value didn't save correctly"
    }
}
catch {
    Write-PSYExceptionLog -Message "Failed Single Scalar Values Test"
}

# Atomic complex types. These can be hashtables/dictionaries, but since it's a single state var
# there's no way to update just part of the structure.
try {
    $d = Set-PSYVariable -Name 'dictionary' -Value @{ID = 111; Hello = "World"; Foo = "Bar";}
    $d = Get-PSYVariable -Name 'dictionary'
    if ($d.Value.ID -ne 111 -or $d.Foo -eq 'Bar') {
        throw "Complex properties didn't save correctly."
    }
}
catch {
    Write-PSYExceptionLog -Message "Failed Atomic hashtable test"
}

# Lists of scalar values
try {
    $list = Set-PSYVariable -Name 'My List' -Value @{MyField = 123}		# create a new list (will error if already exists)
    foreach ($i in (1..10)) {       # add children to our list
        $newItem = Set-PSYVariable -Parent $list -Value (5 * $i) -Name "I'm optional, but unique $i"       # add a new item (this operation should be atomic to the item)
        $newItem.Value = 6 * $i     # update that value we just added
        Set-PSYVariable -Variable $newItem -Overwrite    # save it again
    }
    $list = Get-PSYVariable -Name 'My List'     # retrieve it again
    if ($list.Value.MyField -ne 123 -or $list.Children.Count -ne 10 -or $list.Children[9].Value -ne 60) {
        throw "List values didn't save correctly."
    }
}
catch {
    Write-PSYExceptionLog -Message "Failed List of Scalar Values"
}

# List of complex types
try {
    $entityList = Set-PSYVariable -Name 'Entity List' -Value @{ParentPropA = 'Exists at the parent level'}
    foreach ($i in (1..10)) {       # add children to our list
        $entity = Set-PSYVariable -Parent $entityList -Value @{Key = $i; BackOrdered = $true; ModifiedDate = ConvertTo-PSYNativeType (Get-Date)}
    }
    # (11..20) | Set-PSYVariable -Parent $entityList -Value @{Key = $_; BackOrdered = $false; ModifiedDate = Get-Date}        # adding items via the pipeline
    $entityList = Get-PSYVariable -Name 'Entity List'
    if ($entityList.Value.ParentPropA -ne 'Exists at the parent level' -or $entityList.Children.Count -ne 10 -or $entityList.Children[9].Value.Key -ne 10) {
        throw "List of complex types didn't save correctly."
    }
}
catch {
    Write-PSYExceptionLog -Message "Failed List of complex types Test"
}

# TODO: IMPLEMENT REMAINDER
# List of User Types (aka a custom RDBMS table)
<#
try {
    $tableList = Set-PSYVariable -Name 'TableList' -UserType 'MyCustomTable'
    foreach ($i in (1..10)) {
        # Add row then update
        $row = Set-PSYVariable -Parent $tableList
        if (-not $row.Value.ContainsKey('SourceTable')) {
            throw "Initial schema not present"
        }
        $row.Value.SourceTable = "foo$i"            # these fields should already be present, retrieved from the database schema
        $row.Value.TargetTable = "bar$i"
        Set-PSYVariable -Variable $row
        # Insert new row
        $row = @{                                   # saves just fine as long as the fields match the table, notice it's not boxed within the ID,Value,Children container
            SourceTable = "SourceTable$i"
            TargetTable = "TargetTable$i"
            # UnsupportedField = 'foo'              # this would fail since the field isn't part of user type MyCustomTable
        }
        #$actualRow = Set-PSYVariable -Value $row   # this would fail since PowerSync wouldn't know the parent and a name was omitted
        $actualRow = Set-PSYVariable -Parent $tableList -Value $row     # $actualRow is now contained and has ID,Value,Children fields
    }
    $findList = Get-PSYVariable -Name 'My List'     # the entire table
    $findRecord = Get-PSYVariable -Name "I'm optional, but unique 1"
}
catch {
    Write-PSYExceptionLog -Message "Failed List of User Types Test"
}
#>

# Removal of state variables
try {
    $allVars = Get-PSYVariable
    if ($allVars.Count -ne 10) {
        throw "Count of registered state variables incorrect."
    }
    foreach ($i in $allVars.Children) {
        if ($i.ID % 2 -eq 0) {                      # can remove using entire item, or just the name
            Remove-PSYVariable $i
        }
        else {
            Remove-PSYVariable -Name $i.Name
        }
    }

    $allVars = Get-PSYVariable
    if ($allVars.Count -ne 0) {
        throw "Count of registered state variables should be zero."
    }
}
catch {
    Write-P SYExceptionLog -Message "Failed Removal of State Variables Test"
}

# TODO: DATETIME AND CONVERTO-PSYNATIVETYPE
# TODO: HIERARCHY TEST, WITH REPARENTING