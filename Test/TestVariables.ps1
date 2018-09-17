Write-PSYInformationLog 'Test State Types'

Start-PSYActivity -Name 'test' -ScriptBlock {
    Write-PSYInformationLog 'hello world'
}

# Single scalar values
try {
    $a = Set-PSYVariable -Name 'a' -Value "Hello World"                 # create a new scalar value (overrides if already exists)

    $b = Set-PSYVariable -Name 'b' -Value " Again!"                     # new scalar with default value
    $x = Set-PSYVariable -Name 'x' -Value 555
    $testScalar = (Get-PSYVariable -Name 'a') + (Get-PSYVariable -Name 'b')
    if ($testScalar -ne 'Hello World Again!') {
        throw "Concat of two strings incorrect"
    }
    if ((Get-PSYVariable -Name 'x') -ne 555) {
        throw "Int value didn't save correctly"
    }
}
catch {
    throw "Failed Single Scalar Values Test"
}

# Atomic complex types. These can be hashtables/dictionaries, but since it's a single state var
# there's no way to update just part of the structure.
try {
    $d = Set-PSYVariable -Name 'dictionary' -Value @{ID = 111; Hello = "World"; Foo = "Bar";}
    $d = Get-PSYVariable -Name 'dictionary'
    if ($d.ID -ne 111 -or $d.Foo -ne 'Bar') {
        throw "Complex properties didn't save correctly."
    }
}
catch {
    throw "Failed Atomic hashtable test"
}

# List of complex types
try {
    $complexlist = (
        @{Prop1 = 123; Prop2 = 'ABC'},
        @{Prop1 = 456; Prop2 = 'DEF'},
        @{Prop1 = 789; Prop2 = 'GHI'}
    )
    $entityList = Set-PSYVariable -Name 'Entity List' -Value $complexlist
    $entityList = Get-PSYVariable -Name 'Entity List'
    if ($entityList[2].Prop1 -ne 789 -or $entityList.Count -ne 3) {
        throw "List of complex types didn't save correctly."
    }
}
catch {
    throw "Failed List of complex types Test"
}