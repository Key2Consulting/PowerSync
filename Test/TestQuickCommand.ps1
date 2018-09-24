Start-PSYActivity -Name 'Test Quick Commands' -ScriptBlock {

    Start-PSYActivity -Name 'Test Quick Text to SqlServer' -ScriptBlock {
        Copy-PSYTable -SProvider TextFile -SConnectionString "Test\SampleFiles\Sample100.csv" -SFormat CSV -SHeader `
            -TProvider SqlServer -TServer $testDBServer -TDatabase "PowerSyncTestTarget" -TTable "dbo.QuickCSVCopy"

        Copy-PSYTable -SProvider TextFile -SConnectionString "Test\SampleFiles\Sample100.txt" -SFormat TSV -SHeader `
            -TProvider SqlServer -TServer $testDBServer -TDatabase "PowerSyncTestTarget" -TTable "dbo.QuickTypedCSVCopy"

        Copy-PSYTable -SProvider TextFile -SConnectionString "Test\SampleFiles\Sample10000.gz" -SFormat CSV -SHeader `
            -TProvider SqlServer -TServer $testDBServer -TDatabase "PowerSyncTestTarget" -TTable "dbo.QuickCSVCopyCompressed"
    }
    
    Start-PSYActivity -Name 'Test Quick SqlServer to SqlServer' -ScriptBlock {    
        Copy-PSYTable -SProvider SqlServer -SServer $testDBServer -SDatabase "PowerSyncTestTarget" -STable "dbo.QuickTypedCSVCopy" `
            -TProvider SqlServer -TServer $testDBServer -TDatabase "PowerSyncTestTarget" -TTable "dbo.QuickTypedCSVCopyOfCopy"
    }
    
    Start-PSYActivity -Name 'Test Quick SqlServer to Text' -ScriptBlock {
        Copy-PSYTable -SProvider SqlServer -SServer $testDBServer -SDatabase "PowerSyncTestTarget" -STable "dbo.QuickTypedCSVCopy" `
            -TProvider TextFile -TConnectionString "Test\TempFiles\TempOutput.csv" -TFormat CSV -THeader
        
        Copy-PSYTable -SProvider SqlServer -SServer $testDBServer -SDatabase "PowerSyncTestTarget" -STable "dbo.QuickTypedCSVCopy" `
            -TProvider TextFile -TConnectionString "Test\TempFiles\TempOutput.txt" -TFormat TSV -THeader

        Copy-PSYTable -SProvider SqlServer -SServer $testDBServer -SDatabase "PowerSyncTestTarget" -STable "dbo.QuickTypedCSVCopy" `
            -TProvider TextFile -TConnectionString "Test\TempFiles\TempOutput.gz" -TFormat TSV -THeader
    }
}