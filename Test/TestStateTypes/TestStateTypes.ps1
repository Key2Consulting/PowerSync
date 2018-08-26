Start-PSYActivity -Name 'Test State Types' -Debug -Verbose -ScriptBlock {
    
    Set-PSYStateVar 'TestVariable' "Initial value"

    Start-PSYActivity -Name 'Test ForEach' -Parallel -ScriptBlock {
        Write-PSYInformationLog -Message "Here"
    }

    Remove-PSYStateVar 'TestVariable'
}