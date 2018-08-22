Start-PSYMainActivity -PrintVerbose -ConnectScriptBlock {
    Connect-PSYJsonRepository
} -Name 'Test State Types' -ScriptBlock {

    # Primitive types
    Set-PSYState 'int' ([int]123)
    $a = Get-PSYState 'int'

    Set-PSYState 'Hash1' @{
        Hello = 'World'
        Foo = 'Bar'
        Count = 1
    }

    $x = Get-PSYState 'Hash1'
    if ($x -isplit [hashtable]) {
        Write-PSYExceptionLog -Message "Failed test hash state type"
    }
    
    #$x.My = "Property"
    $y = $x.Hello
}